/// @desc Draw the options.
var bool_to_string = function(_b) { return _b ? "true" : "false"; }
var text = [
    ["X", offsetX, "left and right"],
    ["Y", offsetY, "up and down"],
    ["Scale", scale, "scroll"],
    ["Debug overlay", bool_to_string(debugOverlay), "D"],
    ["Bone overlay", bool_to_string(boneOverlay), "B"],
    ["Iterations", iterations, "page up and page down"],
    ["Animation ID", animationIdx + 1, "number keys 0-9"],
];
var n = array_length(text);
var pad = 20;
var sep = 20;
for (var i = 0; i < n; i += 1) {
    var text_pair = text[i];
    draw_text(pad, pad + i * sep, text_pair[0] + ": " + string(text_pair[1]) + " (" + text_pair[2] + ")");
}
var names = __disarm_array_map(arm.entities[arm.currentEntity].slots, function(_x) {
    return _x.name;
});
var pad = 20;
var sep = 20;
for (var i = 0; i < array_length(names); i += 1) {
    var name = names[i];
    var over_limit = i >= arm.entities[arm.currentEntity].slotCount;
    draw_text(pad + 325 + over_limit * pad, pad + i * sep, name);
}