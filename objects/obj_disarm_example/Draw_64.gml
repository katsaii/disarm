/// @desc Draw the options.
var bool_to_string = function(_b) { return _b ? "true" : "false"; }
var text = [
    ["X", offsetX],
    ["Y", offsetY],
    ["Scale", scale],
    ["Debug overlay", bool_to_string(debugOverlay)],
];
var n = array_length(text);
var pad = 10;
var sep = 20;
for (var i = 0; i < n; i += 1) {
    var text_pair = text[i];
    draw_text(pad, pad + i * sep, text_pair[0] + ": " + string(text_pair[1]));
}