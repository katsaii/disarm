disarm_animation_begin(arm);
if (disarm_animation_exists(arm, "NewAnimation")) {
    disarm_animation_add(arm, "NewAnimation", mouse_x / room_width);
}
disarm_animation_end(arm);
disarm_draw_debug(arm, matrix_build(x, y, 0, 0, 0, image_angle, image_xscale, image_yscale, 1));