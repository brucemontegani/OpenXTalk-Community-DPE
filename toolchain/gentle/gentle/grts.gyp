{
	'includes':
	[
		'../../../common.gypi',
	],
	
	'targets':
	[
		{
			'target_name': 'grts',
			'type': 'static_library',
			
			'toolsets': ['host','target'],

			'cflags_c': [
  				'-std=gnu89',
				'-Wno-implicit-int',
  				'-Wno-implicit-function-declaration',
			],

			'xcode_settings': {
  				'OTHER_CFLAGS': [
    				'-std=gnu89',
					'-Wno-implicit-int',
  					'-Wno-implicit-function-declaration',
  				],
			},
			
			'product_name': 'grts',
		
			'variables':
			{
				'silence_warnings': 1,
			},
	
			'sources':
			[
				'grts.c',
			],
			
			'target_conditions':
			[
				[
					'_toolset != "target"',
					{
						'product_name': 'grts->(_toolset)',
					},
				],
			],
		},
	],
}
