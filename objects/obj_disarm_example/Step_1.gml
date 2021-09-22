/// @desc Update the viewer options.
var dir_x = keyboard_check(vk_right) - keyboard_check(vk_left);
var dir_y = keyboard_check(vk_down) - keyboard_check(vk_up);
var dir_scroll = mouse_wheel_up() - mouse_wheel_down();
var dir_page = keyboard_check(vk_pageup) - keyboard_check(vk_pagedown);
scale += dir_scroll * 0.1;
offsetX -= dir_x * scale;
offsetY -= dir_y * scale;
iterations += dir_page;
if (iterations < 1) {
    iterations = 1;
}
if (keyboard_check_pressed(ord("D"))) {
    debugOverlay = !debugOverlay;
    show_debug_overlay(debugOverlay);
}
if (keyboard_check_pressed(ord("B"))) {
    boneOverlay = !boneOverlay;
}
if (keyboard_check_pressed(ord("1"))) {
    animationIdx = 0;
}
if (keyboard_check_pressed(ord("2"))) {
    animationIdx = 1;
}
if (keyboard_check_pressed(ord("3"))) {
    animationIdx = 2;
}
if (keyboard_check_pressed(ord("4"))) {
    animationIdx = 3;
}
if (keyboard_check_pressed(ord("5"))) {
    animationIdx = 4;
}
if (keyboard_check_pressed(ord("6"))) {
    animationIdx = 5;
}
if (keyboard_check_pressed(ord("7"))) {
    animationIdx = 6;
}
if (keyboard_check_pressed(ord("8"))) {
    animationIdx = 7;
}
if (keyboard_check_pressed(ord("9"))) {
    animationIdx = 8;
}
if (keyboard_check_pressed(ord("0"))) {
    animationIdx = 9;
}