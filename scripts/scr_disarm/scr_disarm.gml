/* Disarm Spriter Runtime
 * ----------------------
 * Kat @katsaii
 * https://github.com/NuxiiGit/disarm
 */


//disarm_import
//disarm_import_ext
//disarm_import_custom

/// @desc Uses a set of events to request information that is used to build a Disarm instance.
///       The `events` struct must contain the fields `armature`, `atlas`, and `image`. Each of these
///       fields must store a function which will return the struct or the file path of where the data
///       is stored externally.
/// @param {struct} events A struct containing the events to call in order to load the armature, atlas, and image files.
function disarm_import_custom(_events) {
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
    return __disarm_import_armature(get_armature, get_atlas, get_image);
}

/// @desc Attempts to import a Spriter project as a Disarm instance by using a virtual file system.
/// @param {value} arm The string or struct containing armature data.
/// @param {struct} [atlas_map] A map from atlas names to atlas data.
/// @param {struct} [image_map] A map from image names to image data.
function disarm_import_ext(_arm, _atlas_map={ }, _image_map={ }) {
    return disarm_import_custom({
        armature : method({
            arm : _arm,
        }, function() {
            return arm;
        }),
        atlas : method({
            map : _atlas_map,
        }, function(_name) {
            return __disarm_struct_get_struct_or_string(map, _name);
        }),
        image : method({
            map : _image_map,
        }, function(_name) {
            var idx_spr = __disarm_struct_get_numeric_or_default(map, _name, -1);
            return sprite_exists(idx_spr) ? idx_spr : -1;
        }),
    });
}

/// @desc Attempts to import a Spriter project as a Disarm instance. If the atlas files are
///       included in the project, the `image_map` struct can be used to map from image
///       file names to their resource names.
/// @param {string} path The file path of the skeleton file.
/// @param {struct} [image_map] A map from image names to image data.
function disarm_import(_path, _image_map={ }) {
    var get_path = method({
        dirname : filename_dir(_path),
    }, function(_name) {
        return dirname + "/" + _name;
    });
    return disarm_import_custom({
        armature : method({
            path : _path,
        }, function() {
            return path;
        }),
        atlas : get_path,
        image : method({
            map : _image_map,
            getPath : get_path,
        }, function(_name) {
            var idx_spr = __disarm_struct_get_numeric_or_default(map, _name, -1);
            return sprite_exists(idx_spr) ? idx_spr : getPath(_name);
        }),
    });
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

// private stuff

function __disarm_import_armature(_get_armature, _get_atlas, _get_image) {
    var struct = _get_armature();
    __disarm_struct_assert_eq(struct, "generator", "BrashMonkey Spriter",
            "Disarm currently only supports animations exported by Spriter");
    __disarm_struct_assert_eq(struct, "scon_version", "1.0",
            "Disarm currently only supports version 1.0 of the Spriter format");
    var arm = {
        atlases : __disarm_array_map(
                __disarm_struct_get_array(struct, "atlas"),
                method({
                    get_atlas : _get_atlas,
                    get_image : _get_image,
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

/// @desc Reads the whole contents of a file and returns it as a string.
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