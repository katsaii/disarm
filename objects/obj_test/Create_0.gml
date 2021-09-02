show_debug_overlay(true);
arm = disarm_import(disarm_env_file("armature.scon"));
mesh = disarm_mesh_create();
disarm_skin_add(arm, "Test Map");