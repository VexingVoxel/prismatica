class_name CoreVFXEventBusClass extends Node

# Signal to request a VFX.
# - id: String matching a VFXConfig.id.
# - global_transform: Transform2D for 2D VFX (position, rotation, scale).
# - params: Dictionary for additional dynamic parameters.
signal request_vfx(id: String, global_transform: Transform2D, params: Dictionary)

# Note: For 3D VFX, an extension (e.g., request_vfx_3d with Transform3D)
# or a more complex 'params' dictionary would be used. This plan focuses on 2D.