/* Disarm Runtime
 * --------------
 * Kat @katsaii
 */

#macro DISARM_TYPE_BONE "bone"
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
    return {
        version : __disarm_struct_get_or_default(_struct, "scon_version", "1.0", is_string),
        entities : __disarm_array_map(
                __disarm_struct_get_or_default(_struct, "entity", [], is_array),
                __disarm_import_entity),
        currentEntity : 0,
    };
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