/// @desc Update mesh.
animationBlend += animationSpeed;
if (animationBlend > 1 || animationBlend < 0) {
    animationBlend = ((animationBlend % 1) + 1) % 1;
}
repeat (iterations) { // not required, but tests performance of the animations
    disarm_animation_begin(arm);
    disarm_animation_add(arm, anim, animationBlend);
    disarm_animation_end(arm);
    disarm_mesh_begin(mesh);
    disarm_mesh_add_armature(mesh, arm, transform);
    disarm_mesh_end(mesh);
}