/* Disarm Runtime
 * --------------
 * Kat @katsaii
 */

#macro __DISARM_TYPE_SPRITE "sprite"
#macro __DISARM_TYPE_BONE "bone"
#macro __DISARM_TYPE_BOX "box"
#macro __DISARM_TYPE_POINT "point"
#macro __DISARM_TYPE_SOUND "sound"
#macro __DISARM_TYPE_ENTITY "entity"
#macro __DISARM_TYPE_VARIABLE "variable"
#macro __DISARM_TYPE_UNKNOWN "unknown"

/// @desc Reads the contents of a file and attempts to build a new Disarm instance from the contents.
/// @param {string} filepath The path of the Spriter project file.
function disarm_import(_path) {
    if not (file_exists(_path)) {
        return undefined;
    }
    var file = file_text_open_read(_path);
    var src = "";
    while not (file_text_eof(file)) {
        src += file_text_readln(file);
    }
    file_text_close(file);
    return disarm_import_from_string(src);
}

/// @desc Attempts to parse this JSON string into a Disarm instance.
/// @param {string} scon The Spriter JSON file as a string.
function disarm_import_from_string(_scon) {
    return disarm_import_from_struct(json_parse(_scon));
}

/// @desc Uses this GML struct to construct a Disarm instance.
/// @param {struct} struct A struct containing the Spriter project information.
function disarm_import_from_struct(_struct) {
    if not (is_struct(_struct)) {
        return undefined;
    }
    if ("BrashMonkey Spriter" != __disarm_struct_get_or_default(
            _struct, "generator", undefined, is_string)) {
        return undefined;
    }
    var arm = {
        version : __disarm_struct_get_or_default(_struct, "scon_version", undefined, is_string),
        entities : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "entity", [], is_array),
                __disarm_import_entity),
        currentEntity : 0,
    };
    if (arm.version != "1.0") {
        show_debug_message(
                "Warning: Disarm currently only supports version 1.0 of the Spriter format, " +
                "the animation was loaded correctly but may be unstable");
    }
    return arm;
}

/// @desc Creates a new Disarm entity instance.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity(_struct) {
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        name : __disarm_struct_get_or_default(_struct, "name", "", is_string),
        objs : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "obj_info", [], is_array),
                __disarm_import_entity_object),
        anims : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "animation", [], is_array),
                __disarm_import_entity_animation),
    };
}

/// @desc Creates a new Disarm entity object definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_object(_struct) {
    var type = __disarm_struct_get_or_default(_struct, "type", __DISARM_TYPE_UNKNOWN, is_string);
    var f = undefined;
    switch (type) {
    case __DISARM_TYPE_SPRITE: break;
    case __DISARM_TYPE_BONE: f = __disarm_import_entity_object_bone; break;
    case __DISARM_TYPE_BOX: break;
    case __DISARM_TYPE_POINT: break;
    case __DISARM_TYPE_SOUND: break;
    case __DISARM_TYPE_ENTITY: break;
    case __DISARM_TYPE_VARIABLE: break;
    }
    var obj = f == undefined ? { } : f(_struct);
    obj.name = __disarm_struct_get_or_default(_struct, "name", "", is_string);
    obj.type = type;
    obj.active = false;
    return obj;
}

/// @desc Creates a new Disarm entity object definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_object_bone(_struct) {
    return {
        width : __disarm_struct_get_or_default(_struct, "w", 1, is_numeric),
        height : __disarm_struct_get_or_default(_struct, "h", 1, is_numeric),
        angle : 0,
        scaleX : 1,
        scaleY : 1,
        posX : 0,
        posY : 0,
        idxParent : -1,
        invalidWorldTransform : true,
    };
}

/// @desc Creates a new Disarm entity animation definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation(_struct) {
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        name : __disarm_struct_get_or_default(_struct, "name", "", is_string),
        time : 0,
        dt : __disarm_struct_get_or_default(_struct, "interval", -1, is_numeric),
        duration : __disarm_struct_get_or_default(_struct, "length", -1, is_numeric),
        looping : __disarm_struct_get_or_default(_struct, "looping", false, is_numeric),
        mainline : __disarm_import_entity_animation_mainline(
                __disarm_struct_get_or_default(_struct, "mainline", { }, is_struct)),
        timelines :  __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "timeline", [], is_array),
                __disarm_import_entity_animation_timeline),
    };
}

/// @desc Creates a new Disarm entity animation definition for the main timeline.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_mainline(_struct) {
    return __disarm_array_map(
            __disarm_struct_get_or_default(_struct, "key", [], is_array),
            __disarm_import_entity_animation_mainline_keyframe);
}

/// @desc Creates a new Disarm entity animation definition for the main timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_mainline_keyframe(_struct) {
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        time : __disarm_struct_get_or_default(_struct, "time", 0, is_numeric),
        objs : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "object_ref", [], is_array),
                function(_struct) {
                    return {
                        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
                        idxParent : __disarm_struct_get_or_default(_struct, "parent", -1, is_numeric),
                        key : __disarm_struct_get_or_default(_struct, "key", -1, is_numeric),
                        timeline : __disarm_struct_get_or_default(_struct, "timeline", -1, is_numeric),
                        zIndex : __disarm_struct_get_or_default(_struct, "z_index", 0, is_numeric),
                    };
                }),
        bones : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "bone_ref", [], is_array),
                function(_struct) {
                    return {
                        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
                        idxParent : __disarm_struct_get_or_default(_struct, "parent", -1, is_numeric),
                        key : __disarm_struct_get_or_default(_struct, "key", -1, is_numeric),
                        timeline : __disarm_struct_get_or_default(_struct, "timeline", -1, is_numeric),
                    };
                }),
    };
}

/// @desc Creates a new Disarm entity animation definition for a timeline.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline(_struct) {
    var type = __disarm_struct_get_or_default(_struct, "object_type", __DISARM_TYPE_UNKNOWN, is_string);
    var f = __disarm_import_entity_animation_timeline_keyframe;
    switch (type) {
    case __DISARM_TYPE_SPRITE: break;
    case __DISARM_TYPE_BONE: f = __disarm_import_entity_animation_timeline_keyframe_bone; break;
    case __DISARM_TYPE_BOX: break;
    case __DISARM_TYPE_POINT: break;
    case __DISARM_TYPE_SOUND: break;
    case __DISARM_TYPE_ENTITY: break;
    case __DISARM_TYPE_VARIABLE: break;
    }
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        name : __disarm_struct_get_or_default(_struct, "name", "", is_string),
        obj : __disarm_struct_get_or_default(_struct, "obj", -1, is_numeric),
        type : type,
        keys : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "key", [], is_array),
                f),
    }
}

/// @desc Creates a new Disarm entity animation definition for a timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe(_struct) {
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        time : __disarm_struct_get_or_default(_struct, "time", 0, is_numeric),
        spin : __disarm_struct_get_or_default(_struct, "spin", 1, is_numeric),
    };
}

/// @desc Creates a new Disarm entity animation definition for a timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe_bone(_struct) {
    var key = __disarm_import_entity_animation_timeline_keyframe(_struct);
    var bone = __disarm_struct_get_or_default(_struct, __DISARM_TYPE_BONE, { }, is_struct);
    key.angle = __disarm_struct_get_or_default(bone, "angle", 0, is_numeric);
    key.scaleX = __disarm_struct_get_or_default(bone, "scale_x", 1, is_numeric);
    key.scaleY = __disarm_struct_get_or_default(bone, "scale_y", 1, is_numeric);
    key.posX = __disarm_struct_get_or_default(bone, "x", 0, is_numeric);
    key.posY = __disarm_struct_get_or_default(bone, "y", 0, is_numeric);
    key.a = __disarm_struct_get_or_default(bone, "a", 1, is_numeric);
    return key;
}

/// @desc Rendersa debug view of the armature.
/// @param {struct} disarm The disarm instance to render.
/// @param {matrix} transform The global transformation to apply to this armature.
function disarm_draw_debug(_disarm, _matrix=undefined) {
    var objs = _disarm.entities[_disarm.currentEntity].objs;
    var default_colour = draw_get_color();
    var default_alpha = draw_get_alpha();
    if (_matrix != undefined) {
        var default_matrix = matrix_get(matrix_world);
        matrix_set(matrix_world, _matrix);
        _matrix = default_matrix;
    }
    for (var i = array_length(objs) - 1; i >= 0; i -= 1) {
        var obj = objs[i];
        if not (obj.active) {
            continue;
        }
        switch (obj.type) {
        case __DISARM_TYPE_BONE:
            var len = obj.width * obj.scaleX;
            var wid = obj.height * obj.scaleY;
            var dir = obj.angle;
            var x1 = obj.posX;
            var y1 = obj.posY;
            var x2 = x1 + lengthdir_x(len, dir);
            var y2 = y1 + lengthdir_y(len, dir);
            draw_set_colour(obj.invalidWorldTransform ? c_red : c_yellow);
            draw_arrow(x1, y1, x2, y2, wid);
            break;
        }
    }
    if (_matrix != undefined) {
        matrix_set(matrix_world, _matrix);
    }
    draw_set_colour(default_colour);
    draw_set_alpha(default_alpha);
}

/// @desc Attempts to get a value from a struct with a specific type, and returns a default value if it doesn't exist or the type is wrong.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {value} default The default value.
/// @param {script} [p] The predicate that the value must hold for.
function __disarm_struct_get_or_default(_struct, _key, _default, _p=undefined) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        if (_p == undefined || _p(value)) {
            return value;
        }
    }
    return _default;
}

/// @desc Creates a new array of the same size by applying some function to the middle values.
/// @param {array} in The input array.
/// @param {script} f The script to call on each element of the array.
function __disarm_array_map(_in, _f) {
    var n = array_length(_in);
    var out = array_create(n);
    for (var i = n - 1; i >= 0; i -= 1) {
        out[@ i] = _f(_in[i]);
    }
    return out;
}