var void(float) net_csqc_entity_parsers[NET_CSQC_COUNT];
var void(void) net_csqc_entity_temp_parsers[NET_TE_CSQC_COUNT];

void(float ignore) net_csqc_entity_error {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void(void) net_csqc_entity_temp_error {
	error(strcat("unknown entity type in CSQC_Parse_TempEntity: ", ftos(self.enttype), "\n"));
}

#define net_csqc_entity_remove CSQC_Ent_Remove
void(void) net_csqc_entity_remove { //called by engine
	if (self.entremove)
		self.entremove();

	remove(self);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
#define net_csqc_entity_update CSQC_Ent_Update
void(float bIsNewEntity) net_csqc_entity_update { //called by engine
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
		net_csqc_entity_error(0);

	self.enttype = t;
	net_csqc_entity_parsers[t](bIsNewEntity);
	time = savetime;
}


vector(float data) net_decompress_vec {
	vector out;
	float pitch, yaw, len;
	if (data == 0)
		return '0 0 0';

	pitch = (data & 0xF000) / 0x1000;
	yaw =   (data & 0x0F80) / 0x80;
	len =   (data & 0x007F);
	//print("\ndecompress: pitch ", ftos(pitch)); print("yaw ", ftos(yaw)); print("len ", ftos(len), "\n");
	if (pitch == 0) {
		out_x = 0;
		out_y = 0;
		if(yaw == 31)
			out_z = -1;
		else
			out_z = +1;
	} else {
		yaw   = .19634954084936207740 * yaw;
		pitch = .19634954084936207740 * pitch - 1.57079632679489661922;
		out_x = cos(yaw) *  cos(pitch);
		out_y = sin(yaw) *  cos(pitch);
		out_z =            -sin(pitch);
	}
	//print("decompressed: ", vtos(out), "\n");
	return out * net_log_table[len];
}

void(void) net_csqc_entity_init {
	float i;
	for (i = 0; i < NET_CSQC_COUNT; i++) {
		net_csqc_entity_parsers[i] = net_csqc_entity_error;
	}
	for (i = 0; i < NET_TE_CSQC_COUNT; i++) {
		net_csqc_entity_temp_parsers[i] = net_csqc_entity_temp_error;
	}
	net_csqc_entity_parsers[NET_CSQC_ENTCS] = player_info_read;
	net_csqc_entity_parsers[NET_CSQC_SCORES_INFO] = score_info_read;
	net_csqc_entity_parsers[NET_CSQC_SCORES] = score_player_read;
	net_csqc_entity_parsers[NET_CSQC_TEAMSCORES] = score_team_read;
	net_csqc_entity_parsers[NET_CSQC_POINTPARTICLES] = particles_point_read;
	net_csqc_entity_parsers[NET_CSQC_RAINSNOW] = particles_rain_or_snow_read;
	net_csqc_entity_parsers[NET_CSQC_LASER] = laser_read;
	net_csqc_entity_parsers[NET_CSQC_NAGGER] = ready_read;
	net_csqc_entity_parsers[NET_CSQC_WAYPOINT] = marker_read;
	net_csqc_entity_parsers[NET_CSQC_RADARLINK] = radar_link_read;
	net_csqc_entity_parsers[NET_CSQC_PROJECTILE] = projectile_read;
	net_csqc_entity_parsers[NET_CSQC_INIT] = main_init_read;
	net_csqc_entity_parsers[NET_CSQC_MAPVOTE] = map_vote_read;
	net_csqc_entity_parsers[NET_CSQC_RANDOMSEED] = prandom_seed_read;
	net_csqc_entity_parsers[NET_CSQC_MODEL] = model_read;
	net_csqc_entity_parsers[NET_CSQC_MODELEFFECT] = effect_model_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS] = physics_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS_SPIDERBOT] = physics_spiderbot_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS_AIRCRAFT] = physics_aircraft_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS_CAR] = physics_car_read;
	net_csqc_entity_parsers[NET_CSQC_GAMESTATUS] = game_status_read;
	net_csqc_entity_parsers[NET_CSQC_MENU] = menu_read;
	net_csqc_entity_parsers[NET_CSQC_PROGRESSBAR] = progressbar_read;
	net_csqc_entity_parsers[NET_CSQC_LOCATION_REQUEST] = locationrequest_read;
	net_csqc_entity_parsers[NET_CSQC_DLC_LIST] = dlc_read;
	net_csqc_entity_parsers[NET_CSQC_ZAPPER] = zapper_beam_read;
	net_csqc_entity_parsers[NET_CSQC_ZAPPER_SHIELD] = zapper_shield_read;
	net_csqc_entity_parsers[NET_CSQC_DMG_INDICATOR] = damage_indicator_read;
	net_csqc_entity_parsers[NET_CSQC_WARPZONE] = warpzone_read;
	net_csqc_entity_parsers[NET_CSQC_FUNC_CAMERA] = func_camera_read;
	net_csqc_entity_parsers[NET_CSQC_WARPZONE_TELEPORTED] = warpzone_teleported_read;
	net_csqc_entity_parsers[NET_CSQC_NOTE] = note_read;
	net_csqc_entity_parsers[NET_CSQC_HOOK] = hook_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS_HOOK] = hook_physics_read;
	net_csqc_entity_parsers[NET_CSQC_PHYSICS_JETPACK] = jetpack_read;
	net_csqc_entity_parsers[NET_CSQC_LMS_SPHERE] = lms_sphere_read;
	net_csqc_entity_parsers[NET_CSQC_ICE] = ice_read;
	net_csqc_entity_parsers[NET_CSQC_3RDVIEW] = thirdview_read;
	net_csqc_entity_parsers[NET_CSQC_SHOOTINGRANGE] = shootingrange_read;
	net_csqc_entity_parsers[NET_CSQC_PORTO] = porto_read;
	net_csqc_entity_parsers[NET_CSQC_PORTAL] = portal_read;
	net_csqc_entity_parsers[NET_CSQC_CHESS_INFO] = chess_info_read;
	net_csqc_entity_parsers[NET_CSQC_RACE_RECORDS] = race_records_read;
	net_csqc_entity_parsers[NET_CSQC_TELEPORT_PREDICTION] = teleport_prediction_read;
	net_csqc_entity_parsers[NET_CSQC_TRIGGER_PUSH_PREDICTION] = trigger_push_prediction_read;
	net_csqc_entity_parsers[NET_CSQC_RM_FLAK_CHARGE_INDICATOR] = rm_flak_charge_indicator_read;
	net_csqc_entity_parsers[NET_CSQC_RM_GAME_TYPE_VOTE] = rm_game_type_vote_read;
	net_csqc_entity_parsers[NET_CSQC_RM_BUFFMODEL] = rm_buffs_model_read;
	net_csqc_entity_parsers[NET_CSQC_RM_EFFECT_HEAL_EMITTER] = rm_effect_heal_emitter_read;
	//net_csqc_entity_parsers[NET_CSQC_UNUSED] = ;
	net_csqc_entity_parsers[NET_CSQC_PIN_CODE_REQUEST] = pin_read;
	net_csqc_entity_parsers[NET_CSQC_TRIGGER_IMPULSE_PREDICTION] = trigger_impulse_prediction_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_PICTURE - NET_TE_CSQC_FIRST] = map_vote_picture_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RACE - NET_TE_CSQC_FIRST] = race_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_ZCURVEPARTICLES - NET_TE_CSQC_FIRST] = particles_zcurve_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_NEXGUNBEAMPARTICLE - NET_TE_CSQC_FIRST] = particles_nex_beam_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_LIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_BIGLIGHTNINGARC - NET_TE_CSQC_FIRST] = effect_lightningarc_big_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_ZAPPERLIGHTNING - NET_TE_CSQC_FIRST] = zapper_lightning_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_NADGETSELECT - NET_TE_CSQC_FIRST] = nadget_select_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_BLAST - NET_TE_CSQC_FIRST] = effect_blast_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RADIO - NET_TE_CSQC_FIRST] = radio_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONLIST - NET_TE_CSQC_FIRST] = weapon_list_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_WEAPONSELECT - NET_TE_CSQC_FIRST] = weapon_select_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_TEAMSELECT - NET_TE_CSQC_FIRST] = team_select_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_GAMEOVER - NET_TE_CSQC_FIRST] = main_game_over;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_MAPLIST - NET_TE_CSQC_FIRST] = map_list_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_TRIP - NET_TE_CSQC_FIRST] = trip_net_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_ANNOUNCE_PRINT - NET_TE_CSQC_FIRST] = announce_print;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_HINT - NET_TE_CSQC_FIRST] = hint_net_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_HIT - NET_TE_CSQC_FIRST] = effect_hit_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_MODELSELECT - NET_TE_CSQC_FIRST] = player_model_select_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RECORDLISTCHUNK - NET_TE_CSQC_FIRST] = recordlist_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_EFFECT_IMPACT - NET_TE_CSQC_FIRST] = effect_impact_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_CASING - NET_TE_CSQC_FIRST] = casing_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_GIBSPLASH - NET_TE_CSQC_FIRST] = gib_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_NOTIFICATION - NET_TE_CSQC_FIRST] = notification_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_TELEPORTATION - NET_TE_CSQC_FIRST] = teleport_teleportation_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_HUDFLASH - NET_TE_CSQC_FIRST] = rm_hud_flash_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_HUDFLASH_TEAMCOLOR - NET_TE_CSQC_FIRST] = rm_hud_flash_team_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_DAMAGE_INDICATOR - NET_TE_CSQC_FIRST] = rm_damage_indicator_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_DAMAGE_RECEIVED_INDICATOR - NET_TE_CSQC_FIRST] = rm_damage_received_indicator_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_GAME_TYPE_VOTE_PICTURE - NET_TE_CSQC_FIRST] = rm_game_type_vote_picture_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_EFFECT_HEAL - NET_TE_CSQC_FIRST] = rm_effect_heal_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_RM_BIGPRINT - NET_TE_CSQC_FIRST] = rm_bigprint_read;
	net_csqc_entity_temp_parsers[NET_TE_CSQC_PRINT - NET_TE_CSQC_FIRST] = print_read;
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
#define net_csqc_te_parse CSQC_Parse_TempEntity
float() net_csqc_te_parse { //called by engine
	// Acquire TE ID
	float n = net_read_byte();
	if (n < NET_TE_CSQC_FIRST) {
		return FALSE;
	}
	if (n >= NET_TE_CSQC_LAST_PLUS_ONE) {
		return FALSE;
	}
	net_csqc_entity_temp_parsers[n - NET_TE_CSQC_FIRST]();
	return TRUE;
}

// CSQC_Parse_CenterPrint : Provides the centerprint string in the first parameter that the server provided.
#define net_csqc_te_parse_centerprint CSQC_Parse_CenterPrint
void(string strMessage) net_csqc_te_parse_centerprint {
	print_center(strMessage);
}

float(void) net_read_int24 {
	float v;
	v = net_read_short() * 256; // note: this is signed
	v += net_read_byte(); // note: this is unsigned
	return v;
}

vector(void) net_read_vector {
	vector v;
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = net_read_coord();
	return v;
}

vector(void) net_read_color {
	vector v;
	v_x = net_read_byte();
	v_y = net_read_byte();
	v_z = net_read_byte();
	v /= 255;
	return v;
}
