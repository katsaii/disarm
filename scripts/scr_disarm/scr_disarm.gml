/* Disarm Runtime
 * --------------
 * Kat @katsaii
 */

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
    if ("BrashMonkey Spriter" != __disarm_struct_get_string_or_default(_struct, "generator")) {
        return undefined;
    }
    var arm = {
        version : __disarm_struct_get_string_or_default(_struct, "scon_version", undefined),
        atlases : __disarm_array_map(
                __disarm_struct_get_array(_struct, "atlas"),
                __disarm_import_atlas),
        folders : __disarm_array_map(
                __disarm_struct_get_array(_struct, "folder"),
                __disarm_import_folder),
        entities : __disarm_array_map(
                __disarm_struct_get_array(_struct, "entity"),
                __disarm_import_entity),
        currentEntity : 0,
        entityTable : { }
    };
    var entities = arm.entities;
    var entity_table = arm.entityTable;
    for (var i = array_length(entities) - 1; i >= 0; i -= 1) {
        entity_table[$ entities[i].name] = i;
    }
    if (arm.version != "1.0") {
        show_debug_message(
                "Warning: Disarm currently only supports version 1.0 of the Spriter format, " +
                "the animation was loaded correctly but may be unstable");
    }
    return arm;
}

/// @desc Creates a new Disarm atlas instance.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_atlas(_struct) {
    return __disarm_struct_get_string_or_default(_struct, "name");
}

/// @desc Creates a new Disarm folder instance.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_folder(_struct) {
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        atlas : __disarm_struct_get_numeric_or_default(_struct, "atlas", -1),
        files : __disarm_array_map(
                __disarm_struct_get_array(_struct, "file"),
                function(_struct) {
                    return {
                        name : __disarm_struct_get_string_or_default(_struct, "name"),
                        width : __disarm_struct_get_numeric_or_default(_struct, "width", 1, is_numeric),
                        height : __disarm_struct_get_numeric_or_default(_struct, "height", 1, is_numeric),
                        aWidth : __disarm_struct_get_numeric_or_default(_struct, "aw", 1, is_numeric),
                        aHeight : __disarm_struct_get_numeric_or_default(_struct, "ah", 1, is_numeric),
                        aX : __disarm_struct_get_numeric_or_default(_struct, "ax"),
                        aY : __disarm_struct_get_numeric_or_default(_struct, "ay"),
                        aXOff : __disarm_struct_get_numeric_or_default(_struct, "axoff"),
                        aYOff : __disarm_struct_get_numeric_or_default(_struct, "ayoff"),
                        pivotX : __disarm_struct_get_numeric_or_default(_struct, "pivot_x"),
                        pivotY : __disarm_struct_get_numeric_or_default(_struct, "pivot_y"),
                    }
                }),
    };
}

/// @desc Creates a new Disarm entity instance.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity(_struct) {
    var entity = {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        objs : __disarm_array_map(
                __disarm_struct_get_array(_struct, "obj_info"),
                __disarm_import_entity_object),
        anims : __disarm_array_map(
                __disarm_struct_get_array(_struct, "animation"),
                __disarm_import_entity_animation),
        animTable : { },
    };
    var anims = entity.anims;
    var anim_table = entity.animTable;
    for (var i = array_length(anims) - 1; i >= 0; i -= 1) {
        anim_table[$ anims[i].name] = i;
    }
    return entity;
}

/// @desc Creates a new Disarm entity object definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_object(_struct) {
    var type = __disarm_struct_get_string_or_default(_struct, "type", undefined);
    var f = undefined;
    switch (type) {
    case "bone": f = __disarm_import_entity_object_bone; break;
    }
    var obj = f == undefined ? { } : f(_struct);
    obj.name = __disarm_struct_get_string_or_default(_struct, "name");
    obj.type = type;
    obj.active = true;
    obj.slots = [];
    obj.slotCount = 0;
    return obj;
}

/// @desc Creates a new Disarm entity object definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_object_bone(_struct) {
    return {
        width : __disarm_struct_get_numeric_or_default(_struct, "w", 1),
        height : __disarm_struct_get_numeric_or_default(_struct, "h", 1),
        angle : 0,
        scaleX : 1,
        scaleY : 1,
        posX : 0,
        posY : 0,
        objParent : -1,
        invalidWorldTransform : true,
    };
}

/// @desc Creates a new Disarm entity animation definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation(_struct) {
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        time : 0,
        dt : __disarm_struct_get_numeric_or_default(_struct, "interval", -1),
        duration : __disarm_struct_get_numeric_or_default(_struct, "length", -1),
        looping : __disarm_struct_get_numeric_or_default(_struct, "looping", true),
        mainline : __disarm_import_entity_animation_mainline(
                __disarm_struct_get_struct(_struct, "mainline")),
        timelines :  __disarm_array_map(
                __disarm_struct_get_array(_struct, "timeline"),
                __disarm_import_entity_animation_timeline),
    };
}

/// @desc Creates a new Disarm entity animation definition for the main timeline.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_mainline(_struct) {
    return __disarm_array_map(
            __disarm_struct_get_array(_struct, "key"),
            __disarm_import_entity_animation_mainline_keyframe);
}

/// @desc Creates a new Disarm entity animation definition for the main timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_mainline_keyframe(_struct) {
    return {
        time : __disarm_struct_get_numeric_or_default(_struct, "time"),
        objs : __disarm_array_map(
                __disarm_struct_get_array(_struct, "object_ref"),
                function(_struct) {
                    return {
                        objParent : __disarm_struct_get_numeric_or_default(_struct, "parent", -1),
                        key : __disarm_struct_get_numeric_or_default(_struct, "key", -1),
                        timeline : __disarm_struct_get_numeric_or_default(_struct, "timeline", -1),
                        zIndex : __disarm_struct_get_numeric_or_default(_struct, "z_index", 0),
                    };
                }),
        bones : __disarm_array_map(
                __disarm_struct_get_array(_struct, "bone_ref"),
                function(_struct) {
                    return {
                        objParent : __disarm_struct_get_numeric_or_default(_struct, "parent", -1),
                        key : __disarm_struct_get_numeric_or_default(_struct, "key", -1),
                        timeline : __disarm_struct_get_numeric_or_default(_struct, "timeline", -1),
                    };
                }),
    };
}

/// @desc Creates a new Disarm entity animation definition for a timeline.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline(_struct) {
    var type = __disarm_struct_get_string_or_default(_struct, "object_type", undefined);
    var f = __disarm_import_entity_animation_timeline_keyframe;
    switch (type) {
    case "bone": f = __disarm_import_entity_animation_timeline_keyframe_bone; break;
    }
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        obj : __disarm_struct_get_numeric_or_default(_struct, "obj", -1),
        type : type,
        keys : __disarm_array_map(__disarm_struct_get_array(_struct, "key"), f),
    }
}

/// @desc Creates a new Disarm entity animation definition for a timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe(_struct) {
    return {
        time : __disarm_struct_get_numeric_or_default(_struct, "time"),
        spin : __disarm_struct_get_numeric_or_default(_struct, "spin", 1),
    };
}

/// @desc Creates a new Disarm entity animation definition for a timeline keyframes.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe_bone(_struct) {
    var key = __disarm_import_entity_animation_timeline_keyframe(_struct);
    var bone = __disarm_struct_get_struct(_struct, "bone");
    key.angle = __disarm_struct_get_numeric_or_default(bone, "angle");
    key.scaleX = __disarm_struct_get_numeric_or_default(bone, "scale_x", 1);
    key.scaleY = __disarm_struct_get_numeric_or_default(bone, "scale_y", 1);
    key.posX = __disarm_struct_get_numeric_or_default(bone, "x");
    key.posY = __disarm_struct_get_numeric_or_default(bone, "y");
    key.a = __disarm_struct_get_numeric_or_default(bone, "a", 1);
    return key;
}

/// @desc Resets the state of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_begin(_arm) {
    var objs = _arm.entities[_arm.currentEntity].objs;
    for (var i = array_length(objs) - 1; i >= 0; i -= 1) {
        var obj = objs[i];
        obj.active = false;
        obj.slotCount = 0;
        switch (obj.type) {
        case "bone":
            obj.invalidWorldTransform = true;
            obj.angle = 0;
            obj.scaleX = 1;
            obj.scaleY = 1;
            obj.posX = 0;
            obj.posY = 0;
            obj.objParent = -1;
            break;
        }
    }
}

/// @desc Returns whether an entity exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} entity The name of the entity to check.
function disarm_entity_exists(_arm, _entity) {
    return variable_struct_exists(_arm.entityTable, _entity);
}

/// @desc Adds an animation to the armature pose.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} entity The name of the entity to set.
function disarm_entity_set(_arm, _entity) {
    _arm.currentEntity = _arm.entityTable[$ _entity];
}

/// @desc Returns whether an animation exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} anim The name of the animation to check.
function disarm_animation_exists(_arm, _anim) {
    return variable_struct_exists(_arm.entities[_arm.currentEntity].animTable, _anim);
}

/// @desc Adds an animation to the armature pose.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} anim The name of the animation to play.
/// @param {real} amount The progress, as a number between 0 and 1, of the animation.
/// @param {real} [blend_mode] The blend mode to use when applying the animation.
function disarm_animation_add(_arm, _anim, _amount, _blend_mode="overlay") {
    var entity = _arm.entities[_arm.currentEntity];
    var objs = entity.objs;
    var anim = entity.anims[entity.animTable[$ _anim]];
    var mainline = anim.mainline;
    var timelines = anim.timelines;
    var looping = anim.looping;
    var time_progress = clamp(_amount, 0, 1);
    var time_duration = anim.duration;
    var time = lerp(0, time_duration, time_progress);
    var idx_mainframe = __disarm_find_struct_with_time_in_array(mainline, time);
    if (idx_mainframe == -1) {
        if (looping) {
            idx_mainframe = array_length(mainline) - 1; // last frame
        } else {
            idx_mainframe = 0; // first frame
        }
    }
    var mainframe = mainline[idx_mainframe];
    // apply bone animations
    var bone_refs = mainframe.bones;
    var bone_ref_count = array_length(bone_refs);
    for (var i = 0; i < bone_ref_count; i += 1) {
        var bone_ref = bone_refs[i];
        var timeline = timelines[bone_ref.timeline];
        var keys = timeline.keys;
        var idx_key = bone_ref.key;
        var key = keys[idx_key];
        var key_next = idx_key + 1 < array_length(keys) ? keys[idx_key + 1] : undefined;
        // get interpolation
        var angle = key.angle;
        var scale_x = key.scaleX;
        var scale_y = key.scaleY;
        var pos_x = key.posX;
        var pos_y = key.posY;
        var a = key.a;
        if (looping || key_next != undefined) {
            if (key_next == undefined) {
                key_next = keys[0];
            }
            var time_mid = time;
            var time_key = key.time;
            var time_key_end = key_next.time;
            if (looping) {
                // wrap around animation
                if (time_mid < time_key) {
                    time_mid += time_duration;
                }
                if (time_key_end < time_key) {
                    time_key_end += time_duration;
                }
            }
            var interp = clamp((time_mid - time_key) / (time_key_end - time_key), 0, 1);
            angle = __disarm_animation_lerp_angle(angle, key_next.angle, key.spin, interp);
            scale_x = lerp(scale_x, key_next.scaleX, interp);
            scale_y = lerp(scale_y, key_next.scaleY, interp);
            pos_x = lerp(pos_x, key_next.posX, interp);
            pos_y = lerp(pos_y, key_next.posY, interp);
            a = lerp(pos_y, key_next.posY, interp);
        }
        // apply transformations
        var bone = objs[timeline.obj];
        bone.active = true; // enables the bone visibility
        bone.angle = angle;
        bone.scaleX = scale_x;
        bone.scaleY = scale_y;
        bone.posX = pos_x;
        bone.posY = pos_y;
        bone.a = a;
        bone.objParent = bone_ref.objParent;
    }
}

/// @desc Updates the world transformation of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_end(_arm) {
    var objs = _arm.entities[_arm.currentEntity].objs;
    for (var i = array_length(objs) - 1; i >= 0; i -= 1) {
        __disarm_update_world_transform_using_object_array(objs, i);
    }
}

/// @desc Updates the world transformation of a specific armature object using this array of objects.
/// @param {array} objs The object array.
/// @param {real} id The object index.
function __disarm_update_world_transform_using_object_array(_objs, _idx) {
    var obj = _objs[_idx];
    if (obj.invalidWorldTransform && obj.active) {
        obj.invalidWorldTransform = false;
        switch (obj.type) {
        case "bone":
            var idx_par = obj.objParent;
            if (idx_par != -1) {
                var par = __disarm_update_world_transform_using_object_array(_objs, idx_par);
                var par_x = par.posX;
                var par_y = par.posY;
                var par_scale_x = par.scaleX;
                var par_scale_y = par.scaleY;
                var par_dir = par.angle;
                obj.angle += par_dir;
                var obj_x = obj.posX;
                var obj_y = obj.posY;
                obj.posX = par_x +
                        lengthdir_x(obj_x * par_scale_x, par_dir) +
                        lengthdir_y(obj_y * par_scale_y, par_dir);
                obj.posY = par_y +
                        lengthdir_y(obj_x * par_scale_x, par_dir) +
                        lengthdir_x(obj_y * par_scale_y, par_dir);
            }
            break;
        }
    }
    return obj;
}

/// @desc Renders a debug view of the armature.
/// @param {struct} Disarm The Disarm instance to render.
/// @param {matrix} transform The global transformation to apply to this armature.
function disarm_draw_debug(_arm, _matrix=undefined) {
    var objs = _arm.entities[_arm.currentEntity].objs;
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
        case "bone":
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

/// @desc Attempts to get a string value from a struct, and returns a default value
///       if it doesn't exist.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {value} [default] The default value.
function __disarm_struct_get_string_or_default(_struct, _key, _default="") {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        return is_string(value) ? value : string(value);
    }
    return _default;
}

/// @desc Attempts to get a numeric value from a struct, and returns a default value
///       if it doesn't exist.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {value} [default] The default value.
function __disarm_struct_get_numeric_or_default(_struct, _key, _default=0) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        if (is_numeric(value)) {
            return value;
        } else {
            try {
                var n = real(value);
                return n;
            } catch (_) { }
        }
    }
    return _default;
}

/// @desc Attempts to get an array value from a struct.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
function __disarm_struct_get_array(_struct, _key) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        return is_array(value) ? value : [value];
    }
    return [];
}

/// @desc Attempts to get a struct value from a struct.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
function __disarm_struct_get_struct(_struct, _key) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        if (is_struct(value)) {
            return value;
        }
    }
    return { };
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

/// @desc Performs a linear search and returns the ID of the first structure where the `name` field
///       equals the expected name, or `-1` if none exist.
/// @param {array} values The array of structs to search.
/// @param {string} name The name to search for.
function __disarm_find_struct_with_name_in_array(_values, _expected_name) {
    var n = array_length(_values);
    for (var i = 0; i < n; i += 1) {
        if (_values[i].name == _expected_name) {
            return i;
        }
    }
    return -1;
}

/// @desc Performs a binary search and returns the ID of the first structure where the `time` field
///       is greater than the expected time, or `-1` if none exist.
/// @param {array} values The array of structs to search.
/// @param {string} time The time to search for.
function __disarm_find_struct_with_time_in_array(_values, _expected_time) {
    var n = array_length(_values);
    var l = 0;
    var r = n - 1;
    while (r >= l) {
        var mid = (l + r) div 2;
        var t_start = _values[mid].time;
        var t_end = mid + 1 < n ? _values[mid + 1].time : infinity;
        if (_expected_time >= t_start && _expected_time < t_end) {
            return mid;
        }
        if (_expected_time < t_start) {
            r = mid - 1;
        } else {
            l = mid + 1;
        }
    }
    return -1;
}

/// @desc Interpolates between two angles in the direction of `spin`.
/// @param {real} a The starting angle.
/// @param {real} b The target angle.
/// @param {real} spin The direction to rotate.
/// @param {real} amount The interpolation amount.
function __disarm_animation_lerp_angle(_a, _b, _spin, _amount) {
    if (_spin == 0) {
        return _a;
    }
    if (_spin > 0) {
        if (_b - _a < 0) {
            _b += 360;
        }
    } else if (_spin < 0) {
        if (_b - _a > 0) {
            _b -= 360;
        }
    }
    return lerp(_a, _b, _amount);
}