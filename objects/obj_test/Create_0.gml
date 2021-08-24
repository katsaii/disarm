arm = disarm_import_from_string(@'
{
	"atlas": [
		{
			"name": "armature.json"
		}
	],
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
								"object_ref": [
									{
										"id": 0,
										"key": 0,
										"parent": 0,
										"timeline": "2",
										"z_index": "0"
									},
									{
										"id": 1,
										"key": 0,
										"parent": 1,
										"timeline": "3",
										"z_index": "1"
									},
									{
										"id": 2,
										"key": 0,
										"parent": 1,
										"timeline": "4",
										"z_index": "2"
									}
								]
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
								"object_ref": [
									{
										"id": 0,
										"key": 0,
										"parent": 0,
										"timeline": "2",
										"z_index": "0"
									},
									{
										"id": 1,
										"key": 0,
										"parent": 1,
										"timeline": "3",
										"z_index": "1"
									}
								],
								"time": 498
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
										"angle": 17.683581091966687,
										"x": 1.647482014388494,
										"y": 0.1726618705035987
									},
									"id": 0
								},
								{
									"bone": {
										"angle": 30.436246177151304,
										"x": 1.647482014388494,
										"y": 0.1726618705035987
									},
									"id": 1,
									"spin": -1,
									"time": 498
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
										"angle": 22.62538558244347,
										"scale_x": 0.6,
										"x": 67.35788366772583,
										"y": -0.1297574600478439
									},
									"id": 0
								},
								{
									"bone": {
										"angle": 70.09934455647362,
										"scale_x": 0.6,
										"x": 67.35788366772577,
										"y": -0.12975746004784378
									},
									"id": 1,
									"spin": -1,
									"time": 498
								}
							],
							"name": "bone_001",
							"obj": 1,
							"object_type": "bone"
						},
						{
							"id": 2,
							"key": [
								{
									"id": 0,
									"object": {
										"angle": 0.19932570830695795,
										"file": 1,
										"folder": 0,
										"x": -10.472076475420549,
										"y": 21.274634758805213
									},
									"spin": 0
								}
							],
							"name": "upper"
						},
						{
							"id": 3,
							"key": [
								{
									"id": 0,
									"object": {
										"angle": 359.85854712738524,
										"file": 0,
										"folder": 0,
										"scale_x": 1.6666666666666667,
										"x": -5.519229707916422,
										"y": 18.643402931617345
									},
									"spin": 0
								}
							],
							"name": "lower"
						},
						{
							"id": 4,
							"key": [
								{
									"id": 0,
									"object": {
										"angle": 346.2560845026678,
										"x": 120.46388652117382,
										"y": -1.009449613697458
									},
									"spin": 0
								}
							],
							"name": "point_000",
							"object_type": "point"
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
					"w": 84.61914676951075
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
	"folder": [
		{
			"atlas": 0,
			"file": [
				{
					"ah": 43,
					"arot": "false",
					"aw": 93,
					"ax": 1,
					"axoff": 0,
					"ay": 1,
					"ayoff": 0,
					"height": 43,
					"id": 0,
					"name": "lower.png",
					"pivot_x": 0,
					"pivot_y": 1,
					"width": 93
				},
				{
					"ah": 43,
					"arot": "false",
					"aw": 93,
					"ax": 1,
					"axoff": 0,
					"ay": 46,
					"ayoff": 0,
					"height": 43,
					"id": 1,
					"name": "upper.png",
					"pivot_x": 0,
					"pivot_y": 1,
					"width": 93
				}
			],
			"id": 0,
			"name": "."
		}
	],
	"generator": "BrashMonkey Spriter",
	"generator_version": "r11",
	"scon_version": "1.0"
}
');
show_debug_overlay(true);