show_debug_overlay(true);
arm = disarm_import(disarm_env_file("wanda.scon"));
mesh = disarm_mesh_create();
//disarm_skin_add(arm, "Test Map");
anim = "Test";

view_enabled = true;
view_set_visible(0, true);
camera_set_view_size(view_camera[0], 64, 64);
//camera_set_view_pos(view_camera[0], -32, -32);