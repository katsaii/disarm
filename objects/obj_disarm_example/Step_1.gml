/// @desc Update the viewer options.
var dir_x = keyboard_check(vk_right) - keyboard_check(vk_left);
var dir_y = keyboard_check(vk_down) - keyboard_check(vk_up);
var dir_scroll = mouse_wheel_up() - mouse_wheel_down();
scale += dir_scroll * 0.1;
offsetX -= dir_x * scale;
offsetY -= dir_y * scale;