/// @desc Update the viewer options.
var dir_x = keyboard_check(vk_right) - keyboard_check(vk_left);
var dir_y = keyboard_check(vk_down) - keyboard_check(vk_up);
var dir_scroll = clamp(
        mouse_wheel_up() - mouse_wheel_down() +
        keyboard_check(vk_pageup) - keyboard_check(vk_pagedown), -1, 1);
scale += dir_scroll * 0.1;
offsetX -= dir_x * scale;
offsetY -= dir_y * scale;
if (keyboard_check_pressed(ord("D"))) {
    debugOverlay = !debugOverlay;
    show_debug_overlay(debugOverlay);
}