shader_type canvas_item;
uniform sampler2D terrain_texture;
uniform sampler2D terrain_colour_map;
uniform sampler2D noise: repeat_enable;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int debug_options;

const vec4 debug_colour_low = vec4(0.0, 0.0, 1.0, 0.7);
const vec4 debug_colour_high = vec4(1.0, 0.0, 0.0, 0.7);

int get_terrain_id(float elevation, float temp, float moisture) {
	// ERROR TERRAIN
	if (elevation < 0.0 || elevation > 1.0 || temp < 0.0 || temp > 1.0 || moisture < 0.0 || moisture > 1.0) {
		return 0;  // Error Terrain - for invalid parameters
	}

	// WATER TERRAINS
	if (elevation < 0.53) {  // All water is below this elevation
		// Ice Sheet - very cold water at any depth
		if (temp < 0.18) {
			return 14;  // Ice Sheet
		}

		// Deep Water (0.0-0.3 elevation)
		if (elevation < 0.3) {
			if (temp < 0.32) {
				return 1;  // Arctic Depths
			} else {
				return 2;  // Deep Ocean
			}
		}
		// Medium depth water (0.3-0.5 elevation)
		else if (elevation < 0.5) {
			if (temp > 0.7 && moisture > 0.7) {
				return 3;  // Warm Sea
			} else {
				return 2;  // Deep Ocean (fallback for medium depth)
			}
		}
		// Coastal Waters (0.5-0.55 elevation)
		else {
			if (temp > 0.7 && moisture > 0.6) {
				return 5;  // Coral Reef
			} else {
				return 4;  // Coastal Waters
			}
		}
	} 
	// LAND TERRAINS (elevation >= 0.55)
	else {
		// High Elevation Terrain (Mountains, etc.)
		if (elevation > 0.75) {
			if (temp < 0.1) {
				return 14;  // Ice Sheet (high altitude glacier)
			} else if (temp < 0.68) {
				return 12;  // Alpine
			} else {
				return 13;  // Rocky Mountains
			}
		}
			// Normal Elevation Terrain
			else {
			// Cold regions
			if (temp < 0.35) {
				return 6;  // Tundra
			}
			// Temperate regions
			else if (temp < 0.73) {
				if (moisture < 0.3) {
					return 7;  // Plains
				} else if (moisture < 0.5) {
					return 16; // Delicious Forest
				} else if (moisture < 0.7) {
					return 15; // Boreal forrest
				} 
				else {
					return 8;  // Wetlands
				}
			}
			// Hot regions
			else {
				if (moisture < 0.5) {
					return 9;  // Desert
				} else if (moisture < 0.65) {
					return 10;  // Savanna
				} else {
					return 11;  // Jungle
				}
			}
		}
	}
}
    

uniform float time_scale;

void fragment() {
	
	vec4 terrain_data = texture(terrain_texture, UV);
	vec4 colour;
	float elevation = terrain_data.r;
	float temp = terrain_data.g;
	float moisture = terrain_data.b;
	int terrain_id = get_terrain_id(elevation, temp, moisture);
	vec4 terrain_col = texelFetch(terrain_colour_map, ivec2(terrain_id, 0), 0);
	colour = terrain_col;
	switch (terrain_id) {
		case 1: // Arctic waters
			break;
		case 2:
			float depth = elevation / 0.53;
			float darkness = pow(depth, 1.5);
			vec4 deep_color = vec4(0.05, 0.1, 0.4, 1.0);
			vec4 shallow_color = terrain_col;
			colour = mix(deep_color, shallow_color, darkness);
			break;
		case 3:
			float depth = elevation / 0.53;
			float darkness = pow(depth, 1.5);
			vec4 deep_color = vec4(0.05, 0.1, 0.4, 1.0);
			vec4 shallow_color = terrain_col;
			colour = mix(deep_color, shallow_color, darkness);
			break;
		case 4: // Costal Water
			float depth = elevation / 0.53;
			float darkness = pow(depth, 1.5);
			vec4 deep_color = vec4(0.05, 0.1, 0.4, 1.0);
			vec4 shallow_color = terrain_col;
			colour = mix(deep_color, shallow_color, darkness);
			float wave = texture(noise, UV * 4.0 + vec2(TIME * 0.005, TIME * 0.003)).b;
			colour = mix(colour, vec4(1.0, 1.0, 1.0, 1.0), wave * 0.15);
			break;
		case 5: // Coral Reef
			float depth = elevation / 0.53;
			float darkness = pow(depth, 1.5);
			vec4 deep_color = vec4(0.05, 0.1, 0.4, 1.0);
			vec4 shallow_color = terrain_col;
			colour = mix(deep_color, shallow_color, darkness);
			
			float pink_coral = texture(noise, UV * 6.0).g;
			colour = mix(colour, vec4(0.9, 0.5, 1.0, 1.0), pink_coral * 0.4);
			break;
		case 6: // Tundra
			float snow_patch = texture(noise, UV * 5.0).r;
			colour = mix(colour, vec4(0.9, 0.95, 1.0, 1.0), smoothstep(0.2, 0.8, snow_patch) * 0.5);
			break;
		case 7: // Plains
			vec2 wind = vec2(TIME * 0.03, sin(TIME * 0.2) * 0.01);
			float grass_wave = texture(noise, UV * 3.0 + wind).r;
			colour = mix(colour, vec4(0.0, 0.0, 0.0, 1.0), grass_wave * 0.15);
		default:
			colour = terrain_col;
			break;
	}
	
	if (elevation > 0.53 && elevation < 0.532) {
		colour = vec4(1.0, 0.98, 0.5, 1.0);
	}
	
	if (temp < 0.28 && elevation < 0.4) {
		vec2 scroll = vec2(0.0005, (UV.y - 0.5) * 0.001);
		float noise_col = texture(noise, UV + scroll * TIME).r;
		if (noise_col * (0.28 - temp) > 0.04) {
			colour = vec4(0.9, 0.95, 1.0, 1.0);
		}
	}
	
	switch (debug_options) {
	    case 1:
	        colour = mix(debug_colour_low, debug_colour_high, elevation);
	        break;
	    case 2:
	        colour = mix(debug_colour_low, debug_colour_high, temp);
	        break;
	    case 3:
	        colour = mix(debug_colour_low, debug_colour_high, moisture);
	        break;
	}
	COLOR = colour;

}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
// Function to determine terrain ID based on elevation, temp, and moisture
