package ogt_vox

import "core:c"
import "core:fmt"

when ODIN_OS == .Windows do foreign import ogt_vox_foreign "../wrapper/ogt_vox.lib"
when ODIN_OS == .Linux do foreign import ogt_vox_foreign "../wrapper/ogt_vox.a"

// Constants
INVALID_GROUP_INDEX :: 0xFFFFFFFF

// Read scene flags
READ_SCENE_FLAGS_GROUPS :: 1 << 0
READ_SCENE_FLAGS_KEYFRAMES :: 1 << 1
READ_SCENE_FLAGS_KEEP_EMPTY_MODELS_INSTANCES :: 1 << 2
READ_SCENE_FLAGS_KEEP_DUPLICATE_MODELS :: 1 << 3

// Material content flags
MATL_HAVE_METAL :: 1 << 0
MATL_HAVE_ROUGH :: 1 << 1
MATL_HAVE_SPEC :: 1 << 2
MATL_HAVE_IOR :: 1 << 3
MATL_HAVE_ATT :: 1 << 4
MATL_HAVE_FLUX :: 1 << 5
MATL_HAVE_EMIT :: 1 << 6
MATL_HAVE_LDR :: 1 << 7
MATL_HAVE_TRANS :: 1 << 8
MATL_HAVE_ALPHA :: 1 << 9
MATL_HAVE_D :: 1 << 10
MATL_HAVE_SP :: 1 << 11
MATL_HAVE_G :: 1 << 12
MATL_HAVE_MEDIA :: 1 << 13

// Color
RGBA :: struct {
	r, g, b, a: u8,
}

// Column-major 4x4 matrix
Transform :: struct {
	// column 0 of 4x4 matrix, 1st three elements = x axis vector, last element always 0.0
	m00, m01, m02, m03: f32,
	// column 1 of 4x4 matrix, 1st three elements = y axis vector, last element always 0.0
	m10, m11, m12, m13: f32,
	// column 2 of 4x4 matrix, 1st three elements = z axis vector, last element always 0.0
	m20, m21, m22, m23: f32,
	// column 3 of 4x4 matrix. 1st three elements = translation vector, last element always 1.0
	m30, m31, m32, m33: f32,
}

// A palette of colors
Palette :: struct {
	color: [256]RGBA, // palette of colors. use the voxel indices to lookup color from the palette.
}

// Extended Material Chunk MATL types
Matl_Type :: enum c.int {
	DIFFUSE = 0, // diffuse is default
	METAL   = 1,
	GLASS   = 2,
	EMIT    = 3,
	BLEND   = 4,
	MEDIA   = 5,
}

Cam_Mode :: enum c.int {
	PERSPECTIVE  = 0,
	FREE         = 1,
	PANO         = 2,
	ORTHOGRAPHIC = 3,
	ISOMETRIC    = 4,
	UNKNOWN      = 5,
}

// Media type for blend, glass and cloud materials
Media_Type :: enum c.int {
	ABSORB, // Absorb media
	SCATTER, // Scatter media
	EMIT, // Emissive media
	SSS, // Subsurface scattering media
}

// Extended Material Chunk MATL information
Matl :: struct {
	content_flags: u32, // set of MATL_HAVE_* OR together to denote contents available
	media_type:    Media_Type, // media type for blend, glass and cloud materials
	type:          Matl_Type,
	metal:         f32,
	rough:         f32, // roughness
	spec:          f32, // specular
	ior:           f32, // index of refraction
	att:           f32, // attenuation
	flux:          f32, // radiant flux (power)
	emit:          f32, // emissive
	ldr:           f32, // low dynamic range
	trans:         f32, // transparency
	alpha:         f32,
	d:             f32, // density
	sp:            f32,
	g:             f32,
	media:         f32,
}

// Extended Material Chunk MATL array of materials
Matl_Array :: struct {
	matl: [256]Matl, // extended material information from Material Chunk MATL
}

Cam :: struct {
	camera_id: u32,
	mode:      Cam_Mode,
	focus:     [3]f32, // the target position
	angle:     [3]f32, // rotation in degree - pitch (-180 to +180), yaw (0 to 360), roll (0 to 360)
	radius:    f32, // distance of camera position from target position, also controls frustum in MV for orthographic/isometric modes
	frustum:   f32, // 'height' of near plane of frustum, either orthographic height in voxels or tan( fov/2.0f )
	fov:       c.int, // angle in degrees for height of field of view, ensure to set frustum as only used when changed in MV UI
}

Sun :: struct {
	intensity: f32,
	area:      f32, // 1.0 ~= 43.5 degrees
	angle:     [2]f32, // elevation, azimuth
	rgba:      RGBA,
	disk:      bool, // visible sun disk
}

// A 3-dimensional model of voxels
Model :: struct {
	size_x:     u32, // number of voxels in the local x dimension
	size_y:     u32, // number of voxels in the local y dimension
	size_z:     u32, // number of voxels in the local z dimension
	voxel_hash: u32, // hash of the content of the grid.
	voxel_data: [^]u8, // grid of voxel data comprising color indices in x -> y -> z order. a color index of 0 means empty, all other indices mean solid and can be used to index the scene's palette to obtain the color for the voxel.
}

// A keyframe for animation of a transform
Keyframe_Transform :: struct {
	frame_index: u32,
	transform:   Transform,
}

// A keyframe for animation of a model
Keyframe_Model :: struct {
	frame_index: u32,
	model_index: u32,
}

// An animated transform
Anim_Transform :: struct {
	keyframes:     [^]Keyframe_Transform,
	num_keyframes: u32,
	loop:          bool,
}

// An animated model
Anim_Model :: struct {
	keyframes:     [^]Keyframe_Model,
	num_keyframes: u32,
	loop:          bool,
}

// An instance of a model within the scene
Instance :: struct {
	name:           cstring, // name of the instance if there is one, will be NULL otherwise.
	transform:      Transform, // orientation and position of this instance on first frame of the scene. This is relative to its group local transform if group_index is not 0
	model_index:    u32, // index of the model used by this instance on the first frame of the scene. used to lookup the model in the scene's models[] array.
	layer_index:    u32, // index of the layer used by this instance. used to lookup the layer in the scene's layers[] array.
	group_index:    u32, // this will be the index of the group in the scene's groups[] array. If group is zero it will be the scene root group and the instance transform will be a world-space transform, otherwise the transform is relative to the group.
	hidden:         bool, // whether this instance is individually hidden or not. Note: the instance can also be hidden when its layer is hidden, or if it belongs to a group that is hidden.
	transform_anim: Anim_Transform, // animation for the transform
	model_anim:     Anim_Model, // animation for the model_index
}

// Describes a layer within the scene
Layer :: struct {
	name:   cstring, // name of this layer if there is one, will be NULL otherwise.
	color:  RGBA, // color of the layer.
	hidden: bool, // whether this layer is hidden or not.
}

// Describes a group within the scene
Group :: struct {
	name:               cstring, // name of the group if there is one, will be NULL otherwise
	transform:          Transform, // transform of this group relative to its parent group (if any), otherwise this will be relative to world-space.
	parent_group_index: u32, // if this group is parented to another group, this will be the index of its parent in the scene's groups[] array, otherwise this group will be the scene root group and this value will be INVALID_GROUP_INDEX
	layer_index:        u32, // which layer this group belongs to. used to lookup the layer in the scene's layers[] array.
	hidden:             bool, // whether this group is hidden or not.
	transform_anim:     Anim_Transform, // animated transform data
}

// The scene parsed from a .vox file.
Scene :: struct {
	num_models:       u32, // number of models within the scene.
	num_instances:    u32, // number of instances in the scene (on anim frame 0)
	num_layers:       u32, // number of layers in the scene
	num_groups:       u32, // number of groups in the scene
	num_color_names:  u32, // number of color names in the scene
	color_names:      [^]cstring, // array of color names. size is num_color_names
	models:           [^]^Model, // array of models. size is num_models
	instances:        [^]Instance, // array of instances. size is num_instances
	layers:           [^]Layer, // array of layers. size is num_layers
	groups:           [^]Group, // array of groups. size is num_groups
	palette:          Palette, // the palette for this scene
	materials:        Matl_Array, // the extended materials for this scene
	num_cameras:      u32, // number of cameras for this scene
	cameras:          [^]Cam, // the cameras for this scene
	sun:              ^Sun, // sun - primary light at infinity
	anim_range_start: u32, // the start frame of the animation range for this scene (META chunk since 0.99.7.2)
	anim_range_end:   u32, // the end frame of the animation range for this scene (META chunk since 0.99.7.2)
}

// Allocate memory function interface. pass in size, and get a pointer to memory with at least that size available.
Alloc_Func :: #type proc "c" (size: c.size_t) -> rawptr

// Free memory function interface. pass in a pointer previously allocated and it will be released back to the system managing memory.
Free_Func :: #type proc "c" (ptr: rawptr)

// Progress feedback function with option to cancel a ogt_vox_write_scene operation. Percentage complete is approximately given by: 100.0f * progress.
Progress_Callback_Func :: #type proc "c" (progress: f32, user_data: rawptr) -> bool

foreign ogt_vox_foreign {
	// Transform utilities
	@(link_name = "ogt_vox_transform_get_identity")
	transform_get_identity :: proc() -> Transform ---

	@(link_name = "ogt_vox_transform_multiply")
	transform_multiply :: proc(a: ^Transform, b: ^Transform) -> Transform ---

	// Memory management
	@(link_name = "ogt_vox_set_memory_allocator")
	set_memory_allocator :: proc(alloc_func: Alloc_Func, free_func: Free_Func) ---

	@(link_name = "ogt_vox_malloc")
	malloc :: proc(size: c.size_t) -> rawptr ---

	@(link_name = "ogt_vox_free")
	free :: proc(mem: rawptr) ---

	// Progress callback
	@(link_name = "ogt_vox_set_progress_callback_func")
	set_progress_callback_func :: proc(progress_callback_func: Progress_Callback_Func, user_data: rawptr) ---

	// Scene reading/writing
	@(link_name = "ogt_vox_read_scene")
	read_scene :: proc(buffer: [^]u8, buffer_size: u32) -> ^Scene ---

	@(link_name = "ogt_vox_read_scene_with_flags")
	read_scene_with_flags :: proc(buffer: [^]u8, buffer_size: u32, read_flags: u32) -> ^Scene ---

	@(link_name = "ogt_vox_destroy_scene")
	destroy_scene :: proc(scene: ^Scene) ---

	@(link_name = "ogt_vox_write_scene")
	write_scene :: proc(scene: ^Scene, buffer_size: ^u32) -> [^]u8 ---

	// Camera utilities
	@(link_name = "ogt_vox_camera_to_transform")
	camera_to_transform :: proc(camera: ^Cam, transform: ^Transform) ---

	// Scene merging
	@(link_name = "ogt_vox_merge_scenes")
	merge_scenes :: proc(scenes: [^]^Scene, scene_count: u32, required_colors: [^]RGBA, required_color_count: u32) -> ^Scene ---

	// Animation sampling
	@(link_name = "ogt_vox_sample_instance_model")
	sample_instance_model :: proc(instance: ^Instance, frame_index: u32) -> u32 ---

	@(link_name = "ogt_vox_sample_instance_transform_global")
	sample_instance_transform_global :: proc(instance: ^Instance, frame_index: u32, scene: ^Scene) -> Transform ---

	@(link_name = "ogt_vox_sample_instance_transform_local")
	sample_instance_transform_local :: proc(instance: ^Instance, frame_index: u32) -> Transform ---

	@(link_name = "ogt_vox_sample_group_transform_global")
	sample_group_transform_global :: proc(group: ^Group, frame_index: u32, scene: ^Scene) -> Transform ---

	@(link_name = "ogt_vox_sample_group_transform_local")
	sample_group_transform_local :: proc(group: ^Group, frame_index: u32) -> Transform ---
}
