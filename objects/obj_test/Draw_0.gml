disarm_animation_begin(arm);
if (disarm_animation_exists(arm, "NewAnimation")) {
    disarm_animation_add(arm, "NewAnimation", mouse_x / room_width);
}
disarm_animation_end(arm);
disarm_mesh_begin(mesh);
disarm_mesh_add_armature(mesh, arm);
disarm_mesh_end(mesh);
matrix_set(matrix_world, matrix_build(x, y, 0, 0, 0, image_angle, image_xscale, image_yscale, 1));
disarm_mesh_submit(mesh);
matrix_set(matrix_world, matrix_build_identity());
disarm_draw_debug(arm, matrix_build(x, y, 0, 0, 0, image_angle, image_xscale, image_yscale, 1));
//disarm_draw_debug_atlas(arm);