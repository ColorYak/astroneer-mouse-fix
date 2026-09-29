using UAssetAPI;
using UAssetAPI.ExportTypes;
using UAssetAPI.PropertyTypes.Objects;
using UAssetAPI.UnrealTypes;

if (args.Length != 2)
{
    Console.Error.WriteLine("Usage: AstroneerMouseFix.Builder <input.uasset> <output.uasset>");
    return 2;
}

UAsset asset = new(args[0], EngineVersion.VER_UE4_23);

NormalExport GetExport(UAsset source, string name) =>
    (NormalExport)source.Exports.Single(export => export.ObjectName.ToString() == name);

FloatPropertyData GetFloat(NormalExport export, string propertyName) =>
    (FloatPropertyData)export[propertyName];

void SetFloat(NormalExport export, string propertyName, float value)
{
    GetFloat(export, propertyName).Value = value;
}

NormalExport rig = GetExport(asset, "Default__CameraSpaceWalkingRig_C");
NormalExport pitch = GetExport(asset, "PitchControlModifier_GEN_VARIABLE");
NormalExport yaw = GetExport(asset, "YawControlModifier_GEN_VARIABLE");

// Use 1000 to remove post-rotation lag; 4000 locked pitch during testing.
SetFloat(rig, "SpringFactor", 1000.0f);

// Match yaw to the installed pitch speed so mouse sensitivity is equal across axes.
float targetAxisSpeed = GetFloat(pitch, "Speed").Value;
float originalYawSpeed = GetFloat(yaw, "Speed").Value;
SetFloat(yaw, "Speed", targetAxisSpeed);

// Compensate yaw's multiplier to preserve its original effective controller rate.
float originalYawGamepadRate = originalYawSpeed * GetFloat(yaw, "GamepadMultiplier").Value;
SetFloat(yaw, "GamepadMultiplier", originalYawGamepadRate / targetAxisSpeed);

// Disable smoothing on both axes because every tested positive value introduced excessive input delay.
SetFloat(pitch, "MouseSmoothingFactor", 0.0f);
SetFloat(yaw, "MouseSmoothingFactor", 0.0f);

// Disable the pitch sponge because it attenuates vertical input near the limits.
SetFloat(pitch, "SpongeRange", 0.0f);

string? outputDirectory = Path.GetDirectoryName(args[1]);
if (!string.IsNullOrEmpty(outputDirectory))
{
    Directory.CreateDirectory(outputDirectory);
}

asset.Write(args[1]);
Console.WriteLine("Patched CameraSpaceWalkingRig.");
return 0;
