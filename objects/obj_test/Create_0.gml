arm = disarm_import_from_string(@'
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
disarm_update_world_transform(arm);