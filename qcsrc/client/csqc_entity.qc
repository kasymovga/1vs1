var void(float) csqc_entity_parsers[NET_CSQC_COUNT];
var void(void) csqc_entity_temp_parsers[NET_TE_CSQC_COUNT];

void(float ignore) csqc_entity_error {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void(void) csqc_entity_temp_error {
	error(strcat("unknown entity type in CSQC_Parse_TempEntity: ", ftos(self.enttype), "\n"));
}

void CSQC_Ent_Remove() { //called by engine
	if (self.entremove)
		self.entremove();

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
			if (self.entremove)
				self.entremove();

			entity e = spawn();
			builtin_copyentity(e, self); //force clean entity fields
			remove(e);
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
	csqc_entity_parsers[NET_CSQC_WAYPOINT] = marker_read;
	csqc_entity_parsers[NET_CSQC_RADARLINK] = radar_link_read;
	csqc_entity_parsers[NET_CSQC_PROJECTILE] = projectile_read;
	csqc_entity_parsers[NET_CSQC_INIT] = main_init_read;
	csqc_entity_parsers[NET_CSQC_MAPVOTE] = map_vote_read;
	csqc_entity_parsers[NET_CSQC_RANDOMSEED] = prandom_seed_read;
	csqc_entity_parsers[NET_CSQC_MODEL] = model_read;
	csqc_entity_parsers[NET_CSQC_MODELEFFECT] = effect_model_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS] = physics_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_SPIDERBOT] = physics_spiderbot_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_AIRCRAFT] = physics_aircraft_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_CAR] = physics_car_read;
	csqc_entity_parsers[NET_CSQC_GAMESTATUS] = game_status_read;
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
	csqc_entity_parsers[NET_CSQC_NOTE] = note_read;
	csqc_entity_parsers[NET_CSQC_HOOK] = hook_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_HOOK] = hook_physics_read;
	csqc_entity_parsers[NET_CSQC_PHYSICS_JETPACK] = jetpack_read;
	csqc_entity_parsers[NET_CSQC_LMS_SPHERE] = lms_sphere_read;
	csqc_entity_parsers[NET_CSQC_ICE] = ice_read;
	csqc_entity_parsers[NET_CSQC_3RDVIEW] = thirdview_read;
	csqc_entity_parsers[NET_CSQC_SHOOTINGRANGE] = shootingrange_read;
	csqc_entity_parsers[NET_CSQC_PORTO] = porto_read;
	csqc_entity_parsers[NET_CSQC_PORTAL] = portal_read;
	csqc_entity_parsers[NET_CSQC_CHESS_INFO] = chess_info_read;
	csqc_entity_parsers[NET_CSQC_RACE_RECORDS] = race_records_read;
	csqc_entity_parsers[NET_CSQC_TELEPORT_PREDICTION] = teleport_prediction_read;
	csqc_entity_parsers[NET_CSQC_TRIGGER_PUSH_PREDICTION] = trigger_push_prediction_read;
	csqc_entity_parsers[NET_CSQC_RM_FLAK_CHARGE_INDICATOR] = rm_flak_charge_indicator_read;
	csqc_entity_parsers[NET_CSQC_RM_GAME_TYPE_VOTE] = rm_game_type_vote_read;
	csqc_entity_parsers[NET_CSQC_RM_BUFFMODEL] = rm_buffs_model_read;
	csqc_entity_parsers[NET_CSQC_RM_EFFECT_HEAL_EMITTER] = rm_effect_heal_emitter_read;
	//csqc_entity_parsers[NET_CSQC_UNUSED] = ;
	csqc_entity_parsers[NET_CSQC_PIN_CODE_REQUEST] = pin_read;
	csqc_entity_parsers[NET_CSQC_TRIGGER_IMPULSE_PREDICTION] = trigger_impulse_prediction_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_PICTURE - NET_TE_CSQC_FIRST] = map_vote_picture_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RACE - NET_TE_CSQC_FIRST] = race_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_ZCURVEPARTICLES - NET_TE_CSQC_FIRST] = particles_zcurve_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_NEXGUNBEAMPARTICLE - NET_TE_CSQC_FIRST] = particles_nex_beam_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_LIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_BIGLIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_big_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_ZAPPERLIGHTNING - NET_TE_CSQC_FIRST] = zapper_lightning_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_NADGETSELECT - NET_TE_CSQC_FIRST] = nadget_select_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_BLAST - NET_TE_CSQC_FIRST] = effect_blast_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RADIO - NET_TE_CSQC_FIRST] = radio_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONLIST - NET_TE_CSQC_FIRST] = weapon_list_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONSELECT - NET_TE_CSQC_FIRST] = weapon_select_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_TEAMSELECT - NET_TE_CSQC_FIRST] = team_select_read;
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
	csqc_entity_temp_parsers[NET_TE_CSQC_NOTIFICATION - NET_TE_CSQC_FIRST] = notification_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_TELEPORTATION - NET_TE_CSQC_FIRST] = teleport_teleportation_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_HUDFLASH - NET_TE_CSQC_FIRST] = rm_hud_flash_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_HUDFLASH_TEAMCOLOR - NET_TE_CSQC_FIRST] = rm_hud_flash_team_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_DAMAGE_INDICATOR - NET_TE_CSQC_FIRST] = rm_damage_indicator_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_DAMAGE_RECEIVED_INDICATOR - NET_TE_CSQC_FIRST] = rm_damage_received_indicator_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_GAME_TYPE_VOTE_PICTURE - NET_TE_CSQC_FIRST] = rm_game_type_vote_picture_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_EFFECT_HEAL - NET_TE_CSQC_FIRST] = rm_effect_heal_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_RM_BIGPRINT - NET_TE_CSQC_FIRST] = rm_bigprint_read;
	csqc_entity_temp_parsers[NET_TE_CSQC_PRINT - NET_TE_CSQC_FIRST] = print_read;
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

// CSQC_Parse_CenterPrint : Provides the centerprint string in the first parameter that the server provided.
void(string strMessage) CSQC_Parse_CenterPrint {
	print_center(strMessage);
}
