/// @desc Render the mesh.
disarm_mesh_submit(mesh); // this causes issues in html5, idk why
if (boneOverlay) {
    disarm_draw_debug(arm, offsetX, offsetY, scale, scale);
}