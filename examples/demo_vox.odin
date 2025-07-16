// port of demo/demo_vox.cpp
package demo

import ogt ".."
import "core:fmt"
import "core:os"
import "core:slice"

VOX_DIR :: "../opengametools/demo/"

load_vox_scene :: proc(
	filename: string,
	scene_read_flags: u32 = 0,
) -> (
	scene: ^ogt.Scene,
	ok: bool,
) {
	buffer, ok2 := os.read_entire_file(filename)
	if !ok2 {
		fmt.eprintf("Failed to open or read file %s", filename)
		return nil, false
	}
	defer delete(buffer)

	loaded_scene := ogt.read_scene_with_flags(raw_data(buffer), u32(len(buffer)), scene_read_flags)

	if loaded_scene == nil {
		return nil, false
	}
	return loaded_scene, true
}

load_vox_scene_with_groups :: proc(filename: string) -> (^ogt.Scene, bool) {
	return load_vox_scene(filename, ogt.READ_SCENE_FLAGS_GROUPS)
}

save_vox_scene :: proc(filename: string, scene: ^ogt.Scene) -> bool {
	buffer_size: u32
	buffer := ogt.write_scene(scene, &buffer_size)
	if buffer == nil {
		fmt.eprintf("Failed to write scene to buffer.\n")
		return false
	}
	defer ogt.free(buffer)

	data_to_write := buffer[:buffer_size]

	ok := os.write_entire_file(filename, data_to_write)
	if !ok {
		fmt.eprintf("Failed to save file %s", filename)
		return false
	}

	fmt.printf("Successfully saved scene to %s\n", filename)
	return true
}

count_solid_voxels_in_model :: proc(model: ^ogt.Model) -> u32 {
	solid_voxel_count: u32 = 0
	voxel_index: u32 = 0
	// the voxel data is stored in x -> y -> z order.
	for z in 0 ..< model.size_z {
		for y in 0 ..< model.size_y {
			for x in 0 ..< model.size_x {
				// a color index of 0 means the voxel is empty.
				color_index := model.voxel_data[voxel_index]
				if color_index != 0 {
					solid_voxel_count += 1
				}
				voxel_index += 1
			}
		}
	}
	return solid_voxel_count
}

demo_load_and_save :: proc(filename: string) -> bool {
	fmt.printf("--- Running Demo: Load, Inspect, and Save ---\n")
	fmt.printf("Loading scene: %s\n", filename)

	scene, ok := load_vox_scene_with_groups(filename)
	if !ok {
		fmt.eprintf("Failed to load scene from %s\n", filename)
		return false
	}
	defer ogt.destroy_scene(scene)

	// Print layer info
	fmt.printf("#layers: %d\n", scene.num_layers)
	for i in 0 ..< scene.num_layers {
		layer := &scene.layers[i]
		layer_name := (string(layer.name) if layer.name != nil else "")
		visibility := ("hidden" if layer.hidden else "shown")
		fmt.printf("layer[%d, name=%s] is %s\n", i, layer_name, visibility)
	}

	// Print group info
	fmt.printf("#groups: %d\n", scene.num_groups)
	for i in 0 ..< scene.num_groups {
		group := &scene.groups[i]
		layer_name := ""
		if group.layer_index != ogt.INVALID_GROUP_INDEX {
			group_layer := &scene.layers[group.layer_index]
			if group_layer.name != nil {
				layer_name = string(group_layer.name)
			}
		}
		visibility := ("hidden" if group.hidden else "shown")
		fmt.printf(
			"group[%d] has parent group %d, is part of layer[%d, name=%s] and is %s\n",
			i,
			group.parent_group_index,
			group.layer_index,
			layer_name,
			visibility,
		)
	}

	// Print instance info
	fmt.printf("#instances: %d\n", scene.num_instances)
	for i in 0 ..< scene.num_instances {
		instance := &scene.instances[i]
		instance_name := (string(instance.name) if instance.name != nil else "")
		layer_name := "(no layer)"
		if instance.layer_index != ogt.INVALID_GROUP_INDEX {
			layer := &scene.layers[instance.layer_index]
			layer_name = (string(layer.name) if layer.name != nil else "")
		}
		visibility := ("hidden" if instance.hidden else "shown")
		pos := instance.transform
		fmt.printf(
			"instance[%d, name=%s] at position (%.0f, %.0f, %.0f) uses model %d and is in layer[%d, name='%s'], group %d, and is %s\n",
			i,
			instance_name,
			pos.m30,
			pos.m31,
			pos.m32,
			instance.model_index,
			instance.layer_index,
			layer_name,
			instance.group_index,
			visibility,
		)
	}

	// Print model info
	fmt.printf("#models: %d\n", scene.num_models)
	for i in 0 ..< scene.num_models {
		model := scene.models[i]
		solid_voxel_count := count_solid_voxels_in_model(model)
		total_voxel_count := model.size_x * model.size_y * model.size_z
		fmt.printf(
			" model[%d] has dimension %dx%dx%d, with %d solid voxels of the total %d voxels (hash=%d)!\n",
			i,
			model.size_x,
			model.size_y,
			model.size_z,
			solid_voxel_count,
			total_voxel_count,
			model.voxel_hash,
		)
	}

	return save_vox_scene("saved.vox", scene)
}

demo_merge_scenes :: proc() {
	fmt.println("\n--- merge scenes")
	source_files := []string {
		VOX_DIR + "vox/chr_old.vox",
		VOX_DIR + "vox/chr_rain.vox",
		VOX_DIR + "vox/chr_sword.vox",
		VOX_DIR + "vox/chr_knight.vox",
		VOX_DIR + "vox/doom.vox",
		VOX_DIR + "vox/test_groups.vox",
	}

	source_scenes := make([dynamic]^ogt.Scene)
	defer {
		for scene in source_scenes {
			if scene != nil {
				ogt.destroy_scene(scene)
			}
		}
		delete(source_scenes)
	}

	for filename in source_files {
		scene, ok := load_vox_scene(filename)
		if ok {
			fmt.printf("Loaded %s for merging.\n", filename)
			append(&source_scenes, scene)
		} else {
			fmt.eprintf("Could not load %s, skipping for merge.\n", filename)
			append(&source_scenes, nil)
		}
	}

	scenes_to_merge := slice.filter(
		source_scenes[:],
		proc(s: ^ogt.Scene) -> bool {return s != nil},
	)

	if len(scenes_to_merge) == 0 {
		fmt.eprintf("No scenes were loaded, cannot perform merge.\n")
		return
	}

	merged_scene: ^ogt.Scene
	use_explicit_output_palette := false

	if use_explicit_output_palette {
		fmt.println("Merging scenes with an explicit output palette.")
		palette_scene, ok := load_vox_scene(VOX_DIR + "vox/test_palette_remap.vox")
		if !ok {
			fmt.eprintf("Could not load palette scene, aborting merge.\n")
			return
		}
		defer ogt.destroy_scene(palette_scene)

		required_colors := palette_scene.palette.color[1:]
		merged_scene = ogt.merge_scenes(
			raw_data(scenes_to_merge),
			u32(len(scenes_to_merge)),
			raw_data(required_colors),
			u32(len(required_colors)),
		)
	} else {
		fmt.println("Merging scenes with an auto-generated palette.")
		merged_scene = ogt.merge_scenes(
			raw_data(scenes_to_merge),
			u32(len(scenes_to_merge)),
			nil,
			0,
		)
	}

	if merged_scene == nil {
		fmt.eprintf("Scene merging failed.\n")
		return
	}
	defer ogt.destroy_scene(merged_scene)

	save_vox_scene("merged.vox", merged_scene)
}


main :: proc() {
	filename := VOX_DIR + "vox/test_groups.vox"
	if len(os.args) > 1 {
		filename = os.args[1]
	}

	if !demo_load_and_save(filename) {
		os.exit(1)
	}

	demo_merge_scenes()

	os.exit(0)
}
