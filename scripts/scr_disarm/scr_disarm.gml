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
/// @param {struct} [template] The functions to call when loading atlas files and images.
function disarm_import_from_string(_scon) {
    var struct = json_parse(_scon);
    if not (is_struct(struct)) {
        return undefined;
    }
    if ("BrashMonkey Spriter" != __disarm_struct_get_string_or_default(struct, "generator")) {
        return undefined;
    }
    var arm = {
        version : __disarm_struct_get_string_or_default(struct, "scon_version", undefined),
        atlases : __disarm_array_map(
                __disarm_struct_get_array(struct, "atlas"),
                __disarm_import_atlas),
        folders : __disarm_array_map(
                __disarm_struct_get_array(struct, "folder"),
                __disarm_import_folder),
        entities : __disarm_array_map(
                __disarm_struct_get_array(struct, "entity"),
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
        info : __disarm_array_map(
                __disarm_struct_get_array(_struct, "obj_info"),
                __disarm_import_entity_object),
        slots : [],
        slotsDrawOrder : [],
        slotTable : { },
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
    var slot = f == undefined ? { } : f(_struct);
    slot.name = __disarm_struct_get_string_or_default(_struct, "name");
    slot.type = type;
    slot.active = true;
    return slot;
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
        boneParent : -1,
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
        slots : __disarm_array_map(
                __disarm_struct_get_array(_struct, "object_ref"),
                function(_struct) {
                    return {
                        boneParent : __disarm_struct_get_numeric_or_default(_struct, "parent", -1),
                        key : __disarm_struct_get_numeric_or_default(_struct, "key", -1),
                        timeline : __disarm_struct_get_numeric_or_default(_struct, "timeline", -1),
                        zIndex : __disarm_struct_get_numeric_or_default(_struct, "z_index", 0),
                    };
                }),
        bones : __disarm_array_map(
                __disarm_struct_get_array(_struct, "bone_ref"),
                function(_struct) {
                    return {
                        boneParent : __disarm_struct_get_numeric_or_default(_struct, "parent", -1),
                        key : __disarm_struct_get_numeric_or_default(_struct, "key", -1),
                        timeline : __disarm_struct_get_numeric_or_default(_struct, "timeline", -1),
                    };
                }),
    };
}

/// @desc Creates a new Disarm entity animation definition for a timeline.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline(_struct) {
    var type = __disarm_struct_get_string_or_default(_struct, "object_type", "sprite");
    var f = __disarm_import_entity_animation_timeline_keyframe;
    switch (type) {
    case "bone": f = __disarm_import_entity_animation_timeline_keyframe_bone; break;
    case "sprite": f = __disarm_import_entity_animation_timeline_keyframe_sprite; break;
    case "point": f = __disarm_import_entity_animation_timeline_keyframe_point; break;
    }
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        slot : __disarm_struct_get_numeric_or_default(_struct, "obj", -1),
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

/// @desc Creates a new Disarm entity animation definition for a bone keyframe.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe_bone(_struct) {
    var key = __disarm_import_entity_animation_timeline_keyframe(_struct);
    var bone = __disarm_struct_get_struct(_struct, "bone");
    key.posX = __disarm_struct_get_numeric_or_default(bone, "x");
    key.posY = -__disarm_struct_get_numeric_or_default(bone, "y");
    key.angle = __disarm_struct_get_numeric_or_default(bone, "angle");
    key.scaleX = __disarm_struct_get_numeric_or_default(bone, "scale_x", 1);
    key.scaleY = __disarm_struct_get_numeric_or_default(bone, "scale_y", 1);
    key.alpha = __disarm_struct_get_numeric_or_default(bone, "a", 1);
    return key;
}

/// @desc Creates a new Disarm entity animation definition for a sprite keyframe.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe_sprite(_struct) {
    var key = __disarm_import_entity_animation_timeline_keyframe(_struct);
    var slot = __disarm_struct_get_struct(_struct, "object");
    key.folder = __disarm_struct_get_numeric_or_default(slot, "folder");
    key.file = __disarm_struct_get_numeric_or_default(slot, "file");
    key.posX = __disarm_struct_get_numeric_or_default(slot, "x");
    key.posY = -__disarm_struct_get_numeric_or_default(slot, "y");
    key.angle = __disarm_struct_get_numeric_or_default(slot, "angle");
    key.scaleX = __disarm_struct_get_numeric_or_default(slot, "scale_x", 1);
    key.scaleY = __disarm_struct_get_numeric_or_default(slot, "scale_y", 1);
    key.pivotX = __disarm_struct_get_numeric_or_default(slot, "pivot_x");
    key.pivotY = __disarm_struct_get_numeric_or_default(slot, "pivot_y", 1);
    key.alpha = __disarm_struct_get_numeric_or_default(slot, "a", 1);
    return key;
}

/// @desc Creates a new Disarm entity animation definition for a point keyframe.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation_timeline_keyframe_point(_struct) {
    var key = __disarm_import_entity_animation_timeline_keyframe(_struct);
    var slot = __disarm_struct_get_struct(_struct, "object");
    key.posX = __disarm_struct_get_numeric_or_default(slot, "x");
    key.posY = -__disarm_struct_get_numeric_or_default(slot, "y");
    key.angle = __disarm_struct_get_numeric_or_default(slot, "angle");
    key.scaleX = __disarm_struct_get_numeric_or_default(slot, "scale_x", 1);
    key.scaleY = __disarm_struct_get_numeric_or_default(slot, "scale_y", 1);
    key.alpha = __disarm_struct_get_numeric_or_default(slot, "a", 1);
    return key;
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

/// @desc Returns the linear interpolation of two keyframe times.
/// @param {real} seek The seek time.
/// @param {real} start The start frame time.
/// @param {real} end The end frame time.
/// @param {real} looping Whether the animation is looping.
/// @param {real} duration If looping, the duration of the animation.
function __disarm_animation_calculate_animation_interpolation_between_keyframes(_seek, _start, _end, _looping, _duration) {
    if (_looping) {
        // wrap around animation
        if (_seek < _start) {
            _seek += _duration;
        }
        if (_end < _start) {
            _end += _duration;
        }
    }
    return _end == _start ? 0 : clamp((_seek - _start) / (_end - _start), 0, 1);
}

/// @desc Returns the slot with this name, or creates a new slot if it doesn't exist.
/// @param {string} name The name of the slot.
/// @param {string} type The type of slot.
/// @param {struct} table The table of slots to look-up.
/// @param {array} array The array to insert a new slot into if one doesn't exist.
function __disarm_animation_get_slot_by_name_or_spawn_new(_name, _type, _slot_table, _slots) {
    if (variable_struct_exists(_slot_table, _name)) {
        return _slot_table[$ _name];
    } else {
        var slot;
        switch (_type) {
        case "sprite":
            slot = {
                folder : -1,
                file : -1,
                posX : 0,
                posY : 0,
                angle : 0,
                scaleX : 1,
                scaleY : 1,
                pivotX : 0,
                pivotY : 1,
                alpha : 1,
                aX : 0, bX : 0, cX : 0, dX : 0,
                aY : 0, bY : 0, cY : 0, dY : 0,
            };
            break;
        case "point":
            slot = {
                posX : 0,
                posY : 0,
                angle : 0,
                scaleX : 1,
                scaleY : 1,
                alpha : 1,
            };
            break;
        default:
            slot = { };
            break;
        }
        slot[$ "name"] = _name;
        slot[$ "type"] = _type;
        slot[$ "boneParent"] = -1;
        slot[$ "zIndex"] = 0;
        _slot_table[$ _name] = slot;
        array_push(_slots, slot);
        return slot;
    }
}

/// @desc Resets the state of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_begin(_arm) {
    var entity = _arm.entities[_arm.currentEntity];
    entity.slots = [];
    entity.slotTable = { };
    var info = entity.info;
    for (var i = array_length(info) - 1; i >= 0; i -= 1) {
        var slot = info[i];
        slot.active = false;
        switch (slot.type) {
        case "bone":
            slot.invalidWorldTransform = true;
            slot.angle = 0;
            slot.scaleX = 1;
            slot.scaleY = 1;
            slot.posX = 0;
            slot.posY = 0;
            slot.boneParent = -1;
            break;
        }
    }
}

/// @desc Adds an animation to the armature pose.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} anim The name of the animation to play.
/// @param {real} amount The progress, as a number between 0 and 1, of the animation.
/// @param {real} [blend_mode] The blend mode to use when applying the animation.
function disarm_animation_add(_arm, _anim, _amount, _blend_mode="overlay") {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slots;
    var slot_table = entity.slotTable;
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
        var key_next = idx_key + 1 < array_length(keys) ? keys[idx_key + 1] : (looping ? keys[0] : undefined);
        // get interpolation
        var pos_x = key.posX;
        var pos_y = key.posY;
        var angle = key.angle;
        var scale_x = key.scaleX;
        var scale_y = key.scaleY;
        var alpha = key.alpha;
        if (key_next != undefined) {
            var interp = __disarm_animation_calculate_animation_interpolation_between_keyframes(
                    time, key.time, key_next.time, looping, time_duration);
            pos_x = lerp(pos_x, key_next.posX, interp);
            pos_y = lerp(pos_y, key_next.posY, interp);
            angle = __disarm_animation_lerp_angle(angle, key_next.angle, key.spin, interp);
            scale_x = lerp(scale_x, key_next.scaleX, interp);
            scale_y = lerp(scale_y, key_next.scaleY, interp);
            alpha = lerp(pos_y, key_next.posY, interp);
        }
        // apply transformations
        var bone = info[timeline.slot];
        bone.active = true; // enables the bone visibility
        bone.posX = pos_x;
        bone.posY = pos_y;
        bone.angle = angle;
        bone.scaleX = scale_x;
        bone.scaleY = scale_y;
        bone.alpha = alpha;
        bone.boneParent = bone_ref.boneParent;
    }
    // apply object animations
    var slot_refs = mainframe.slots;
    var slot_ref_count = array_length(slot_refs);
    for (var i = 0; i < slot_ref_count; i += 1) {
        var slot_ref = slot_refs[i];
        var timeline = timelines[slot_ref.timeline];
        var keys = timeline.keys;
        var type = timeline.type;
        var idx_key = slot_ref.key;
        var key = keys[idx_key];
        var key_next = idx_key + 1 < array_length(keys) ? keys[idx_key + 1] : (looping ? keys[0] : undefined);
        var slot = __disarm_animation_get_slot_by_name_or_spawn_new(timeline.name, type, slot_table, slots);
        switch (type) {
        case "sprite":
            // get interpolation
            var folder = key.folder;
            var file = key.file;
            var pos_x = key.posX;
            var pos_y = key.posY;
            var angle = key.angle;
            var scale_x = key.scaleX;
            var scale_y = key.scaleY;
            var pivot_x = key.pivotX;
            var pivot_y = key.pivotY;
            var alpha = key.alpha;
            if (key_next != undefined) {
                var interp = __disarm_animation_calculate_animation_interpolation_between_keyframes(
                        time, key.time, key_next.time, looping, time_duration);
                pos_x = lerp(pos_x, key_next.posX, interp);
                pos_y = lerp(pos_y, key_next.posY, interp);
                angle = __disarm_animation_lerp_angle(angle, key_next.angle, key.spin, interp);
                scale_x = lerp(scale_x, key_next.scaleX, interp);
                scale_y = lerp(scale_y, key_next.scaleY, interp);
                pivot_x = lerp(pivot_x, key_next.pivotX, interp);
                pivot_y = lerp(pivot_y, key_next.pivotY, interp);
                alpha = lerp(pos_y, key_next.posY, interp);
            }
            // apply transformations
            slot.folder = folder;
            slot.file = file;
            slot.posX = pos_x;
            slot.posY = pos_y;
            slot.angle = angle;
            slot.scaleX = scale_x;
            slot.scaleY = scale_y;
            slot.pivotX = pivot_x;
            slot.pivotY = pivot_y;
            slot.alpha = alpha;
            break;
        case "point":
            // get interpolation
            var pos_x = key.posX;
            var pos_y = key.posY;
            var angle = key.angle;
            var scale_x = key.scaleX;
            var scale_y = key.scaleY;
            var alpha = key.alpha;
            if (key_next != undefined) {
                var interp = __disarm_animation_calculate_animation_interpolation_between_keyframes(
                        time, key.time, key_next.time, looping, time_duration);
                pos_x = lerp(pos_x, key_next.posX, interp);
                pos_y = lerp(pos_y, key_next.posY, interp);
                angle = __disarm_animation_lerp_angle(angle, key_next.angle, key.spin, interp);
                scale_x = lerp(scale_x, key_next.scaleX, interp);
                scale_y = lerp(scale_y, key_next.scaleY, interp);
                alpha = lerp(pos_y, key_next.posY, interp);
            }
            // apply transformations
            slot.posX = pos_x;
            slot.posY = pos_y;
            slot.angle = angle;
            slot.scaleX = scale_x;
            slot.scaleY = scale_y;
            slot.alpha = alpha;
            break;
        }
        slot.boneParent = slot_ref.boneParent;
        slot.zIndex = slot_ref.zIndex;
    }
}

/// @desc Updates the world transformation of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_end(_arm) {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slots;
    var folders = _arm.folders;
    for (var i = array_length(info) - 1; i >= 0; i -= 1) {
        __disarm_update_world_transform_using_object_array(info, i);
    }
    for (var i = array_length(slots) - 1; i >= 0; i -= 1) {
        var slot = slots[i];
        var idx_parent = slot.boneParent;
        var bone_parent = idx_parent == -1 ? undefined : info[idx_parent];
        switch (slot.type) {
        case "sprite":
            var idx_folder = slot.folder;
            var idx_file = slot.file;
            if (idx_folder == -1 || idx_file == -1) {
                continue;
            }
            __disarm_update_world_transform(slot, bone_parent);
            var folder = folders[idx_folder];
            var file = folder.files[idx_file];
            var left = -file.pivotX;
            var top = -file.pivotY;
            var right = left + file.width;
            var bottom = top + file.height;
            var slot_x = slot.posX;
            var slot_y = slot.posY;
            var slot_scale_x = slot.scaleX;
            var slot_scale_y = slot.scaleY;
            var slot_dir = slot.angle;
            var i_x = lengthdir_x(slot_scale_x, slot_dir);
            var i_y = lengthdir_y(slot_scale_x, slot_dir);
            var j_x = lengthdir_x(slot_scale_y, slot_dir - 90);
            var j_y = lengthdir_y(slot_scale_y, slot_dir - 90);
            slot.aX = slot_x + left * i_x + top * j_x;
            slot.aY = slot_y + left * i_y + top * j_y;
            slot.bX = slot_x + right * i_x + top * j_x;
            slot.bY = slot_y + right * i_y + top * j_y;
            slot.cX = slot_x + right * i_x + bottom * j_x;
            slot.cY = slot_y + right * i_y + bottom * j_y;
            slot.dX = slot_x + left * i_x + bottom * j_x;
            slot.dY = slot_y + left * i_y + bottom * j_y;
            break;
        case "point":
            __disarm_update_world_transform(slot, bone_parent);
            break;
        }
    }
    var draw_order = __disarm_wierd_hack_for_array_clone(slots);
    entity.slotsDrawOrder = draw_order;
    array_sort(draw_order, function(_a, _b) {
        var a_z = _a.zIndex;
        var b_z = _b.zIndex;
        if (a_z < b_z) {
            return -1;
        } else if (a_z > b_z) {
            return 1;
        } else {
            return 0;
        }
    });
}

/// @desc Returns a clone of an array.
/// @param variable {Array} The array to clone.
function __disarm_wierd_hack_for_array_clone(_in) {
    if (array_length(_in) < 1) {
        return [];
    }
    _in[0] = _in[0];
    return _in;
}

/// @desc Updates the world transformation of a specific armature object using this array of objects.
/// @param {array} info The object array.
/// @param {real} id The object index.
function __disarm_update_world_transform_using_object_array(_objs, _idx) {
    var bone = _objs[_idx];
    if (bone.invalidWorldTransform && bone.active) {
        bone.invalidWorldTransform = false;
        switch (bone.type) {
        case "bone":
            var idx_parent = bone.boneParent;
            var bone_parent = idx_parent == -1 ? undefined : __disarm_update_world_transform_using_object_array(_objs, idx_parent);
            __disarm_update_world_transform(bone, bone_parent);
            break;
        }
    }
    return bone;
}

/// @desc Updates the world transformation of a specific armature object using this array of objects.
/// @param {struct} child The object to update.
/// @param {struct} parent The parent to use.
/// @param {real} [up] The direction of the "up" vector.
function __disarm_update_world_transform(_child, _bone_parent) {
    if (_bone_parent == undefined) {
        return;
    }
    var par_x = _bone_parent.posX;
    var par_y = _bone_parent.posY;
    var par_scale_x = _bone_parent.scaleX;
    var par_scale_y = _bone_parent.scaleY;
    var par_dir = _bone_parent.angle;
    var par_alpha = _bone_parent.alpha;
    _child.angle += par_dir;
    _child.scaleX *= par_scale_x;
    _child.scaleY *= par_scale_y;
    _child.alpha *= par_alpha;
    var fk = __disarm_apply_forward_kinematics(_child.posX * par_scale_x, _child.posY * par_scale_y, par_dir);
    _child.posX = par_x + fk[0];
    _child.posY = par_y + fk[1];
}

/// @desc Applies forward kinematics and returns a new point.
/// @param {real} x The x position to rotate.
/// @param {real} y The y position to rotate.
/// @param {real} angle The angle to rotate about.
function __disarm_apply_forward_kinematics(_x, _y, _angle) {
    return [
        lengthdir_x(_x, _angle) + lengthdir_x(_y, _angle - 90),
        lengthdir_y(_x, _angle) + lengthdir_y(_y, _angle - 90)
    ];
}

/// @desc Renders a debug view of the armature.
/// @param {struct} Disarm The Disarm instance to render.
/// @param {matrix} transform The global transformation to apply to this armature.
function disarm_draw_debug(_arm, _matrix=undefined) {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slotsDrawOrder;
    var default_colour = draw_get_color();
    var default_alpha = draw_get_alpha();
    draw_set_alpha(1);
    if (_matrix != undefined) {
        var default_matrix = matrix_get(matrix_world);
        matrix_set(matrix_world, _matrix);
        _matrix = default_matrix;
    }
    for (var i = array_length(info) - 1; i >= 0; i -= 1) {
        var slot = info[i];
        if not (slot.active) {
            continue;
        }
        switch (slot.type) {
        case "bone":
            var len = slot.width * slot.scaleX;
            var wid = slot.height * slot.scaleY;
            var dir = slot.angle;
            var x1 = slot.posX;
            var y1 = slot.posY;
            var x2 = x1 + lengthdir_x(len, dir);
            var y2 = y1 + lengthdir_y(len, dir);
            draw_set_colour(slot.invalidWorldTransform ? c_red : c_yellow);
            draw_arrow(x1, y1, x2, y2, wid);
            break;
        }
    }
    for (var i = array_length(slots) - 1; i >= 0; i -= 1) {
        var slot = slots[i];
        switch (slot.type) {
        case "sprite":
            var alpha = 1;
            var col = c_green;
            draw_primitive_begin(pr_linestrip);
            draw_vertex_color(slot.aX, slot.aY, col, alpha);
            draw_vertex_color(slot.bX, slot.bY, col, alpha);
            draw_vertex_color(slot.cX, slot.cY, col, alpha);
            draw_vertex_color(slot.dX, slot.dY, col, alpha);
            draw_vertex_color(slot.aX, slot.aY, col, 0);
            draw_primitive_end();
            draw_text_color(slot.posX, slot.posY, slot.zIndex, col, col, col, col, alpha);
            break;
        case "point":
            var alpha = 1;
            var col = c_orange;
            var r = 10;
            var x1 = slot.posX;
            var y1 = slot.posY;
            var dir = slot.angle;
            var x2 = x1 + lengthdir_x(r, dir);
            var y2 = y1 + lengthdir_y(r, dir);
            draw_circle_colour(x1, y1, r, col, col, true);
            draw_circle_colour(x2, y2, r / 2, col, col, false);
            draw_text_color(slot.posX, slot.posY, slot.zIndex, col, col, col, col, alpha);
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