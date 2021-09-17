/// @desc Update mesh.
animationBlend += animationSpeed;
if (animationBlend > 1 || animationBlend < 0) {
    animationBlend = ((animationBlend % 1) + 1) % 1;
}
disarm_animation_begin(arm);
disarm_animation_add(arm, anim, animationBlend);
disarm_animation_end(arm, offsetX, offsetY, scaleX, scaleY);
disarm_mesh_begin(mesh);
disarm_mesh_add_armature(mesh, arm);
disarm_mesh_end(mesh);