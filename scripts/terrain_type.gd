class_name TerrainTypes




static func get_all_terrains() -> Dictionary:
	var terrains = {}
	# Format: [id, name, color, movement_cost, build_cost, sail-able]
		# Debug terrain
	terrains[0] = create_terrain(0, "Error Terrain", Color(1.0, 0.29, 0.64), 0.01, 999.0, 100.0, 0.05, true)
	terrains[1] = create_terrain(1, "Arctic Depths", Color(0.4, 0.5, 0.8), 3.0, 5.0, 0.7, 0.8, true) # Icy water
	terrains[2] = create_terrain(2, "Deep Ocean", Color(0.1, 0.2, 0.6), 2.8, 4.5, 0.8, 0.7, true) # Deep oceans
	terrains[3] = create_terrain(3, "Warm Sea", Color(0.1, 0.5, 0.8), 2.0, 3.0, 1.0, 0.5, true) # Oceans but warm
	terrains[4] = create_terrain(4, "Coastal Waters", Color(0.3, 0.6, 0.8), 1.8, 2.5, 1.0, 0.6, true) # Low elevation waters
	terrains[5] = create_terrain(5, "Coral Reef", Color(0.2, 0.8, 0.7), 2.0, 2.8, 0.9, 0.7, true) # Warm, Moist, shallow?
	terrains[6] = create_terrain(6, "Tundra", Color(0.8, 0.85, 0.7), 1.8, 2.8, 0.8, 1.0, false) # Cold, low elevation, not moist?
	terrains[7] = create_terrain(7, "Plains", Color(0.65, 0.75, 0.3), 0.8, 0.8, 1.3, 0.8, false) # Average in everything
	terrains[8] = create_terrain(8, "Wetlands", Color(0.4, 0.6, 0.3), 2.3, 3.0, 0.7, 1.1, false) # Low-ish temp, very moist, 
	terrains[9] = create_terrain(9, "Desert", Color(0.95, 0.85, 0.5), 1.5, 2.5, 1.0, 0.7, false) # Any elevation, but hot and no moisture
	terrains[10] = create_terrain(10, "Savanna", Color(0.63, 0.74, 0.23), 1.2, 1.2, 1.1, 0.9, false) # Hot slight moisture #@ 163, 191, 61
	terrains[11] = create_terrain(11, "Jungle", Color(0.1, 0.6, 0.1), 2.4, 2.0, 0.8, 1.4, false) # Hot extreme moisture
	terrains[12] = create_terrain(12, "Alpine", Color(0.9, 0.9, 1.0), 2.5, 3.0, 0.7, 1.5, false) # Cold, and high
	terrains[13] = create_terrain(13, "Rocky Mountains", Color(0.7, 0.7, 0.65), 2.8, 3.5, 0.6, 1.7, false) # High
	terrains[14] = create_terrain(14, "Ice Sheet", Color(0.9, 0.95, 1.0, 1.0), 2.3, 4.8, 1.2, 0.7, true) # Any ocean level that is cold enough
	terrains[15] = create_terrain(15, "Boreal Forest", Color(0.27, 0.5, 0.12), 0.8, 0.8, 1.3, 0.8, false) # Average, but a bit higher moisture
	terrains[16] = create_terrain(16, "Deciduous Forest", Color(0.45, 0.6, 0.3), 1.6, 1.8, 0.9, 1.3, false)
	
	return terrains
	
	
static func create_terrain(id: int, name: String, colour: Color, move_cost: float, build_cost: float, attack_mult: float, defence_mult: float, sailable: bool):
	return {
		"id": id,
		"name": name,
		"colour": colour,
		"movement_cost": move_cost,
		"build_cost": build_cost,
		"attack_mult": attack_mult,
		"defence_mult": defence_mult,
		"sailable": sailable
	}
	
	
static func get_terrain_id(elevation: float, temp: float, moisture: float) -> int:
	# ERROR TERRAIN
	if elevation < 0.0 or elevation > 1.0 or temp < 0.0 or temp > 1.0 or moisture < 0.0 or moisture > 1.0:
		return 0  # Error Terrain - for invalid parameters
	
	# WATER TERRAINS
	if elevation < 0.55:  # All water is below this elevation
		# Ice Sheet - very cold water at any depth
		if temp < 0.18:
			return 14  # Ice Sheet
		
		if elevation < 0.3:
			if temp < 0.32:
				return 1  # Arctic Depths
			else:
				return 2  # Deep Ocean
		
		elif elevation < 0.5:
			if temp > 0.7 and moisture > 0.7:
				return 3  # Warm Sea
			else:
				return 2  # Deep Ocean (fallback for medium depth)
		
		# Coastal Waters (0.5-0.55 elevation)
		else:
			if temp > 0.7 and moisture > 0.6:
				return 5  # Coral Reef
			else:
				return 4  # Coastal Waters
	
	# LAND TERRAINS (elevation >= 0.55)
	else:
		# High Elevation Terrain (Mountains, etc.)
		if elevation > 0.75:
			if temp < 0.12:
				return 14  # Ice Sheet (high altitude glacier)
			elif temp < 0.65:
				return 12  # Alpine
			else:
				return 13  # Rocky Mountains
		
		# Normal Elevation Terrain
		else:
			# Cold regions
			if temp < 0.3:
				return 6  # Tundra
			
			# Temperate regions
			elif temp < 0.68:
				if moisture < 0.4:
					return 7  # Plains
				elif moisture < 0.7:
					return 15 # Forest
				else:
					return 8  # Wetlands
			
			# Hot regions
			else:
				if moisture < 0.4:
					return 9  # Desert
				elif moisture < 0.65:
					return 10  # Savanna
				else:
					return 11  # Jungle
	

	
static func colourMap(terrain_set: Dictionary):
	var max_id: int = 0
	for id in terrain_set.keys():
		max_id = max(max_id, id)

	var img = Image.create(max_id + 1, 1, false, Image.FORMAT_RGBA8)
	
	for id in terrain_set.keys():
		img.set_pixel(id, 0, terrain_set[id].colour)
	img.save_png("res://test.png")
	return ImageTexture.create_from_image(img)
