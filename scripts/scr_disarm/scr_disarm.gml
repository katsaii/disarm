/* Disarm Runtime
 * --------------
 * Kat @katsaii
 */

/// @desc Reads the contents of a file and returns its contents.
/// @param {string} filepath The path of the file to load.
function __disarm_read_whole_text_file_from_path(_path) {
    var src = "";
    if (file_exists(_path)) {
        var file = file_text_open_read(_path);
        while not (file_text_eof(file)) {
            src += file_text_readln(file);
        }
        file_text_close(file);
    }
    return src;
}

/// @desc Returns the global list of managed sprites.
function __disarm_get_static_sprite_manager() {
    static sprites = ds_list_create();
    return sprites;
}

/// @desc Packages the sprite information into a single structure.
/// @param {real} sprite The id of the sprite to package.
/// @param {real} [subimg] The id of the subimage to use.
function __disarm_make_sprite_information(_sprite, _subimg=0) {
    var idx_spr = sprite_exists(_sprite) &&
            _subimg >= 0 &&
            _subimg < sprite_get_number(_sprite) ? _sprite : -1;
    var sprite_data = {
        idx : idx_spr,
        img : _subimg,
        page : -1,
        uvLeft : 0,
        uvTop : 0,
        uvRight : 1,
        uvBottom : 1,
    };
    if (idx_spr != -1) {
        var width = sprite_get_width(_sprite);
        var height = sprite_get_height(_sprite);
        var uvs = sprite_get_uvs(_sprite, _subimg);
        var uv_left = uvs[0];
        var uv_top = uvs[1];
        var uv_right = uvs[2];
        var uv_bottom = uvs[3];
        var uv_x_offset = uvs[4]; // number of pixels trimmed from the left
        var uv_y_offset = uvs[5]; // number of pixels trimmed from the top
        var uv_x_ratio = uvs[6]; // ratio of discarded pixels horizontally
        var uv_y_ratio = uvs[7]; // ratio of discarded pixels vertically
        var uv_width = (uv_right - uv_left) / uv_x_ratio;
        var uv_height = (uv_bottom - uv_top) / uv_y_ratio;
        var uv_kw = uv_width / width;
        var uv_kh = uv_height / height;
        sprite_data.page = sprite_get_info(_sprite).frames[_subimg].texture;
        sprite_data.uvLeft = uv_left - uv_x_offset * uv_kw;
        sprite_data.uvTop = uv_top - uv_y_offset * uv_kh;
        sprite_data.uvRight = sprite_data.uvLeft + uv_width;
        sprite_data.uvBottom = sprite_data.uvTop + uv_height;
    }
    return sprite_data;
}

/// @desc Registers a sprite to be managed.
/// @param {real} sprite The id of the sprite to register.
function __disarm_make_sprite_information_managed(_sprite) {
    var sprites = __disarm_get_static_sprite_manager();
    var sprite_data = __disarm_make_sprite_information(_sprite);
    var sprite_ref = weak_ref_create(sprite_data);
    sprite_ref.idx = _sprite;
    ds_list_add(sprites, sprite_ref);
    return sprite_data;
}

/// @desc Collects any dynamically allocated sprites that are no longer referenced.
function disarm_flush() {
    var sprites = __disarm_get_static_sprite_manager();
    for (var i = ds_list_size(sprites) - 1; i >= 0; i -= 1) {
        var sprite_ref = sprites[| i];
        if not (weak_ref_alive(sprite_ref)) {
            ds_list_delete(sprites, i);
            sprite_delete(sprite_ref.idx);
        }
    }
}

/// @desc Creates a set of events for loading Spriter armatures from strings and sprites.
/// @param {struct} arm The struct containing armature data.
/// @param {struct} [atlas_map] A map from atlas names to atlas data.
/// @param {struct} [image_map] A map from image names to image data.
function disarm_importer_raw(_arm, _atlas_map={ }, _image_map={ }) {
    return {
        armature : method({
            arm : _arm,
        }, function() {
            return arm;
        }),
        atlas : method({
            map : _atlas_map,
        }, function(_name) {
            return __disarm_struct_get_struct(map, _name);
        }),
        image : method({
            map : _image_map,
        }, function(_name) {
            var idx_spr = __disarm_struct_get_numeric_or_default(map, _name, -1);
            return sprite_exists(idx_spr) ? idx_spr : -1;
        }),
    };
}

/// @desc Creates a set of events for loading Spriter armatures from the physical file system.
/// @param {string} path The file path of the skeleton file.
/// @param {struct} [image_map] A map from image names to image data.
function disarm_importer_file(_path, _image_map={ }) {
    var get_path = method({
        dirname : filename_dir(_path),
    }, function(_name) {
        return dirname + "/" + _name;
    });
    return {
        armature : method({
            path : _path,
        }, function() {
            return path;
        }),
        atlas : get_path,
        image : method({
            map : _image_map,
            get_path : get_path,
        }, function(_name) {
            var idx_spr = __disarm_struct_get_numeric_or_default(map, _name, -1);
            return sprite_exists(idx_spr) ? idx_spr : get_path(_name);
        }),
    };
}

/// @desc Reads the contents of a file and attempts to build a new Disarm instance from the contents.
/// @param {value} path_or_events_struct A struct containing the fields `armature`, `atlas` and `image`, representing events the disarm importer will call.
function disarm_import(_events) {
    if (is_string(_events)) {
        _events = disarm_importer_file(_events);
    }
    static aux_text = function(_x) {
        if (is_string(_x)) {
            return json_parse(file_exists(_x) ? __disarm_read_whole_text_file_from_path(_x) : _x);
        } else if (is_struct(_x)) {
            return _x;
        } else {
            return { };
        }
    };
    static aux_image = function(_x) {
        if (is_string(_x)) {
            if (asset_get_type(_x) == asset_sprite) {
                return __disarm_make_sprite_information(_x);
            } else if (file_exists(_x)) {
                var new_spr = sprite_add(_x, 1, false, false, 0, 0);
                return __disarm_make_sprite_information_managed(new_spr);
            }
        } else if (is_numeric(_x) && sprite_exists(_x)) {
            return __disarm_make_sprite_information(_x);
        }
        return __disarm_make_sprite_information(-1);
    };
    static aux_nothing = function() { return { }; };
    var get_armature = __disarm_compose_methods(aux_text,
            __disarm_struct_get_method_or_default(_events, "armature", aux_nothing));
    var get_atlas = __disarm_compose_methods(aux_text,
            __disarm_struct_get_method_or_default(_events, "atlas", aux_nothing));
    var get_image = __disarm_compose_methods(aux_image,
            __disarm_struct_get_method_or_default(_events, "image", aux_nothing));
    var struct = get_armature();
    __disarm_struct_assert_eq(struct, "generator", "BrashMonkey Spriter",
            "Disarm currently only supports animations exported by Spriter");
    __disarm_struct_assert_eq(struct, "scon_version", "1.0",
            "Disarm currently only supports version 1.0 of the Spriter format");
    var arm = {
        atlases : __disarm_array_map(
                __disarm_struct_get_array(struct, "atlas"),
                method({
                    get_atlas : get_atlas,
                    get_image : get_image,
                }, __disarm_import_atlas)),
        atlasTable : { },
        folders : __disarm_array_map(
                __disarm_struct_get_array(struct, "folder"),
                __disarm_import_folder),
        entities : __disarm_array_map(
                __disarm_struct_get_array(struct, "entity"),
                __disarm_import_entity),
        entityTable : { },
        currentEntity : 0,
    };
    var entities = arm.entities;
    var entity_table = arm.entityTable;
    for (var i = array_length(entities) - 1; i >= 0; i -= 1) {
        entity_table[$ entities[i].name] = i;
    }
    var atlases = arm.atlases;
    var atlas_table = arm.atlasTable;
    for (var i = array_length(atlases) - 1; i >= 0; i -= 1) {
        atlas_table[$ atlases[i].name] = i;
    }
    return arm;
}

/// @desc Creates a new Disarm atlas instance.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_atlas(_struct) {
    var name = __disarm_struct_get_string_or_default(_struct, "name");
    var atlas = get_atlas(name);
    var meta = __disarm_struct_get_struct(atlas, "meta");
    __disarm_struct_assert_eq(meta, "app", "Spriter", "unrecognised texture atlas format");
    __disarm_struct_assert_eq(meta, "format", "RGBA8888", "unsupported texture atlas colour format");
    __disarm_struct_assert_eq(meta, "version", "r11", "unsupported texture atlas version");
    var scale = __disarm_struct_get_numeric_or_default(meta, "scale", 1);
    var size = __disarm_struct_get_struct(meta, "size");
    var width = __disarm_struct_get_numeric_or_default(size, "w", 1);
    var height = __disarm_struct_get_numeric_or_default(size, "h", 1);
    var frames = __disarm_struct_get_struct(atlas, "frames");
    var frame_names = variable_struct_get_names(frames);
    var frame_table = { };
    for (var i = array_length(frame_names) - 1; i >= 0; i -= 1) {
        var frame_name = frame_names[i];
        var frame_data = frames[$ frame_name];
        var rotate = __disarm_struct_get_bool_or_default(frame_data, "rotated");
        var frame_size = __disarm_struct_get_struct(frame_data, "frame");
        var tex_x = __disarm_struct_get_numeric_or_default(frame_size, "x");
        var tex_y = __disarm_struct_get_numeric_or_default(frame_size, "y");
        var tex_width = __disarm_struct_get_numeric_or_default(frame_size, "w");
        var tex_height = __disarm_struct_get_numeric_or_default(frame_size, "h");
        var tex_dx = rotate ? tex_height : tex_width;
        var tex_dy = rotate ? tex_width : tex_height;
        var uv_left = tex_x / width;
        var uv_top = tex_y / height;
        var uv_right = (tex_x + tex_dx) / width;
        var uv_bottom = (tex_y + tex_dy) / height;
        var a_u, a_v, b_u, b_v, c_u, c_v, d_u, d_v;
        if (rotate) {
            a_u = uv_right;
            a_v = uv_top;
            b_u = uv_right;
            b_v = uv_bottom;
            c_u = uv_left;
            c_v = uv_bottom;
            d_u = uv_left;
            d_v = uv_top;
        } else {
            a_u = uv_left;
            a_v = uv_top;
            b_u = uv_right;
            b_v = uv_top;
            c_u = uv_right;
            c_v = uv_bottom;
            d_u = uv_left;
            d_v = uv_bottom;
        }
        frame_table[$ frame_name] = {
            aU : a_u, bU : b_u, cU : c_u, dU : d_u,
            aV : a_v, bV : b_v, cV : c_v, dV : d_v,
        };
    }
    return {
        name : name,
        image : get_image(__disarm_struct_get_string_or_default(meta, "image")),
        frameTable : frame_table,
        width : width,
        height : height,
    };
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
                        width : __disarm_struct_get_numeric_or_default(_struct, "width", 1),
                        height : __disarm_struct_get_numeric_or_default(_struct, "height", 1),
                        pivotX : __disarm_struct_get_numeric_or_default(_struct, "pivot_x"),
                        pivotY : __disarm_struct_get_numeric_or_default(_struct, "pivot_y", 1),
                        //atlasRotated : __disarm_struct_get_bool_or_default(_struct, "arot"),
                        atlasWidth : __disarm_struct_get_numeric_or_default(_struct, "aw", 1),
                        atlasHeight : __disarm_struct_get_numeric_or_default(_struct, "ah", 1),
                        //atlasX : __disarm_struct_get_numeric_or_default(_struct, "ax"),
                        //atlasY : __disarm_struct_get_numeric_or_default(_struct, "ay"),
                        atlasXOff : __disarm_struct_get_numeric_or_default(_struct, "axoff"),
                        atlasYOff : __disarm_struct_get_numeric_or_default(_struct, "ayoff"),
                    };
                    
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
        slotCount : 0,
        slotTable : { },
        anims : __disarm_array_map(
                __disarm_struct_get_array(_struct, "animation"),
                __disarm_import_entity_animation),
        animTable : { },
        animStep : 0,
        skins : __disarm_array_map(
                __disarm_struct_get_array(_struct, "character_map"),
                __disarm_import_entity_character_map),
        skinTable : { },
        activeSkin : { },
    };
    var anims = entity.anims;
    var anim_table = entity.animTable;
    for (var i = array_length(anims) - 1; i >= 0; i -= 1) {
        anim_table[$ anims[i].name] = i;
    }
    var skins = entity.skins;
    var skin_table = entity.skinTable;
    for (var i = array_length(skins) - 1; i >= 0; i -= 1) {
        skin_table[$ skins[i].name] = i;
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
        posX : 0,
        posY : 0,
        angle : 0,
        scaleX : 1,
        scaleY : 1,
        alpha : 1,
        boneParent : -1,
        invalidWorldTransform : true,
    };
}

/// @desc Creates a new Disarm entity animation definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation(_struct) {
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
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
    key.useDefaultPivot = !variable_struct_exists(slot, "pivot_x") && !variable_struct_exists(slot, "pivot_y");
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

/// @desc Creates a new Disarm entity character map definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_character_map(_struct) {
    return {
        name : __disarm_struct_get_string_or_default(_struct, "name"),
        maps : __disarm_array_map(
                __disarm_struct_get_array(_struct, "map"),
                function(_struct) {
                    return {
                        sourceFile : __disarm_struct_get_numeric_or_default(_struct, "file", -1),
                        sourceFolder : __disarm_struct_get_numeric_or_default(_struct, "folder", -1),
                        destFile : __disarm_struct_get_numeric_or_default(_struct, "target_file", -1),
                        destFolder : __disarm_struct_get_numeric_or_default(_struct, "target_folder", -1),
                    };
                }),
    };
}

/// @desc Returns whether an entity exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} entity The name of the entity to check.
function disarm_entity_exists(_arm, _entity) {
    var pos = __disarm_get_index_id_or_name(_arm.entityTable, _entity);
    return __disarm_check_index_in_array(_arm.entities, pos);
}

/// @desc Adds an animation to the armature pose.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} entity The name of the entity to set.
function disarm_entity_set(_arm, _entity) {
    _arm.currentEntity = __disarm_get_index_id_or_name(_arm.entityTable, _entity);
}

/// @desc Clears the current character map state.
/// @param {struct} arm The Disarm instance to update.
function disarm_skin_clear(_arm) {
    var entity = _arm.entities[_arm.currentEntity];
    entity.activeSkin = { };
}

/// @desc Returns whether a character map exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} skin The name of the skin to check.
function disarm_skin_exists(_arm, _skin) {
    var entity = _arm.entities[_arm.currentEntity];
    var pos = __disarm_get_index_id_or_name(entity.skinTable, _skin);
    return __disarm_check_index_in_array(entity.skins, pos);
}

/// @desc Adds a new character map, or array of character maps, or the current active skin.
/// @param {struct} arm The Disarm instance to update.
/// @param {value} skin The name, or array of names, of character maps to add.
function disarm_skin_add(_arm, _skin_names) {
    var entity = _arm.entities[_arm.currentEntity];
    var skin = entity.activeSkin;
    if not (is_array(_skin_names)) {
        _skin_names = [_skin_names];
    }
    var count = array_length(_skin_names);
    for (var i = 0; i < count; i += 1) {
        var skin_name = _skin_names[i];
        var pos = __disarm_get_index_id_or_name(entity.skinTable, skin_name);
        var maps = entity.skins[pos].maps;
        for (var j = array_length(maps) - 1; j >= 0; j -= 1) {
            var map = maps[j];
            var folder = string(map.sourceFolder);
            if not (variable_struct_exists(skin, folder)) {
                skin[$ folder] = { };
            }
            skin[$ folder][$ string(map.sourceFile)] = [map.destFolder, map.destFile];
        }
    }
}

/// @desc Returns whether a slot exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} slot The name of the slot to check.
function disarm_slot_exists(_arm, _slot) {
    var entity = _arm.entities[_arm.currentEntity];
    return variable_struct_exists(entity.slotTable, _slot);
}

/// @desc Returns a reference to the slot data with this name. Note: any changes made to this
///       struct will affect the representation of the slot in the armature.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} slot The name of the slot to check.
function disarm_slot_get_data(_arm, _slot) {
    var entity = _arm.entities[_arm.currentEntity];
    return entity.slotTable[$ _slot];
}

/// @desc Returns whether an animation exists with this name.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} anim The name of the animation to check.
function disarm_animation_exists(_arm, _anim) {
    var entity = _arm.entities[_arm.currentEntity];
    var pos = __disarm_get_index_id_or_name(entity.animTable, _anim);
    return __disarm_check_index_in_array(entity.anims, pos);
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
/// @param {real} anim_step The animation step variable to check a slot for.
/// @param {struct} entity The entity to update.
function __disarm_animation_get_slot_by_name_or_spawn_new(_name, _type, _slot_table, _slots, _anim_step, _entity) {
    var slot_data = _slot_table[$ _name];
    if (slot_data != undefined) {
        if (slot_data[0] == _anim_step) {
            return slot_data[1];
        }
    } else {
        slot_data = array_create(2); // slot_data[0] holds the anim_step, slot_data[1] holds the actual slot
        _slot_table[$ _name] = slot_data;
        slot_data[@ 1] = {
            folder : -1,
            file : -1,
            posX : 0,
            posY : 0,
            angle : 0,
            scaleX : 1,
            scaleY : 1,
            useDefaultPivot : true,
            pivotX : 0,
            pivotY : 1,
            alpha : 1,
            aX : 0, bX : 0, cX : 0, dX : 0,
            aY : 0, bY : 0, cY : 0, dY : 0,
            idxAtlas : -1,
            frameName : "",
            name : _name,
            type : _type,
            boneParent : -1,
            zIndex : 0,
        };
    }
    slot_data[@ 0] = _anim_step;
    var slot = slot_data[1];
    var i = _entity.slotCount;
    _entity.slotCount += 1;
    if (i < array_length(_slots)) {
        _slots[@ i] = slot;
    } else {
        array_push(_slots, slot);
    }
    return slot;
}

/// @desc Resets the state of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_begin(_arm) {
    var entity = _arm.entities[_arm.currentEntity];
    entity.slotCount = 0;
    entity.animStep += 1;
    var info = entity.info;
    for (var i = array_length(info) - 1; i >= 0; i -= 1) {
        var slot = info[i];
        slot.active = false;
        switch (slot.type) {
        case "bone":
            slot.invalidWorldTransform = true;
            slot.posX = 0;
            slot.posY = 0;
            slot.angle = 0;
            slot.scaleX = 1;
            slot.scaleY = 1;
            slot.alpha = 1;
            slot.boneParent = -1;
            break;
        }
    }
}

/// @desc Adds an animation to the armature pose.
/// @param {struct} arm The Disarm instance to update.
/// @param {real} anim The name of the animation to play.
/// @param {real} progress The progress, as a number between 0 and 1, of the animation.
/// @param {real} [blend_amount] The intensity of the animation.
function disarm_animation_add(_arm, _anim, _progress, _amount=undefined) {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slots;
    var slot_table = entity.slotTable;
    var anim_step = entity.animStep;
    var anim = entity.anims[__disarm_get_index_id_or_name(entity.animTable, _anim)];
    var mainline = anim.mainline;
    var timelines = anim.timelines;
    var looping = anim.looping;
    var time_progress = clamp(_progress, 0, 1);
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
            alpha = lerp(alpha, key_next.alpha, interp);
        }
        var bone = info[timeline.slot];
        // blend between current and new animation
        if (_amount != undefined) {
            pos_x = lerp(bone.posX, pos_x, _amount);
            pos_y = lerp(bone.posY, pos_y, _amount);
            angle = __disarm_animation_lerp_angle(bone.angle, angle, 1, _amount);
            scale_x = lerp(bone.scaleX, scale_x, _amount);
            scale_y = lerp(bone.scaleY, scale_y, _amount);
            alpha = lerp(bone.alpha, alpha, _amount);
        }
        // apply transformations
        bone.active = true; // enables the bone visibility
        bone.posX = pos_x;
        bone.posY = pos_y;
        bone.angle = angle;
        bone.scaleX = scale_x;
        bone.scaleY = scale_y;
        bone.alpha = alpha;
        var idx_bone_ref_parent = bone_ref.boneParent;
        if (idx_bone_ref_parent == -1) {
            bone.boneParent = -1;
        } else {
            var bone_ref_parent = bone_refs[idx_bone_ref_parent];
            bone.boneParent = timelines[bone_ref_parent.timeline].slot;
        }
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
        var slot = __disarm_animation_get_slot_by_name_or_spawn_new(timeline.name, type, slot_table, slots, anim_step, entity);
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
            var pivot_use_default = key.useDefaultPivot;
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
                if not (pivot_use_default) {
                    pivot_x = lerp(pivot_x, key_next.pivotX, interp);
                    pivot_y = lerp(pivot_y, key_next.pivotY, interp);
                }
                alpha = lerp(alpha, key_next.alpha, interp);
            }
            // blend between current and new animation
            if (_amount != undefined) {
                pos_x = lerp(slot.posX, pos_x, _amount);
                pos_y = lerp(slot.posY, pos_y, _amount);
                angle = __disarm_animation_lerp_angle(slot.angle, angle, 1, _amount);
                scale_x = lerp(slot.scaleX, scale_x, _amount);
                scale_y = lerp(slot.scaleY, scale_y, _amount);
                if not (pivot_use_default) {
                    pivot_x = lerp(slot.pivotX, pivot_x, _amount);
                    pivot_y = lerp(slot.pivotY, pivot_y, _amount);
                }
                alpha = lerp(slot.alpha, alpha, _amount);
            }
            // apply transformations
            slot.folder = folder;
            slot.file = file;
            slot.posX = pos_x;
            slot.posY = pos_y;
            slot.angle = angle;
            slot.scaleX = scale_x;
            slot.scaleY = scale_y;
            slot.useDefaultPivot = pivot_use_default;
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
                alpha = lerp(alpha, key_next.alpha, interp);
            }
            // blend between current and new animation
            if (_amount != undefined) {
                pos_x = lerp(slot.posX, pos_x, _amount);
                pos_y = lerp(slot.posY, pos_y, _amount);
                angle = __disarm_animation_lerp_angle(slot.angle, angle, 1, _amount);
                scale_x = lerp(slot.scaleX, scale_x, _amount);
                scale_y = lerp(slot.scaleY, scale_y, _amount);
                alpha = lerp(slot.alpha, alpha, _amount);
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
        slot.zIndex = slot_ref.zIndex;
        var idx_slot_ref_parent = slot_ref.boneParent;
        if (idx_slot_ref_parent == -1) {
            slot.boneParent = -1;
        } else {
            var bone_ref_parent = bone_refs[idx_slot_ref_parent];
            slot.boneParent = timelines[bone_ref_parent.timeline].slot;
        }
    }
}

/// @desc Updates the world transformation of armature objects.
/// @param {struct} arm The Disarm instance to update.
function disarm_animation_end(_arm) {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slots;
    var skin = entity.activeSkin;
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
            var folder_map = skin[$ string(idx_folder)];
            if (folder_map != undefined) {
                var file_map = folder_map[$ string(idx_file)];
                if (file_map != undefined) {
                    idx_folder = file_map[0];
                    idx_file = file_map[1];
                }
            }
            if (idx_folder == -1 || idx_file == -1) {
                continue;
            }
            __disarm_update_world_transform(slot, bone_parent);
            var folder = folders[idx_folder];
            var file = folder.files[idx_file];
            var pivot_x, pivot_y;
            if (slot.useDefaultPivot) {
                pivot_x = file.pivotX;
                pivot_y = file.pivotY;
            } else {
                pivot_x = slot.pivotX;
                pivot_y = slot.pivotY;
            }
            pivot_y = 1 - pivot_y; // why would you do this to me
            var source_left = -pivot_x * file.width;
            var source_top = -pivot_y * file.height;
            var source_right = source_left + file.width;
            var source_bottom = source_top + file.height;
            var left = source_left + file.atlasXOff;
            var top = source_top + file.atlasYOff;
            var right = left + file.atlasWidth;
            var bottom = top + file.atlasHeight;
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
            slot.idxAtlas = folder.atlas;
            slot.frameName = file.name;
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
function __disarm_update_world_transform_using_object_array(_info, _idx) {
    var slot = _info[_idx];
    switch (slot.type) {
    case "bone":
        if (slot.invalidWorldTransform && slot.active) {
            slot.invalidWorldTransform = false;
            switch (slot.type) {
            case "bone":
                var idx_parent = slot.boneParent;
                var bone_parent = idx_parent == -1 ? undefined :
                        __disarm_update_world_transform_using_object_array(_info, idx_parent);
                __disarm_update_world_transform(slot, bone_parent);
                break;
            }
        }
        break;
    }
    return slot;
}

/// @desc Updates the world transformation of a specific armature object using this array of objects.
/// @param {struct} child The object to update.
/// @param {struct} parent The parent to use.
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
    var dir = _child.angle;
    if (par_scale_x < 0) {
        // flip direction through y-axis
        dir = 180 - dir;
    }
    if (par_scale_y < 0) {
        // flip direction through x-axis
        dir = -dir;
    }
    _child.angle = par_dir + dir;
    _child.scaleX *= par_scale_x;
    _child.scaleY *= par_scale_y;
    _child.alpha *= par_alpha;
    var fk_x = _child.posX * par_scale_x;
    var fk_y = _child.posY * par_scale_y;
    var fk_angle = par_dir;
    _child.posX = par_x + lengthdir_x(fk_x, fk_angle) + lengthdir_x(fk_y, fk_angle - 90);
    _child.posY = par_y + lengthdir_y(fk_x, fk_angle) + lengthdir_y(fk_y, fk_angle - 90);
}

/// @desc Renders a debug view of the armature.
/// @param {struct} arm The Disarm instance to render.
/// @param {real} [x] The X offset to render the armature at.
/// @param {real} [y] The Y offset to render the armature at.
/// @param {real} [xscale] The X scale to render the armature at.
/// @param {real} [yscale] The Y scale to render the armature at.
function disarm_draw_debug(_arm, _offset_x=0, _offset_y=0, _scale_x=1, _scale_y=1) {
    var entity = _arm.entities[_arm.currentEntity];
    var info = entity.info;
    var slots = entity.slotsDrawOrder;
    var default_colour = draw_get_color();
    var default_alpha = draw_get_alpha();
    var default_matrix = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_multiply(default_matrix,
            matrix_build(_offset_x, _offset_y, 0, 0, 0, 0, _scale_x, _scale_y, 1)));
    draw_set_alpha(1);
    for (var i = array_length(info) - 1; i >= 0; i -= 1) {
        var slot = info[i];
        if not (slot.active) {
            continue;
        }
        switch (slot.type) {
        case "bone":
            var len = slot.width * slot.scaleX;
            var wid = 1;//abs(slot.height * slot.scaleY);
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
            draw_set_colour(col);
            draw_arrow(slot.aX, slot.aY, slot.bX, slot.bY, abs(1 * slot.scaleY));
            draw_primitive_begin(pr_linestrip);
            draw_vertex_color(slot.bX, slot.bY, col, alpha);
            draw_vertex_color(slot.cX, slot.cY, col, alpha);
            draw_vertex_color(slot.dX, slot.dY, col, alpha);
            draw_vertex_color(slot.aX, slot.aY, col, alpha);
            draw_vertex_color(slot.posX, slot.posY, col, alpha);
            draw_primitive_end();
            //draw_text_color(slot.posX, slot.posY, slot.zIndex, col, col, col, col, alpha);
            break;
        case "point":
            var alpha = 1;
            var col = c_orange;
            var r = 1;
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
    draw_set_colour(default_colour);
    draw_set_alpha(default_alpha);
    matrix_set(matrix_world, default_matrix);
}

/// @desc Renders a debug view of the armature atlas.
/// @param {struct} arm The Disarm instance to render.
/// @param {name} name The name of the atlas the draw.
/// @param {real} x The x position to render the atlas debug window.
/// @param {real} y The y position to render the atlas debug window.
/// @param {real} [width] The width of the debug window.
/// @param {real} [height] The height of the debug window.
function disarm_draw_debug_atlas(_arm, _name, _x, _y, _width=undefined, _height=undefined) {
    var atlas = _arm.atlases[_arm.atlasTable[$ _name]];
    var width = _width == undefined ? atlas.width : _width;
    var height = _height == undefined ? atlas.height : _height;
    var sprite_data = atlas.image;
    var frame_table = atlas.frameTable;
    var frame_names = variable_struct_get_names(frame_table);
    var default_colour = draw_get_color();
    var default_alpha = draw_get_alpha();
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_primitive_begin_texture(pr_trianglestrip, sprite_data.page);
    var uv_left = sprite_data.uvLeft;
    var uv_top = sprite_data.uvTop;
    var uv_right = sprite_data.uvRight;
    var uv_bottom = sprite_data.uvBottom;
    draw_vertex_texture(_x, _y + height, uv_left, uv_bottom);
    draw_vertex_texture(_x + width, _y + height, uv_right, uv_bottom);
    draw_vertex_texture(_x, _y, uv_left, uv_top);
    draw_vertex_texture(_x + width, _y, uv_right, uv_top);
    draw_primitive_end();
    for (var i = array_length(frame_names) - 1; i >= 0; i -= 1) {
        var frame_name = frame_names[i];
        var frame = frame_table[$ frame_name];
        var a_x = _x + lerp(0, width, frame.aU);
        var a_y = _y + lerp(0, height, frame.aV);
        var b_x = _x + lerp(0, width, frame.bU);
        var b_y = _y + lerp(0, height, frame.bV);
        var c_x = _x + lerp(0, width, frame.cU);
        var c_y = _y + lerp(0, height, frame.cV);
        var d_x = _x + lerp(0, width, frame.dU);
        var d_y = _y + lerp(0, height, frame.dV);
        var colour = c_red;
        var alpha = 1;
        draw_primitive_begin(pr_linestrip);
        draw_vertex_color(a_x, a_y, colour, alpha);
        draw_vertex_color(b_x, b_y, colour, alpha);
        draw_vertex_color(c_x, c_y, colour, alpha);
        draw_vertex_color(d_x, d_y, colour, alpha);
        draw_vertex_color(a_x, a_y, colour, alpha);
        draw_primitive_end();
        draw_text_color(a_x, a_y, frame_name, colour, colour, colour, colour, alpha);
    }
    draw_set_colour(default_colour);
    draw_set_alpha(default_alpha);
}

/// @desc Returns the preferred vertex format.
function __disarm_get_full_fat_vertex_format() {
    static format = (function() {
        vertex_format_begin();
        vertex_format_add_position();
        vertex_format_add_colour();
        vertex_format_add_texcoord();
        return vertex_format_end();
    })();
    return format;
}

/// @desc Creates a new Disarm mesh.
function disarm_mesh_create() {
    return {
        partialBatch : false,
        batches : [],
        batchCount : 0,
        batchCapacity : 0,
        currentPage : undefined,
    };
}

/// @desc Destroys this Disarm mesh.
/// @param {struct} mesh The mesh to destroy.
function disarm_mesh_destroy(_mesh) {
    __disarm_mesh_batch_end(_mesh);
    var batches = _mesh.batches;
    for (var i = _mesh.batchCapacity - 1; i >= 0; i -= 1) {
        var batch = batches[i];
        vertex_delete_buffer(batch.vbuff);
    }
}

/// @desc Resets the draw options for this mesh.
/// @param {struct} mesh The mesh to begin drawing.
function disarm_mesh_begin(_mesh) {
    _mesh.partialBatch = false;
    _mesh.batchCount = 0;
    _mesh.currentPage = undefined;
}

/// @desc Finalises the drawing of this mesh.
/// @param {struct} mesh The mesh to finalise drawing.
function disarm_mesh_end(_mesh) {
    __disarm_mesh_batch_end(_mesh);
}

/// @desc Adds the current world transform of an armature to this mesh.
/// @param {struct} mesh The mesh to add vertices to.
/// @param {struct} arm The armature to get vertices from.
/// @param {real} [x] The X offset to render the armature at.
/// @param {real} [y] The Y offset to render the armature at.
/// @param {real} [xscale] The X scale to render the armature at.
/// @param {real} [yscale] The Y scale to render the armature at.
function disarm_mesh_add_armature(_mesh, _arm, _offset_x=0, _offset_y=0, _scale_x=1, _scale_y=1) {
    var entity = _arm.entities[_arm.currentEntity];
    var atlases = _arm.atlases;
    var slots = entity.slotsDrawOrder;
    var slot_count = array_length(slots);
    var page = _mesh.currentPage;
    var batches = _mesh.batches;
    for (var i = 0; i < slot_count; i += 1) {
        var slot = slots[i];
        switch (slot.type) {
        case "sprite":
            var idx_atlas = slot.idxAtlas;
            var frame_name = slot.frameName,
            if (idx_atlas == -1) {
                break;
            }
            var atlas = atlases[idx_atlas];
            var sprite_data = atlas.image;
            var frame = atlas.frameTable[$ frame_name];
            var new_page = sprite_data.page;
            var uv_left = sprite_data.uvLeft;
            var uv_top = sprite_data.uvTop;
            var uv_right = sprite_data.uvRight;
            var uv_bottom = sprite_data.uvBottom;
            if (page == undefined) {
                __disarm_mesh_batch_begin(_mesh, new_page);
                page = new_page;
            } else if (new_page != page) {
                __disarm_mesh_batch_end(_mesh);
                __disarm_mesh_batch_begin(_mesh, new_page);
                page = new_page;
            }
            var vbuff = batches[_mesh.batchCount].vbuff;
            var colour = c_white;
            var alpha = slot.alpha;
            var a_x = _offset_x + _scale_x * slot.aX;
            var a_y = _offset_y + _scale_y * slot.aY;
            var b_x = _offset_x + _scale_x * slot.bX;
            var b_y = _offset_y + _scale_y * slot.bY;
            var c_x = _offset_x + _scale_x * slot.cX;
            var c_y = _offset_y + _scale_y * slot.cY;
            var d_x = _offset_x + _scale_x * slot.dX;
            var d_y = _offset_y + _scale_y * slot.dY;
            var a_u = lerp(uv_left, uv_right, frame.aU);
            var a_v = lerp(uv_top, uv_bottom, frame.aV);
            var b_u = lerp(uv_left, uv_right, frame.bU);
            var b_v = lerp(uv_top, uv_bottom, frame.bV);
            var c_u = lerp(uv_left, uv_right, frame.cU);
            var c_v = lerp(uv_top, uv_bottom, frame.cV);
            var d_u = lerp(uv_left, uv_right, frame.dU);
            var d_v = lerp(uv_top, uv_bottom, frame.dV);
            vertex_position(vbuff, a_x, a_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, a_u, a_v);
            vertex_position(vbuff, b_x, b_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, b_u, b_v);
            vertex_position(vbuff, d_x, d_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, d_u, d_v);
            vertex_position(vbuff, d_x, d_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, d_u, d_v);
            vertex_position(vbuff, b_x, b_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, b_u, b_v);
            vertex_position(vbuff, c_x, c_y);
            vertex_colour(vbuff, colour, alpha);
            vertex_texcoord(vbuff, c_u, c_v);
            break;
        }
    }
    _mesh.currentPage = page;
}

/// @desc Submits this mesh to the draw pipeline.
/// @param {struct} mesh The mesh to submit.
function disarm_mesh_submit(_mesh) {
    var batches = _mesh.batches;
    var count = _mesh.batchCount;
    for (var i = 0; i < count; i += 1) {
        var batch = batches[i];
        vertex_submit(batch.vbuff, pr_trianglelist, batch.page);
    }
}

/// @desc Starts a new mesh batch
/// @param {struct} mesh The mesh to add a new batch to.
function __disarm_mesh_batch_end(_mesh) {
    if (_mesh.partialBatch) {
        vertex_end(_mesh.batches[_mesh.batchCount].vbuff);
        _mesh.partialBatch = false;
        _mesh.batchCount += 1;
    }
}

/// @desc Starts a new mesh batch
/// @param {struct} mesh The mesh to add a new batch to.
/// @param {pointer} texture The pointer to the texture to use.
function __disarm_mesh_batch_begin(_mesh, _texture) {
    _mesh.partialBatch = true;
    var i = _mesh.batchCount;
    if (i >= _mesh.batchCapacity) {
        array_push(_mesh.batches, {
            vbuff : vertex_create_buffer(),
            page : _texture,
        });
        _mesh.batchCapacity += 1;
    }
    vertex_begin(_mesh.batches[i].vbuff, __disarm_get_full_fat_vertex_format());
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

/// @desc Attempts to get a string value from a struct, and returns a default value
///       if it doesn't exist.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {array} expected The expected value.
/// @param {string} on_error The message to warn if the value isn't expected.
function __disarm_struct_assert_eq(_struct, _key, _expected, _on_error) {
    if not (is_array(_expected)) {
        _expected = [_expected];
    }
    var current = __disarm_struct_get_string_or_default(_struct, _key);
    for (var i = array_length(_expected) - 1; i >= 0; i -= 1) {
        var expected = _expected[i];
        if (current == expected) {
            return true;
        }
    }
    show_debug_message("DISARM WARNING: " + _on_error + ", got `" + string(current) + "` (the animation will be loaded but may be unstable)");
    return false;
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

/// @desc Attempts to get a Boolean value from a struct, and returns a default value
///       if it doesn't exist.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {value} [default] The default value.
function __disarm_struct_get_bool_or_default(_struct, _key, _default=false) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        if (is_string(value)) {
            switch (value) {
            case "true":
                return true;
            case "false":
                return false;
            }
        }
        if (is_numeric(value)) {
            return bool(value);
        } else {
            try {
                var b = bool(value);
                return b;
            } catch (_) { }
        }
    }
    return _default;
}

/// @desc Attempts to get a method value from a struct.
/// @param {struct} struct The struct to check.
/// @param {string} key The key to check.
/// @param {value} [default] The default value.
/// @param {real} [ignore_self] Whether to unbind methods bound to `struct`.
function __disarm_struct_get_method_or_default(_struct, _key, _default=undefined, _ignore_self=true) {
    if (variable_struct_exists(_struct, _key)) {
        var value = _struct[$ _key];
        if (is_method(value)) {
            return _ignore_self && method_get_self(value) == _struct ? method_get_index(value) : value;
        } else if (is_numeric(value) && script_exists(value)) {
            return value;
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

/// @desc Returns the index of a value by name if it is a string.
/// @param {struct} names The struct to check.
/// @param {value} name_or_index The name to search for.
function __disarm_get_index_id_or_name(_names, _idx) {
    return is_numeric(_idx) ? _idx : _names[$ string(_idx)];
}

/// @desc Returns whether an index is in the bounds of an array.
/// @param {array} arr The array to check.
/// @param {value} pos The position to check.
function __disarm_check_index_in_array(_arr, _pos) {
    return is_numeric(_pos) && _pos >= 0 && _pos < array_length(_arr);
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

/// @desc Composes two functions together.
/// @param {real} f The outer function.
/// @param {real} g The inner function.
function __disarm_compose_methods(_f, _g) {
    return method({
        f : _f,
        g : _g,
    }, function(_x) {
        return f(g(_x));
    });
}