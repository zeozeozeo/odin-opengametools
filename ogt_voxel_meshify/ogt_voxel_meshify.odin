package ogt_voxel_meshify

import "core:c"

when ODIN_OS == .Windows do foreign import ogt_voxel_meshify_foreign "../wrapper/ogt_voxel_meshify.lib"
when ODIN_OS == .Linux do foreign import ogt_voxel_meshify_foreign "../wrapper/ogt_voxel_meshify.a"

// 3D vector
Mesh_Vec3 :: struct {
	x, y, z: f32,
}

// Color with alpha
Mesh_RGBA :: struct {
	r, g, b, a: u8,
}

// Vertex structure
Mesh_Vertex :: struct {
	pos:           Mesh_Vec3,
	normal:        Mesh_Vec3,
	color:         Mesh_RGBA,
	palette_index: u32,
}

// Mesh containing indexed triangle list
Mesh :: struct {
	vertex_count: u32,
	index_count:  u32,
	vertices:     [^]Mesh_Vertex,
	indices:      [^]u32,
}

// Function pointer types
Alloc_Func :: #type proc "c" (size: c.size_t, user_data: rawptr) -> rawptr
Free_Func :: #type proc "c" (ptr: rawptr, user_data: rawptr)
Voxel_Simple_Stream_Func :: #type proc "c" (
	x, y, z: u32,
	vertices: [^]Mesh_Vertex,
	vertex_count: u32,
	indices: [^]u32,
	index_count: u32,
	user_data: rawptr,
)

// Context for overriding internal operations
Context :: struct {
	alloc_func:           Alloc_Func,
	free_func:            Free_Func,
	alloc_free_user_data: rawptr,
}

foreign ogt_voxel_meshify_foreign {
	// Face counting
	@(link_name = "ogt_face_count_from_paletted_voxels_simple")
	face_count_from_paletted_voxels_simple :: proc(voxels: [^]u8, size_x, size_y, size_z: u32) -> u32 ---

	// Simple meshifier - most naive mesh at voxel granularity
	@(link_name = "ogt_mesh_from_paletted_voxels_simple")
	mesh_from_paletted_voxels_simple :: proc(ctx: ^Context, voxels: [^]u8, size_x, size_y, size_z: u32, palette: [^]Mesh_RGBA) -> ^Mesh ---

	// Greedy meshifier - uses greedy box-expansion to merge adjacent voxels
	@(link_name = "ogt_mesh_from_paletted_voxels_greedy")
	mesh_from_paletted_voxels_greedy :: proc(ctx: ^Context, voxels: [^]u8, size_x, size_y, size_z: u32, palette: [^]Mesh_RGBA) -> ^Mesh ---

	// Polygon meshifier - polygonizes and triangulates connected voxels of same color
	@(link_name = "ogt_mesh_from_paletted_voxels_polygon")
	mesh_from_paletted_voxels_polygon :: proc(ctx: ^Context, voxels: [^]u8, size_x, size_y, size_z: u32, palette: [^]Mesh_RGBA) -> ^Mesh ---

	// Remove duplicate vertices in-place
	@(link_name = "ogt_mesh_remove_duplicate_vertices")
	mesh_remove_duplicate_vertices :: proc(ctx: ^Context, mesh: ^Mesh) ---

	// Smooth normals by averaging adjacent face normals
	@(link_name = "ogt_mesh_smooth_normals")
	mesh_smooth_normals :: proc(ctx: ^Context, mesh: ^Mesh) ---

	// Destroy mesh
	@(link_name = "ogt_mesh_destroy")
	mesh_destroy :: proc(ctx: ^Context, mesh: ^Mesh) ---

	// Stream geometry for each voxel to a callback function
	@(link_name = "ogt_stream_from_paletted_voxels_simple")
	stream_from_paletted_voxels_simple :: proc(voxels: [^]u8, size_x, size_y, size_z: u32, palette: [^]Mesh_RGBA, stream_func: Voxel_Simple_Stream_Func, stream_func_data: rawptr) ---
}

main :: proc() {
	mesh_destroy(nil, nil)
}
