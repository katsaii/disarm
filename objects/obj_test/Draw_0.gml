if (keyboard_check_pressed(vk_enter)) {
    anim = choose("idle", "fall_loop", "walk", "Ladder", "crouch_idle", "jump_000", "hit_0", "die_0", "throw");
    show_debug_message(anim);
}
repeat (30) {
disarm_animation_begin(arm);
if (disarm_animation_exists(arm, anim)) {
    disarm_animation_add(arm, anim, mouse_x / room_width);
}
disarm_animation_end(arm, x, y, image_xscale, image_yscale, image_angle);
disarm_mesh_begin(mesh);
disarm_mesh_add_armature(mesh, arm);
disarm_mesh_end(mesh);
disarm_mesh_submit(mesh);
//disarm_draw_debug(arm);
var point_attachment = disarm_slot_get_data(arm, "point_000");
if (point_attachment != undefined) {
    draw_text(point_attachment.posX, point_attachment.posY, point_attachment.name);
}
}
//disarm_draw_debug_atlas(arm, "armature.json", 10, 10);