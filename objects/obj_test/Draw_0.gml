disarm_animation_begin(arm);
if (disarm_animation_exists(arm, "NewAnimation")) {
    disarm_animation_add(arm, "NewAnimation", mouse_x / room_width);
}
disarm_animation_end(arm, x, y, image_xscale, image_yscale, image_angle + current_time * 0.1);
disarm_mesh_begin(mesh);
disarm_mesh_add_armature(mesh, arm);
disarm_mesh_end(mesh);
disarm_mesh_submit(mesh);
disarm_draw_debug(arm);
//disarm_draw_debug_atlas(arm, "armature.json", 10, 10);