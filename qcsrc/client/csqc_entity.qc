var void(float) csqc_entity_parsers[ENT_CLIENT_COUNT];

void (float ignore) csqc_entity_error {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void(void) csqc_entity_clean {
	if(self.entremove)
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
	t = ReadByte();
	// set up the "time" global for received entities to be correct for interpolation purposes
	savetime = time;
	if (servertime) {
		time = servertime;
	} else {
		serverprevtime = time;
		serverdeltatime = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
		time = serverprevtime + serverdeltatime;
	}
	clienttime = time;
	if (self.enttype)
		if (t != self.enttype) {
			//print("A CSQC entity changed its type!\n");
			csqc_entity_clean();
			bIsNewEntity = 1;
		}
	if (t >= ENT_CLIENT_COUNT)
		csqc_entity_error(0);

	self.enttype = t;
	csqc_entity_parsers[t](bIsNewEntity);
	time = savetime;
}

void(void) csqc_entity_init {
	float i;
	for (i = 0; i < ENT_CLIENT_COUNT; i++) {
		csqc_entity_parsers[i] = csqc_entity_error;
	}
	csqc_entity_parsers[ENT_CLIENT_ENTCS] = entcs_read;
	csqc_entity_parsers[ENT_CLIENT_SCORES_INFO] = score_info_read;
	csqc_entity_parsers[ENT_CLIENT_SCORES] = score_player_read;
	csqc_entity_parsers[ENT_CLIENT_TEAMSCORES] = score_team_read;
	csqc_entity_parsers[ENT_CLIENT_POINTPARTICLES] = particles_point_read;
	csqc_entity_parsers[ENT_CLIENT_RAINSNOW] = particles_rain_or_snow_read;
	csqc_entity_parsers[ENT_CLIENT_LASER] = Ent_Laser;
	csqc_entity_parsers[ENT_CLIENT_NAGGER] = ready_read;
	csqc_entity_parsers[ENT_CLIENT_WAYPOINT] = Ent_WaypointSprite;
	csqc_entity_parsers[ENT_CLIENT_RADARLINK] = Ent_RadarLink;
	csqc_entity_parsers[ENT_CLIENT_PROJECTILE] = Ent_Projectile;
	csqc_entity_parsers[ENT_CLIENT_GIBSPLASH] = Ent_GibSplash;
	csqc_entity_parsers[ENT_CLIENT_DAMAGEINFO] = Ent_DamageInfo;
	csqc_entity_parsers[ENT_CLIENT_CASING] = Ent_Casing;
	csqc_entity_parsers[ENT_CLIENT_INIT] = main_init_read;
	csqc_entity_parsers[ENT_CLIENT_MAPVOTE] = mapvote_read;
	csqc_entity_parsers[ENT_CLIENT_RANDOMSEED] = prandom_seed_read;
	csqc_entity_parsers[ENT_CLIENT_WALL] = Ent_Wall;
	csqc_entity_parsers[ENT_CLIENT_MODELEFFECT] = Ent_ModelEffect;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS] = Ent_Physic;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS_SPIDERBOT] = Ent_PhysicSpiderbot;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS_AIRCRAFT] = Ent_PhysicAircraft;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS_CAR] = Ent_PhysicCar;
	csqc_entity_parsers[ENT_CLIENT_GAMESTATUS] = Ent_GameStatus;
	csqc_entity_parsers[ENT_CLIENT_MENU] = Ent_Menu;
	csqc_entity_parsers[ENT_CLIENT_PROGRESSBAR] = Ent_ProgressBar;
	csqc_entity_parsers[ENT_CLIENT_LOCATION_REQUEST] = Ent_LocationRequest;
	csqc_entity_parsers[ENT_CLIENT_DLC_LIST] = dlc_read;
	csqc_entity_parsers[ENT_CLIENT_ZAPPER] = Zapper_Read_Beam;
	csqc_entity_parsers[ENT_CLIENT_ZAPPER_SHIELD] = Zapper_Read_Shield;
	csqc_entity_parsers[ENT_CLIENT_DMG_INDICATOR] = Ent_DamageIndicator;
	csqc_entity_parsers[ENT_CLIENT_INIT_IP2C] = inline void(void) { sv_ip2country = TRUE; };
	csqc_entity_parsers[ENT_CLIENT_WARPZONE] = WarpZone_Read;
	csqc_entity_parsers[ENT_CLIENT_FUNC_CAMERA] = func_camera_read;
	csqc_entity_parsers[ENT_CLIENT_WARPZONE_TELEPORTED] = WarpZone_Teleported_Read;
	csqc_entity_parsers[ENT_CLIENT_NOTELINE] = Ent_NoteLine;
	csqc_entity_parsers[ENT_CLIENT_HOOK] = Ent_GrapplingHook;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS_HOOK] = hook_physics_read;
	csqc_entity_parsers[ENT_CLIENT_DLC_SOUND] = dlc_sound_read;
	csqc_entity_parsers[ENT_CLIENT_PHYSICS_JETPACK] = jetpack_read;
	csqc_entity_parsers[ENT_CLIENT_LMS_SPHERE] = sphere_read;
	csqc_entity_parsers[ENT_CLIENT_ICE] = ice_read;
}
