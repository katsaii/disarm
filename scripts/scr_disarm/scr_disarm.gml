/* Disarm Runtime
 * --------------
 * Kat @katsaii
 */

#macro DISARM_TYPE_SPRITE "sprite"
#macro DISARM_TYPE_BONE "bone"
#macro DISARM_TYPE_BOX "box"
#macro DISARM_TYPE_POINT "point"
#macro DISARM_TYPE_SOUND "sound"
#macro DISARM_TYPE_ENTITY "entity"
#macro DISARM_TYPE_VARIABLE "variable"
#macro DISARM_TYPE_UNKNOWN "unknown"

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
    return {
        width : __disarm_struct_get_or_default(_struct, "w", 1, is_numeric),
        height : __disarm_struct_get_or_default(_struct, "h", 1, is_numeric),
        name : __disarm_struct_get_or_default(_struct, "name", "", is_string),
        type : __disarm_struct_get_or_default(_struct, "type", DISARM_TYPE_UNKNOWN, is_string),
    };
}

/// @desc Creates a new Disarm entity animation definition.
/// @param {struct} struct A struct containing the Spriter project information.
function __disarm_import_entity_animation(_struct) {
    return {
        idx : __disarm_struct_get_or_default(_struct, "id", -1, is_numeric),
        name : __disarm_struct_get_or_default(_struct, "name", "", is_string),
        dt : __disarm_struct_get_or_default(_struct, "interval", -1, is_numeric),
        duration  : __disarm_struct_get_or_default(_struct, "length", -1, is_numeric),
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
        objs : [],
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
    var type = __disarm_struct_get_or_default(_struct, "object_type", DISARM_TYPE_UNKNOWN, is_string);
    var f = __disarm_import_entity_animation_timeline_keyframe;
    switch (type) {
    case DISARM_TYPE_SPRITE: break;
    case DISARM_TYPE_BONE: f = __disarm_import_entity_animation_timeline_keyframe_bone; break;
    case DISARM_TYPE_BOX: break;
    case DISARM_TYPE_POINT: break;
    case DISARM_TYPE_SOUND: break;
    case DISARM_TYPE_ENTITY: break;
    case DISARM_TYPE_VARIABLE: break;
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
    var bone = __disarm_struct_get_or_default(_struct, DISARM_TYPE_BONE, { }, is_struct);
    key.angle = __disarm_struct_get_or_default(bone, "angle", 0, is_numeric);
    key.scaleX = __disarm_struct_get_or_default(bone, "scale_x", 1, is_numeric);
    key.scaleY = __disarm_struct_get_or_default(bone, "scale_y", 1, is_numeric);
    key.posX = __disarm_struct_get_or_default(bone, "x", 0, is_numeric);
    key.posY = __disarm_struct_get_or_default(bone, "y", 0, is_numeric);
    return key;
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

var disarm = disarm_import_from_string(@'
{
	"entity": [
		{
			"animation": [
				{
					"id": 0,
					"interval": 100,
					"length": 1000,
					"mainline": {
						"key": [
							{
								"bone_ref": [
									{
										"id": 0,
										"key": 0,
										"timeline": 0
									},
									{
										"id": 1,
										"key": 0,
										"parent": 0,
										"timeline": 1
									}
								],
								"id": 0,
								"object_ref": []
							},
							{
								"bone_ref": [
									{
										"id": 0,
										"key": 1,
										"timeline": 0
									},
									{
										"id": 1,
										"key": 1,
										"parent": 0,
										"timeline": 1
									}
								],
								"id": 1,
								"object_ref": [],
								"time": 798
							}
						]
					},
					"name": "NewAnimation",
					"timeline": [
						{
							"id": 0,
							"key": [
								{
									"bone": {
										"angle": 22.833654177917538,
										"x": 1.647482014388494,
										"y": 0.1726618705035987
									},
									"id": 0
								},
								{
									"bone": {
										"angle": 73.83148691577918,
										"x": 1.647482014388494,
										"y": 0.1726618705035987
									},
									"id": 1,
									"spin": -1,
									"time": 798
								}
							],
							"name": "bone_000",
							"obj": 0,
							"object_type": "bone"
						},
						{
							"id": 1,
							"key": [
								{
									"bone": {
										"angle": 99.17172903016598,
										"scale_x": 0.9999999999999999,
										"x": 142.74948945393854,
										"y": 2.15525182766096
									},
									"id": 0,
									"spin": -1
								},
								{
									"bone": {
										"angle": 34.222081318590426,
										"scale_x": 0.9999999999999999,
										"x": 142.7494894539386,
										"y": 2.155251827660961
									},
									"id": 1,
									"time": 798
								}
							],
							"name": "bone_001",
							"obj": 1,
							"object_type": "bone"
						}
					]
				}
			],
			"character_map": [],
			"id": 0,
			"name": "entity_000",
			"obj_info": [
				{
					"h": 10,
					"name": "bone_000",
					"type": "bone",
					"w": 141.0319112825179
				},
				{
					"h": 10,
					"name": "bone_001",
					"type": "bone",
					"w": 128.95369892739242
				}
			]
		}
	],
	"folder": [],
	"generator": "BrashMonkey Spriter",
	"generator_version": "r11",
	"scon_version": "1.0"
}
');
show_message(disarm);