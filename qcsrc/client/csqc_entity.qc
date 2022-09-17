var void(float) csqc_entity_parsers[NET_CSQC_COUNT];
var void(void) csqc_entity_temp_parsers[NET_TE_CSQC_COUNT];

void(float ignore) csqc_entity_error {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void(void) csqc_entity_temp_error {
	error(strcat("unknown entity type in CSQC_Parse_TempEntity: ", ftos(self.enttype), "\n"));
}

void(void) csqc_entity_clean {
	if (self.entremove)
		self.entremove();

	self.enttype = 0;
	self.classname = "";
	self.draw = NULL;
	self.entremove = NULL;
}

void CSQC_Ent_Remove() { //called by engine
	if (self.enttype)
		csqc_entity_clean();

	remove(self);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void(float bIsNewEntity) CSQC_Ent_Update { //called by engine
	float t;
	float savetime;
	t = net_read_byte();
	// set up the "time" global for received entities to be correct for interpolation purposes
	savetime = time;
	if (server_time) {
		time = server_time;
	} else {
		server_prevtime = time;
		server_deltatime = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
		time = server_prevtime + server_deltatime;
	}
	if (self.enttype)
		if (t != self.enttype) {
			//print("A CSQC entity changed its type!\n");
			csqc_entity_clean();
			bIsNewEntity = 1;
		}
	if (t >= NET_CSQC_COUNT)
		csqc_entity_error(0);

	self.enttype = t;
	csqc_entity_parsers[t](bIsNewEntity);
	time = savetime;
}

void(void) csqc_entity_temp_hit_read {
	if (CVAR(cl_hitsound))
		sound(world, CHAN_AUTO, "misc/hit.wav", VOL_BASE, ATTN_NONE);

	if (CVAR(crosshair_hit_time) > 0)
		view_crosshair_hittime = time + CVAR(crosshair_hit_time);
}

void(void) csqc_entity_temp_weapon_list_show {
	sbar_weapons_time = time;
}

void(void) csqc_entity_temp_team_select_show {
	if not(main_isdemo)
		GUI_Show(GUI_TEAMSELECT);
}

void(void) csqc_entity_temp_map_list_read {
	str_unzone_ifneeded(gui_available_maps);
	gui_available_maps = str_zone_ifneeded(net_read_string());
	string s = gui_available_maps;
	gui_available_maps_count = 0;
	while (s != "") {
		s = str_cdr(s);
		gui_available_maps_count++;
	}
}

void(void) csqc_entity_temp_game_over {
	if (main_calledhooks & MAIN_HOOK_START) {
		localcmd("\ncl_hook_gameend;");
		main_calledhooks |= MAIN_HOOK_END;
	}
}

void(void) csqc_entity_init {
	float i;
	for (i = 0; i < NET_CSQC_COUNT; i++) {
		csqc_entity_parsers[i] = csqc_entity_error;
	}
	for (i = 0; i < NET_TE_CSQC_COUNT; i++) {
		csqc_entity_temp_parsers[i] = csqc_entity_temp_error;
	}
	csqc_entity_parsers[NET_CSQC_ENTCS] = entcs_read;
	csqc_entity_parsers[NET_CSQC_SCORES_INFO] = score_info_read;
	csqc_entity_parsers[NET_CSQC_SCORES] = score_player_read;
	csqc_entity_parsers[NET_CSQC_TEAMSCORES] = score_team_read;
	csqc_entity_parsers[NET_CSQC_POINTPARTICLES] = particles_point_read;
	csqc_entity_parsers[NET_CSQC_RAINSNOW] = particles_rain_or_snow_read;
	csqc_entity_parsers[NET_CSQC_LASER] = laser_read;
	csqc_entity_parsers[NET_CSQC_NAGGER] = ready_read;
	csqc_entity_parsers[NET_CSQC_WAYPOINT] = waypointsprite_read;
	csqc_entity_parsers[NET_CSQC_RADARLINK] = teamradar_link_read;
	csqc_entity_parsers[NET_CSQC_PROJECTILE] = projectile_read;
	csqc_entity_parsers[NET_CSQC_INIT] = main_init_read;
	csqc_entity_parsers[NET_CSQC_MAPVOTE] = mapvote_read;
	csqc_entity_parsers[NET_CSQC_RANDOMSEED] = prandom_seed_read;
	csqc_entity_parsers[NET_CSQC_MODEL] = model_read;
	csqc_entity_parsers[NET_CSQC_MODELEFFECT] = effect_model_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS] = physics_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_SPIDERBOT] = physics_spiderbot_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_AIRCRAFT] = physics_aircraft_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_CAR] = physics_car_read;
	csqc_entity_parsers[NET_CSQC_GAMESTATUS] = gamestatus_read;
	csqc_entity_parsers[NET_CSQC_MENU] = menu_read;
	csqc_entity_parsers[NET_CSQC_PROGRESSBAR] = progressbar_read;
	csqc_entity_parsers[NET_CSQC_LOCATION_REQUEST] = locationrequest_read;
	csqc_entity_parsers[NET_CSQC_DLC_LIST] = dlc_read;
	csqc_entity_parsers[NET_CSQC_ZAPPER] = zapper_beam_read;
	csqc_entity_parsers[NET_CSQC_ZAPPER_SHIELD] = zapper_shield_read;
	csqc_entity_parsers[NET_CSQC_DMG_INDICATOR] = damage_indicator_read;
	csqc_entity_parsers[NET_CSQC_WARPZONE] = warpzone_read;
	csqc_entity_parsers[NET_CSQC_FUNC_CAMERA] = func_camera_read;
	csqc_entity_parsers[NET_CSQC_WARPZONE_TELEPORTED] = warpzone_teleported_read;
	csqc_entity_parsers[NET_CSQC_NOTELINE] = noteline_read;
	csqc_entity_parsers[NET_CSQC_HOOK] = hook_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_HOOK] = hook_physics_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_JETPACK] = jetpack_read;
	csqc_entity_parsers[NET_CSQC_LMS_SPHERE] = sphere_read;
	csqc_entity_parsers[NET_CSQC_ICE] = ice_read;
	csqc_entity_parsers[NET_CSQC_3RDVIEW] = thirdview_read;
	csqc_entity_parsers[NET_CSQC_SHOOTINGRANGE] = shootingrange_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_PICTURE - NET_TE_CSQC_FIRST] = mapvote_picture_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RACE - NET_TE_CSQC_FIRST] = race_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_ZCURVEPARTICLES - NET_TE_CSQC_FIRST] = particles_zcurve_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_NEXGUNBEAMPARTICLE - NET_TE_CSQC_FIRST] = particles_nex_beam_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_LIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_BIGLIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_big_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_ZAPPERLIGHTNING - NET_TE_CSQC_FIRST] = zapper_lightning_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_NADGETSELECT - NET_TE_CSQC_FIRST] = nadgetselect_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_BLAST - NET_TE_CSQC_FIRST] = effect_blast_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RADIO - NET_TE_CSQC_FIRST] = radio_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONLIST - NET_TE_CSQC_FIRST] = csqc_entity_temp_weapon_list_show;
	csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONSELECT - NET_TE_CSQC_FIRST] = weaponselect_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_TEAMSELECT - NET_TE_CSQC_FIRST] = csqc_entity_temp_team_select_show;
	csqc_entity_temp_parsers[NET_TE_CSQC_GAMEOVER - NET_TE_CSQC_FIRST] = csqc_entity_temp_game_over;
	csqc_entity_temp_parsers[NET_TE_CSQC_MAPLIST - NET_TE_CSQC_FIRST] = csqc_entity_temp_map_list_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_TRIP - NET_TE_CSQC_FIRST] = trip_net_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_ANNOUNCE_PRINT - NET_TE_CSQC_FIRST] = announce_print;
	csqc_entity_temp_parsers[NET_TE_CSQC_HINT - NET_TE_CSQC_FIRST] = hint_net_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_HIT - NET_TE_CSQC_FIRST] = csqc_entity_temp_hit_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_MODELSELECT - NET_TE_CSQC_FIRST] = modelselect_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RECORDLISTCHUNK - NET_TE_CSQC_FIRST] = recordlist_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_EFFECT_IMPACT - NET_TE_CSQC_FIRST] = effect_impact_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_CASING - NET_TE_CSQC_FIRST] = casing_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_GIBSPLASH - NET_TE_CSQC_FIRST] = gib_read;
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
float() CSQC_Parse_TempEntity { //called by engine
	// Acquire TE ID
	float n = net_read_byte();
	if (n < NET_TE_CSQC_FIRST) {
		return FALSE;
	}
	if (n >= NET_TE_CSQC_LAST_PLUS_ONE) {
		return FALSE;
	}
	csqc_entity_temp_parsers[n - NET_TE_CSQC_FIRST]();
	return TRUE;
}
