disarm_animation_begin(arm);
if (disarm_animation_exists(arm, "walk")) {
    disarm_animation_add(arm, "walk", mouse_x / room_width);
}
disarm_animation_end(arm, x, y, image_xscale, image_yscale, image_angle);
disarm_mesh_begin(mesh);
disarm_mesh_add_armature(mesh, arm);
disarm_mesh_end(mesh);
disarm_mesh_submit(mesh);
disarm_draw_debug(arm);
var point_attachment = disarm_slot_get_data(arm, "point_000");
if (point_attachment != undefined) {
    draw_text(point_attachment.posX, point_attachment.posY, point_attachment.name);
}
//disarm_draw_debug_atlas(arm, "armature.json", 10, 10);