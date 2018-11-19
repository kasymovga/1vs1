float g_spawn_furthest;
float g_teamdamage_resetspeed;
float g_forced_respawn;
float sv_defaultcharacter;
float sv_defaultplayercolors;
string sv_defaultplayermodel;
string sv_defaultplayermodel_red;
string sv_defaultplayermodel_blue;
string sv_defaultplayermodel_yellow;
string sv_defaultplayermodel_pink;
float sv_defaultplayerskin;
float sv_defaultplayerskin_red;
float sv_defaultplayerskin_blue;
float sv_defaultplayerskin_yellow;
float sv_defaultplayerskin_pink;
float sv_servermodelsonly;
float sv_reset_on_join;
float g_spawn_furthest;
float sv_servermodelsonly;
float sv_reset_on_join;
float g_teamdamage_resetspeed;
float g_forced_respawn;
float g_balance_armor_regen;
float g_balance_armor_regenlinear;
float g_balance_armor_regenstable;
float g_balance_armor_rot;
float g_balance_armor_rotlinear;
float g_balance_armor_rotstable;
float g_balance_fuel_limit;
float g_balance_fuel_regen;
float g_balance_fuel_regenlinear;
float g_balance_fuel_regenstable;
float g_balance_fuel_rot;
float g_balance_fuel_rotlinear;
float g_balance_fuel_rotstable;
float g_balance_health_regen;
float g_balance_health_regenlinear;
float g_balance_health_regenstable;
float g_balance_health_rot;
float g_balance_health_rotlinear;
float g_balance_health_rotstable;
float g_balance_kill_delay;
float g_balance_pause_armor_rot_spawn;
float g_balance_pause_fuel_rot_spawn;
float g_balance_pause_health_regen_spawn;
float g_balance_pause_health_rot_spawn;
float g_changeteam_banned;
float g_maxplayers;
float g_maxplayers_spectator_blocktime;
float g_player_brightness;
float g_spawnshieldtime;
float g_spawnsound;
float leadlimit;
float sv_spectate;
float sv_timeout;
float sv_timeout_number;
float sv_maxidle;
float sv_maxidle_forcespec;
entity spectator_note;

float Spectator_Note_Customize() {
	if (other.classname == "player")
		return FALSE;

	return TRUE;
}

void Spectator_Note_Message() {
	string s;
	if (other.classname == "spectator") {
		s = strcat("^1Spectating ^7", strreplace("{", "{}", other.enemy.netname), "\n^1Press ^3{+attack}^1 for another player\n^1Press ^3{+attack2}^1 to observe");
	} else if (other.classname == "observer")
		s = "^1Observing\n^1Press ^3{+attack}^1 to spectate";

	s = strcat(s, "\n^1Press ^3{+show_info}^1 for gamemode info");
	if (other.team <= 0)
		s = strcat(s, "\n^1Press ^3{+jump}^1 to join");

	self.message = s;
}

float reset_on_join_done;

void FixPlayermodel();

#define SPAWNPOINT_SCORE frags

void spawnfunc_info_player_survivor (void)
{
	spawnfunc_info_player_deathmatch();
}

void spawnfunc_info_player_start (void)
{
	spawnfunc_info_player_deathmatch();
}

void spawnfunc_info_player_deathmatch (void)
{
	self.classname = "info_player_deathmatch";
	waypoint_spawnforitem(self);
	relocate_spawnpoint();
}

void spawnpoint_use()
{
	if(teamplay)
	if(have_team_spawns)
	{
		self.team = activator.team;
		some_spawn_has_been_used = 1;
	}
};

// Returns:
//   -1 if a spawn can't be used
//   otherwise, a weight of the spawnpoint
float Spawn_Score(entity spot, entity playerlist, float teamcheck)
{
	float shortest, thisdist;
	entity player;

	// filter out spots for the wrong team
	if(teamcheck)
	if(spot.team != teamcheck)
		return -1;

	if(clienttype(self) == CLIENTTYPE_REAL)
	{
		if(spot.restriction == 1)
			return -1;
	}
	else
	{
		if(spot.restriction == 2)
			return -1;
	}
	if (!GameHook_SpawnPointGood(spot))
		return -1;

	player = playerlist;
	shortest = vlen(world.maxs - world.mins);
	for(player = playerlist; player; player = player.chain)
		if (player != self)
		{
			thisdist = vlen(player.origin - spot.origin);
			if (thisdist < shortest)
				shortest = thisdist;
		}
	return shortest;
}

float spawn_allbad;
float spawn_allgood;
entity Spawn_FilterOutBadSpots(entity firstspot, entity playerlist, float mindist, float teamcheck)
{
	local entity spot, spotlist, spotlistend;
	spawn_allgood = TRUE;
	spawn_allbad = TRUE;

	spotlist = world;
	spotlistend = world;

	for(spot = firstspot; spot; spot = spot.chain)
	{
		spot.SPAWNPOINT_SCORE = Spawn_Score(spot, playerlist, teamcheck);

		if(spawn_debugview)
		{
			setmodel(spot, "models/runematch/rune.mdl");
			if(spot.SPAWNPOINT_SCORE < mindist)
			{
				spot.colormod = '1 0 0';
				spot.scale = 1;
			}
			else
			{
				spot.colormod = '0 1 0';
				spot.scale = spot.SPAWNPOINT_SCORE / mindist;
			}
		}

		if(spot.SPAWNPOINT_SCORE >= 0) // spawning allowed here
		{
			if(spot.SPAWNPOINT_SCORE < mindist)
			{
				// too short distance
				spawn_allgood = FALSE;
			}
			else
			{
				// perfect
				spawn_allbad = FALSE;

				if(spotlistend)
					spotlistend.chain = spot;
				spotlistend = spot;
				if(!spotlist)
					spotlist = spot;

				/*
				if(teamcheck)
				if(spot.team != teamcheck)
					error("invalid spawn added");

				print("added ", etos(spot), "\n");
				*/
			}
		}
	}
	if(spotlistend)
		spotlistend.chain = world;

	/*
		entity e;
		if(teamcheck)
			for(e = spotlist; e; e = e.chain)
			{
				print("seen ", etos(e), "\n");
				if(e.team != teamcheck)
					error("invalid spawn found");
			}
	*/

	return spotlist;
}

entity Spawn_WeightedPoint(entity firstspot, float lower, float upper, float exponent)
{
	// weight of a point: bound(lower, mindisttoplayer, upper)^exponent
	// multiplied by spot.cnt (useful if you distribute many spawnpoints in a small area)
	local entity spot;

	RandomSelection_Init();
	for(spot = firstspot; spot; spot = spot.chain)
		RandomSelection_Add(spot, 0, string_null, pow(bound(lower, spot.SPAWNPOINT_SCORE, upper), exponent) * spot.cnt, spot.SPAWNPOINT_SCORE >= lower);

	return RandomSelection_chosen_ent;
}

/*
=============
SelectSpawnPoint

Finds a point to respawn
=============
*/
entity SelectSpawnPoint (float anypoint)
{
	local float teamcheck;
	local entity firstspot_new;
	local entity spot, firstspot, playerlist;

	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	teamcheck = 0;

	if(!anypoint && have_team_spawns)
		teamcheck = self.team;

	// get the list of players
	playerlist = findchain(classname, "player");
	// get the entire list of spots
	firstspot = findchain(classname, "info_player_deathmatch");
	// filter out the bad ones
	// (note this returns the original list if none survived)
	if(anypoint)
	{
		spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
	}
	else
	{
		firstspot_new = Spawn_FilterOutBadSpots(firstspot, playerlist, 100, teamcheck);
		if(!firstspot_new)
			firstspot_new = Spawn_FilterOutBadSpots(firstspot, playerlist, -1, teamcheck);
		firstspot = firstspot_new;

		// there is 50/50 chance of choosing a random spot or the furthest spot
		// (this means that roughly every other spawn will be furthest, so you
		// usually won't get fragged at spawn twice in a row)
		if (random() > g_spawn_furthest)
			spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
		else
			spot = Spawn_WeightedPoint(firstspot, 1, 5000, 5); // chooses a far far away spawnpoint
	}

	if(spawn_debugview)
	{
		print("spot mindistance: ", ftos(spot.SPAWNPOINT_SCORE), "\n");

		entity e;
		if(teamcheck)
			for(e = firstspot; e; e = e.chain)
				if(e.team != teamcheck)
					error("invalid spawn found");
	}

	if (!spot)
	{
		if(spawn_debug)
			GotoNextMap();
		else
			return world; // team can't spawn any more, because of actions of other team
	}

	return spot;
}

/*
=============
CheckPlayerModel

Checks if the argument string can be a valid playermodel.
Returns a valid one in doubt.
=============
*/
string FallbackPlayerModel = "models/player/marine.zym";
string CheckPlayerModel(string plyermodel) {
	if(strlen(plyermodel) < 4)
		return FallbackPlayerModel;
	if( substring(plyermodel,0,14) != "models/player/")
		return FallbackPlayerModel;
	else if(sv_servermodelsonly)
	{
		if(substring(plyermodel,-4,4) != ".zym")
		if(substring(plyermodel,-4,4) != ".dpm")
		if(substring(plyermodel,-4,4) != ".md3")
		if(substring(plyermodel,-4,4) != ".psk")
			return FallbackPlayerModel;
		// forbid the LOD models
		if(substring(plyermodel, -9,5) == "_lod1")
			return FallbackPlayerModel;
		if(substring(plyermodel, -9,5) == "_lod2")
			return FallbackPlayerModel;
		if(plyermodel != strtolower(plyermodel))
			return FallbackPlayerModel;
		if(!fexists(plyermodel))
			return FallbackPlayerModel;
	}
	return plyermodel;
}

/*
=============
Client_customizeentityforclient

LOD reduction
=============
*/
void Client_uncustomizeentityforclient()
{
	if(self.modelindex == 0) // no need to uncustomize then
		return;
	self.modelindex = self.modelindex_lod0;
	self.skin = self.skinindex;
}

float Client_customizeentityforclient()
{
	entity modelsource;

	self.alpha = Player_CalculateAlpha(self, other);
	if (GameHookChain_PlayerVisibleThroughWallFor(self, other))
		self.effects |= EF_NODEPTHTEST;
	else
		self.effects &~= EF_NODEPTHTEST;

	if(self.alpha < 0)
		return FALSE;

	if(self.modelindex == 0)
		return TRUE;

	// forcemodel stuff

#ifdef PROFILING
	float t0;
	t0 = gettime(GETTIME_HIRES); // reference
#endif

	modelsource = self;

#ifdef ALLOW_FORCEMODELS
	if(other.cvar_cl_forceplayermodelsfromnexuiz)
		if not(self.modelindex_lod0_from_nexuiz)
			modelsource = other;
	if(other.cvar_cl_forceplayermodels && sv_clforceplayermodels)
		modelsource = other;
#endif

	self.skin = modelsource.skinindex;

#if 0
	if(modelsource == self)
		self.skin = modelsource.skinindex;
	else
		self.skin = mod(modelsource.skinindex, 3); // forbid the fbskins as forced skins
#endif

	// self: me
	// other: the player viewing me
	float distance;
	float f;

	if(other.cvar_cl_playerdetailreduction <= 0)
	{
		if(other.cvar_cl_playerdetailreduction <= -2)
			self.modelindex = modelsource.modelindex_lod2;
		else if(other.cvar_cl_playerdetailreduction <= -1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	}
	else
	{
		distance = vlen(self.origin - other.origin);
		f = (distance + 100.0) * other.cvar_cl_playerdetailreduction;
		if(f > sv_loddistance2)
			self.modelindex = modelsource.modelindex_lod2;
		else if(f > sv_loddistance1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	}

#ifdef PROFILING
	float t1;
	t1 = gettime(GETTIME_HIRES); // reference
	client_cefc_accumulator += (t1 - t0);
#endif

	return TRUE;
}

void setmodel_lod(entity e, string modelname)
{
	string s;

	if(sv_loddistance1)
	{
		// FIXME: this only supports 3-letter extensions
		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod1", substring(modelname, -4, 4));
		if(fexists(s))
		{
			setmodel(e, s); // players have high precision
			self.modelindex_lod1 = self.modelindex;
		}
		else
			self.modelindex_lod1 = -1;

		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
		if(fexists(s))
		{
			setmodel(e, s); // players have high precision
			self.modelindex_lod2 = self.modelindex;
		}
		else
			self.modelindex_lod2 = -1;

		precache_model(modelname);
		setmodel(e, modelname); // players have high precision
		self.modelindex_lod0 = self.modelindex;

		if(self.modelindex_lod1 < 0)
			self.modelindex_lod1 = self.modelindex;

		if(self.modelindex_lod2 < 0)
			self.modelindex_lod2 = self.modelindex;
	}
	else
	{
		precache_model(modelname);
		setmodel(e, modelname); // players have high precision
		self.modelindex_lod0 = self.modelindex;
			// save it for possible player model forcing
	}

	s = whichpack(self.model);
	self.modelindex_lod0_from_nexuiz = ((s == "") || (substring(s, 0, 4) == "data"));

	player_setupanimsformodel();
	UpdatePlayerSounds();
}

void ClientSetView(entity to) {
	if not(clienttype(self) == CLIENTTYPE_REAL)
		return;

	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEW);
	WriteEntity(MSG_ONE, to);
}

void PutClientToSpot(entity spot) {
	self.deadflag = DEAD_NO;
	self.angles = spot.angles;
	self.angles_z = 0;
	self.fixangle = TRUE;
	self.crouch = FALSE;
	self.view_ofs = PL_VIEW_OFS;
	setorigin (self, spot.origin);
	self.prevorigin = self.origin;
	ClientSetView(self);
}

/*
=============
PutObserverInServer

putting a client as observer in the server
=============
*/
void PutObserverInServer(float frags_team_reset)
{
	entity	spot;

	GameHookChain_ObserverSpawn();
	PlayerClear(FALSE);

	spot = SelectSpawnPoint (TRUE);
	if(!spot)
		error("No spawnpoints for observers?!?\n");

	if (frags_team_reset || self.team <= 0)
	if (self.killcount != -666)
		bprint ("^4", self.netname, "^4 is spectating now\n");

	if (self.team >= 0)
		PlayerScore_Clear(self); // clear scores when needed

	self.spectatortime = time;

	self.classname = "observer";
	self.iscreature = FALSE;
	self.health = 1;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NOCLIP;
	self.flags = FL_CLIENT | FL_NOTARGET;
	self.armorvalue = 0;
	self.effects = 0;
	self.pauserotarmor_finished = 0;
	self.pauserothealth_finished = 0;
	self.pauseregen_finished = 0;
	self.damageforcescale = 0;
	self.death_time = 0;
	self.dead_frame = 0;
	self.alpha = 0;
	self.scale = 0;
	self.fade_time = 0;
	self.pain_frame = 0;
	self.pain_finished = 0;
	self.pushltime = 0;
	self.think = SUB_Null;
	self.nextthink = 0;
	self.hook_time = 0;
	PutClientToSpot(spot);
	setsize (self, '0 0 0', '0 0 0');
	self.items = 0;
	self.weapons = 0;
	self.model = "";
	FixPlayermodel();
	self.model = "";
	self.modelindex = 0;
	self.weapon = 0;
	self.weaponmodel = "";
	self.weaponentity = world;
	self.exteriorweaponentity = world;
	self.killcount = -666;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.punchvector = '0 0 0';
	self.oldvelocity = self.velocity;
	self.fire_endtime = -1;
	spectator_note.SendFlags = 1;

	if(sv_loddistance1)
		SetCustomizer(self, Client_customizeentityforclient, Client_uncustomizeentityforclient);

	if not(frags_team_reset)
		return;

	if (self.team != -1) {
		self.team = -1;
		ScoreKeeper_Touch(self);
	}

	self.frags = FRAGS_SPECTATOR;
}

float RestrictSkin(float s)
{
	if(!teamplay)
		return s;
	if(s == 6)
		return 6;
	return mod(s, 3);
}

void FixPlayermodel()
{
	local string defaultmodel;
	local float defaultskin, chmdl, oldskin;
	local vector m1, m2;

	defaultmodel = "";

	if (sv_defaultcharacter) {
		defaultskin = 0;

		if(teamplay)
		{
			defaultmodel =
					((self.team == COLOR_TEAM1) ? sv_defaultplayermodel_red :
					((self.team == COLOR_TEAM2) ? sv_defaultplayermodel_blue :
					((self.team == COLOR_TEAM3) ? sv_defaultplayermodel_yellow :
					((self.team == COLOR_TEAM4) ? sv_defaultplayermodel_pink : sv_defaultplayermodel))));

			defaultskin =
					((self.team == COLOR_TEAM1) ? sv_defaultplayerskin_red :
					((self.team == COLOR_TEAM2) ? sv_defaultplayerskin_blue :
					((self.team == COLOR_TEAM3) ? sv_defaultplayerskin_yellow :
					((self.team == COLOR_TEAM4) ? sv_defaultplayerskin_pink : sv_defaultplayerskin))));
		}

		if(defaultmodel == "")
		{
			defaultmodel = sv_defaultplayermodel;
			defaultskin = sv_defaultplayerskin;
		}
	}
	if(self.modelindex == 0 && self.deadflag == DEAD_NO)
	{
		if(self.model != "")
			bprint("\{1}^1Player ", self.netname, "^1 has a zero modelindex, trying to fix...\n");
		self.model = ""; // force the != checks to return true
	}
	if(defaultmodel != "")
	{
:setdefaultmodel
		if (defaultmodel != self.model)
		{
			m1 = self.mins;
			m2 = self.maxs;
			setmodel_lod (self, defaultmodel);
			setsize (self, m1, m2);
			chmdl = TRUE;
		}

		oldskin = self.skinindex;
		self.skinindex = defaultskin;
	} else {
		if (self.playermodel != self.model)
		{
			self.playermodel = CheckPlayerModel(self.playermodel);
			m1 = self.mins;
			m2 = self.maxs;
			setmodel_lod (self, self.playermodel);
			setsize (self, m1, m2);
			chmdl = TRUE;
		}

		oldskin = self.skinindex;
		self.skinindex = RestrictSkin(stof(self.playerskin));
	}

	if(chmdl || oldskin != self.skinindex)
		self.species = player_getspecies(); // model or skin has changed

	if(!teamplay)
		if (sv_defaultplayercolors > -2) {
			float colors = GameHookChain_PlayerColorsMod(sv_defaultplayercolors);
			if (self.clientcolors != colors)
				SetPlayerColors(self, colors);
		}
}

/*
=============
PutClientInServer

Called when a client spawns in the server
=============
*/
.float just_connected;
void PutClientInServer()
{
	if (self.just_connected) {
		self.team = -1;
		self.just_connected = FALSE;
		if (time + 5 < game_starttime)
			announce(self, "announcer/robotic/prepareforbattle.wav");
	}
	entity e;
	FOR_EACH_PLAYER(e)
		e.entcs.SendFlags |= 16;

	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		self.classname = "player";
	}
	if(gameover)
		self.classname = "observer";

	if(self.classname == "player") {
		entity spot, oldself;
		local float currentlyPlaying, i;
		float oldteam = self.team;

		if (self.team < 0) {
			if(clienttype(self) == CLIENTTYPE_BOT)
				self.team = self.bot_forced_team;

			JoinBestTeam(self, FALSE, FALSE);
		}
		if (self.team != oldteam)
			ScoreKeeper_Touch(self);

		spot = GameHook_SelectSpawnPoint();

		if(!spot) {
			if (clienttype(self) == CLIENTTYPE_REAL)
				centerprint(self, "Sorry, no spawnpoints available!\nHope your team can fix it...");

			print(self.netname, " not have place to spawn\n");
			PutObserverInServer(FALSE);
			return;
		}
		PlayerClear(FALSE);
		PhysicMarkAsTeleported(self);
		self.iscreature = TRUE;
		self.movetype = MOVETYPE_WALK;
		self.solid = SOLID_SLIDEBOX;
		self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
		self.frags = FRAGS_PLAYER;
		if(independent_players)
			MAKE_INDEPENDENT_PLAYER(self);
		self.flags = FL_CLIENT;
		self.takedamage = DAMAGE_AIM;
		self.effects = 0;
		self.air_finished = time + 12;
		self.dmg = 2;
		self.keys = 0;

		if not(GameHook_EquipPlayerHandle()) {
			if(inWarmupStage)
			{
				self.ammo_shells = warmup_start_ammo_shells;
				self.ammo_nails = warmup_start_ammo_nails;
				self.ammo_rockets = warmup_start_ammo_rockets;
				self.ammo_cells = warmup_start_ammo_cells;
				self.ammo_fuel = warmup_start_ammo_fuel;
				self.health = warmup_start_health;
				self.armorvalue = warmup_start_armorvalue;
				self.weapons = warmup_start_weapons;
			}
			else
			{
				self.ammo_shells = start_ammo_shells;
				self.ammo_nails = start_ammo_nails;
				self.ammo_rockets = start_ammo_rockets;
				self.ammo_cells = start_ammo_cells;
				self.ammo_fuel = start_ammo_fuel;
				self.health = start_health;
				self.armorvalue = start_armorvalue;
				self.weapons = start_weapons;
			}
		}
		self.items = start_items;
		self.switchweapon = w_getbestweapon(self);
		if not(self.switchweapon)
			for(i=WEP_FIRST; i <= WEP_LAST ; ++i)
				if(client_hasweapon(self, i, TRUE, FALSE))
					self.switchweapon = i;

		self.cnt = self.switchweapon;
		self.weapon = 0;
		self.jump_interval = time;

		self.spawnshieldtime = time + g_spawnshieldtime;
		self.pauserotarmor_finished = time + g_balance_pause_armor_rot_spawn;
		self.pauserothealth_finished = time + g_balance_pause_health_rot_spawn;
		self.pauserotfuel_finished = time + g_balance_pause_fuel_rot_spawn;
		self.pauseregen_finished = time + g_balance_pause_health_regen_spawn;
		//extend the pause of rotting if client was reset at the beginning of the countdown
		if(!restart_active && time < game_starttime) {
			self.spawnshieldtime += game_starttime - time;
			self.pauserotarmor_finished += game_starttime - time;
			self.pauserothealth_finished += game_starttime - time;
			self.pauseregen_finished += game_starttime - time;
		}
		self.damageforcescale = 2;
		self.death_time = 0;
		self.dead_frame = 0;
		self.alpha = 0;
		self.scale = sv_world_scale;
		self.fade_time = 0;
		self.pain_frame = 0;
		self.pain_finished = 0;
		self.pushltime = 0;
		//self.speed_finished = 0;
		//self.slowmo_finished = 0;
		// players have no think function
		self.think = SUB_Null;
		self.nextthink = 0;
		self.hook_time = 0;
		self.dmg_team = 0;

		PutClientToSpot(spot);
		self.velocity = '0 0 0';
		self.avelocity = '0 0 0';
		self.punchangle = '0 0 0';
		self.punchvector = '0 0 0';
		self.oldvelocity = self.velocity;
		self.fire_endtime = -1;

		msg_entity = self;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_SPAWN);
		});

		if(sv_loddistance1)
			SetCustomizer(self, Client_customizeentityforclient, Client_uncustomizeentityforclient);

		self.model = "";
		FixPlayermodel();

		self.stand_view_ofs = PL_VIEW_OFS;
		self.crouch_view_ofs = PL_CROUCH_VIEW_OFS;
		setsize (self, PL_MIN, PL_MAX);
		self.stand_mins = PL_MIN;
		self.stand_maxs = PL_MAX;
		self.crouch_mins = PL_CROUCH_MIN;
		self.crouch_maxs = PL_CROUCH_MAX;
		self.spawnorigin = spot.origin;
		// don't reset back to last position, even if new position is stuck in solid
		self.oldorigin = self.origin;

		self.event_damage = PlayerDamage;

		self.bot_attack = TRUE;

		self.statdraintime = time + 5;
		self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = 0;

		if(self.killcount == -666) {
			PlayerScore_Clear(self);
			self.killcount = 0;
		}

		self.cnt = WEP_LASER;

		CL_SpawnWeaponentity();
		self.alpha = default_player_alpha;
		self.colormod = '1 1 1' * g_player_brightness;

		self.speedrunning = FALSE;

		if(spawn_debug)
		{
			sprint(self, strcat("spawnpoint origin:  ", vtos(spot.origin), "\n"));
			remove(spot);	// usefull for checking if there are spawnpoints, that let drop through the floor
		}

		if (g_spawnsound)
			sound (self, CHAN_TRIGGER, "misc/spawn.wav", VOL_BASE, ATTN_NORM);

		target_voicescript_clear(self);

		oldself = self;
		self = spot;
			activator = oldself;
				SUB_UseTargets();
			activator = world;
		self = oldself;

		if (sv_reset_on_join)
		if not(reset_on_join_done)
		{
			FOR_EACH_REALPLAYER(e)
				if(e.classname == "player")
					currentlyPlaying += 1;
			if (currentlyPlaying == sv_reset_on_join)
			{
				reset_on_join_done = TRUE;
				if (time > game_starttime)
					ReadyRestartForce();
			}
		}
		player_effects();
		GameHookChain_Spawn(spot);
		antilag_teleported(self);
		self.wasplayer = TRUE;
	} else if(self.classname == "observer") {
		PutObserverInServer(TRUE);
	}
}

void PlayerToSpec(entity player)
{
	if (player.classname == "player" || (player.classname == "spectator" && player.team >= 0))
	if not(g_campaign)
	if not(GameHook_ForbidSpectators())
	if (sv_spectate) {
		entity oldself = self;
		self = player;
		PlayerClear(FALSE);
		player.classname = "observer";
		if(blockSpectators)
			sprint(player, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));

		PutClientInServer();
		ScoreKeeper_Touch(player);
		self = oldself;
		spectator_note.SendFlags = 1;
		if (teamplay)
			AuditTeams(FALSE);
	}
}

float ClientInit_SendEntity(entity to, float sf)
{
	float i, t;
	WriteByte(MSG_ENTITY, ENT_CLIENT_INIT);
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		for(i = 1; i <= 24; ++i)
			WriteByte(MSG_ENTITY, (get_weaponinfo(i)).impulse + 1);
	}
	if (sf & 4) {
		if(sv_foginterval && world.fog != "")
			WriteString(MSG_ENTITY, world.fog);
		else
			WriteString(MSG_ENTITY, "");
	}
	if (sf & 8) {
		WriteString(MSG_ENTITY, cvar_string("sv_vote_commands"));
	}
	if (sf & 16)
		GameMenu_Send();

	if (sf & 32) {
		WriteByte(MSG_ENTITY, teamplay);
		t = 0;
		if(teamplay) {
			CheckAllowedTeams(self);
			if(c1 >= 0) t |= 1; if(c2 >= 0) t |= 2; if(c3 >= 0) t |= 4; if(c4 >= 0) t |= 8;
		}
		WriteByte(MSG_ENTITY, t);
	}

	if(sf & 64) {
		ProjInfo_Send();
	}

	return TRUE;
}

entity client_init;
void ClientInit_Spawn()
{
	client_init = spawn();
	Net_LinkEntity(client_init, FALSE, 0, ClientInit_SendEntity);
}

/*
=============
SetNewParms
=============
*/
void SetNewParms (void)
{
	// initialize parms for a new player
	parm1 = -(86400 * 366);
	GameHook_SetNewParms();
}

/*
=============
SetChangeParms
=============
*/
void SetChangeParms (void)
{
	// save parms for level change
	parm1 = self.parm_idlesince - time;
	GameHook_SetChangeParms();
}

/*
=============
DecodeLevelParms
=============
*/
void DecodeLevelParms (void)
{
	// load parms
	self.parm_idlesince = parm1;
	if(self.parm_idlesince == -(86400 * 366))
		self.parm_idlesince = time;

	// whatever happens, allow 60 seconds of idling directly after connect for map loading
	self.parm_idlesince = max(self.parm_idlesince, time - sv_maxidle + 60);
	GameHook_DecodeLevelParms();
}

/*
=============
ClientKill

Called when a client types 'kill' in the console
=============
*/

void ClientKill_Now_TeamChange()
{
	if(self.killindicator_teamchange == -2)
	{
		PlayerToSpec(self);
	}
	else if(self.killindicator_teamchange == -1)
	{
		self.team = -1;
		JoinBestTeam( self, FALSE, FALSE );
	}
	else
		ChangeTeam(self, self.killindicator_teamchange, FALSE);
}

void ClientKill_Now()
{
	if(self.killindicator_teamchange)
		ClientKill_Now_TeamChange();
	else
		Damage(self, self, self, 100000, DEATH_KILL, self.origin, '0 0 0');

	if(self.killindicator)
	{
		dprint("Cleaned up after a leaked kill indicator.\n");
		remove(self.killindicator);
		self.killindicator = world;
	}
}
void KillIndicator_Think()
{
	if (!self.owner.modelindex)
	{
		self.owner.killindicator = world;
		remove(self);
		return;
	}

	if(self.cnt <= 0)
	{
		self = self.owner;
		ClientKill_Now(); // no oldself needed
		return;
	}
	else
	{
		if(self.cnt <= 10)
			setmodel(self, strcat("models/sprites/", ftos(self.cnt), ".spr32"));
		if(clienttype(self.owner) == CLIENTTYPE_REAL)
		{
			if(self.cnt <= 10)
				announce(self.owner, strcat("announcer/robotic/", ftos(self.cnt), ".wav"));
			if(self.owner.killindicator_teamchange)
			{
				if(self.owner.killindicator_teamchange == -1)
					centerprint(self.owner, strcat("Changing team in ", ftos(self.cnt), " seconds"));
				else
					centerprint(self.owner, strcat("Changing to ", ColoredTeamName(self.owner.killindicator_teamchange), " in ", ftos(self.cnt), " seconds"));
			}
			else
				centerprint(self.owner, strcat("^1Suicide in ", ftos(self.cnt), " seconds"));
		}
		self.nextthink = time + 1;
		self.cnt -= 1;
	}
}

void ClientKill_TeamChange (float targetteam) // 0 = don't change, -1 = auto
{
	float killtime;
	entity e;
	killtime = GameHook_KillDelayMod(g_balance_kill_delay);

	self.killindicator_teamchange = targetteam;

	if(!self.killindicator)
	{
		if(killtime <= 0 || !self.modelindex || self.deadflag != DEAD_NO || FastTeamSwitchAllowed(self, targetteam))
		{
			ClientKill_Now();
		}
		else
		{
			self.killindicator = spawn();
			self.killindicator.owner = self;
			self.killindicator.scale = 0.5;
			setattachment(self.killindicator, self, "");
			setorigin(self.killindicator, '0 0 52');
			self.killindicator.think = KillIndicator_Think;
			self.killindicator.nextthink = time + (self.lip) * 0.05;
			self.killindicator.cnt = ceil(killtime);
			self.killindicator.count = bound(0, ceil(killtime), 10);
			sprint(self, strcat("^1You'll be dead in ", ftos(self.killindicator.cnt), " seconds\n"));

			for(e = world; (e = find(e, classname, "body")) != world; )
			{
				if(e.enemy != self)
					continue;
				e.killindicator = spawn();
				e.killindicator.owner = e;
				e.killindicator.scale = 0.5;
				setattachment(e.killindicator, e, "");
				setorigin(e.killindicator, '0 0 52');
				e.killindicator.think = KillIndicator_Think;
				e.killindicator.nextthink = time + (e.lip) * 0.05;
				e.killindicator.cnt = ceil(killtime);
			}
			self.lip = 0;
		}
	}
	if(self.killindicator)
	{
		if(targetteam)
			self.killindicator.colormod = TeamColor(targetteam);
		else
			self.killindicator.colormod = '0 0 0';
	}
}

void ClientKill (void)
{
	ClientKill_TeamChange(0);
}

void DoTeamChange(float destteam)
{
	float t, c0;
	if(!teamplay)
	{
		if(destteam >= 0)
			SetPlayerColors(self, destteam);
		return;
	}
	if(self.classname == "player")
	if(destteam == -1)
	{
		CheckAllowedTeams(self);
		t = FindSmallestTeam(self, TRUE);
		switch(self.team)
		{
			case COLOR_TEAM1: c0 = c1; break;
			case COLOR_TEAM2: c0 = c2; break;
			case COLOR_TEAM3: c0 = c3; break;
			case COLOR_TEAM4: c0 = c4; break;
			default:          c0 = 999;
		}
		switch(t)
		{
			case 1:
				if(c0 > c1)
					destteam = COLOR_TEAM1;
				break;
			case 2:
				if(c0 > c2)
					destteam = COLOR_TEAM2;
				break;
			case 3:
				if(c0 > c3)
					destteam = COLOR_TEAM3;
				break;
			case 4:
				if(c0 > c4)
					destteam = COLOR_TEAM4;
				break;
		}
		if(destteam == -1)
			return;
	}
	if(destteam == self.team && destteam >= 0 && !self.killindicator)
		return;
	ClientKill_TeamChange(destteam);
}

void FixClientCvars(entity e)
{
	stuffcmd(e, strcat("\nin_bindmap 0 0\n", GameHook_FixClientCvars(), "\n"));
}

void Check_ForRetard(entity player) {
	string tail = cvar_string("sv_retard_nets");
	string head;
	string address_check = strcat(player.netaddress, ".");
	if (player.netname == retardplayername)
		player.retard = 1;

	while (tail != "") {
		head = car(tail);
		tail = cdr(tail);
		if (head == "")
			continue;

		if (strstrofs(address_check, head, 0) == 0) {
			player.retard = 1;
			print("Retard connected with address ", address_check, " and pattern ", head, "\n");
			break;
		}
	}
}

float ClientPreConnect_Abort() {
	if (self.just_connected)
		return FALSE;

	if(Ban_MaybeEnforceBan(self))
		return TRUE;

	self.just_connected = TRUE;
	self.team = -1;
	self.retard = -1;
	Check_ForRetard(self);
	return FALSE;
}

/*
=============
ClientConnect

Called when a client connects to the server
=============
*/
void ClientConnect (void)
{
	if not(self.flags & FL_CLIENT) {
		if (ClientPreConnect_Abort())
			return;

		self.flags = FL_CLIENT;
	}
	if (self.retard > 0)
		self.netname = retardplayername;

	DecodeLevelParms();

	self.classname = "player_joining";
	self.team = -1; //clear engine assigned values
	if(player_count<0)
	{
		dprint("BUG player count is lower than zero, this cannot happen!\n");
		player_count = 0;
	}

	PlayerScore_Attach(self);
	ScoreKeeper_Touch(self);

	bot_clientconnect();

	if (g_campaign) {
		self.classname = "player";
		campaign_bots_may_start = 1;
	} else if (GameHook_ForbidSpectators()) {
		self.classname = "player";
	} else if (sv_spectate == 1) {
		self.classname = "observer";
	} else {
		if(teamplay)
		{
			if(g_balance_teams || g_balance_teams_force)
			{
				self.classname = "player";
			}
			else
			{
				self.classname = "observer"; // do it anyway
			}
		}
		else
		{
			self.classname = "player";
		}
	}

	self.playerid = (playerid_last = playerid_last + 1);

	//stuffcmd(self, "set tmpviewsize $viewsize \n");

	bprint ("^4", self.netname, "^4 connected\n");

	self.welcomemessage_time = 0;

	stuffcmd(self, strcat(clientstuff, "\n"));
	stuffcmd(self, strcat("exec maps/", mapname, ".cfg\n"));
	stuffcmd(self, "cl_particles_reloadeffects\n");

	FixClientCvars(self);

	// spawnfunc_waypoint sprites
	WaypointSprite_InitClient(self);

	// Wazat's grappling hook
	SetGrappleHookBindings();

	// get other cvars from player
	Client_GetCvars();

	attach_entcs();

	bot_relinkplayerlist();

	self.spectatortime = time;
	if(blockSpectators)
	{
		sprint(self, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));
	}

	self.jointime = time;
	self.allowedTimeouts = sv_timeout_number;

	if(!sv_foginterval && world.fog != "")
		stuffcmd(self, strcat("\nfog ", world.fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));

	SoundEntity_Attach(self);

	if (clienttype(self) == CLIENTTYPE_REAL)
	{
		GameHookChain_RealClientConnect();
	}

	IP2C_SetCountry(self);
}

/*
=============
ClientDisconnect

Called when a client disconnects from the server
=============
*/
.entity chatbubbleentity;
void ClientDisconnect (void)
{
	if not(self.flags & FL_CLIENT)
	{
		print("Warning: ClientDisconnect without ClientConnect\n");
		return;
	}

	bot_clientdisconnect();

	if(self.entcs)
		detach_entcs();

	bprint ("^4",self.netname);
	bprint ("^4 disconnected\n");

	SoundEntity_Detach(self);

	self.classname = "disconnecting";

	PlayerClear(FALSE);

	// Here, everything has been done that requires this player to be a client.

	self.flags &~= FL_CLIENT;
	self.just_connected = FALSE;

	if (self.chatbubbleentity)
		remove (self.chatbubbleentity);

	if (self.killindicator)
		remove (self.killindicator);

	WaypointSprite_PlayerGone();

	bot_relinkplayerlist();

	// remove laserdot
	if(self.weaponentity)
		if(self.weaponentity.lasertarget)
			remove(self.weaponentity.lasertarget);

	PlayerScore_Detach(self);

	if(self.clientstatus)
		strunzone(self.clientstatus);

	ClearPlayerSounds();

	self.playerid = 0;
	self.retard = 0;
	self.muted = 0;
	ReadyCount();

	// free cvars
	Client_GetCvars_Free();

	if (clienttype(self) == CLIENTTYPE_REAL)
		GameHookChain_RealClientDisconnect();

	if (teamplay) {
		AuditTeams(FALSE);
		if (autoswap_last_best == self)
			autoswap_last_best = world;
	}
}

.float BUTTON_CHAT;
void ChatBubbleThink()
{
	self.nextthink = time;
	if (!self.owner.modelindex || self.owner.chatbubbleentity != self)
	{
		if(self.owner) // but why can that ever be world?
			self.owner.chatbubbleentity = world;
		remove(self);
		return;
	}
	if ((self.owner.BUTTON_CHAT && !self.owner.deadflag))
		self.model = self.mdl;
	else
		self.model = "";
};

void UpdateChatBubble()
{
	if (!self.modelindex)
		return;
	// spawn a chatbubble entity if needed
	if (!self.chatbubbleentity)
	{
		self.chatbubbleentity = spawn();
		self.chatbubbleentity.owner = self;
		self.chatbubbleentity.exteriormodeltoclient = self;
		self.chatbubbleentity.think = ChatBubbleThink;
		self.chatbubbleentity.nextthink = time;
		setmodel(self.chatbubbleentity, "models/misc/chatbubble.spr"); // precision set below
		//setorigin(self.chatbubbleentity, self.origin + '0 0 15' + self.maxs_z * '0 0 1');
		setorigin(self.chatbubbleentity, '0 0 15' + self.maxs_z * '0 0 1');
		setattachment(self.chatbubbleentity, self, "");  // sticks to moving player better, also conserves bandwidth
		self.chatbubbleentity.mdl = self.chatbubbleentity.model;
		self.chatbubbleentity.model = "";
		self.chatbubbleentity.effects = EF_LOWPRECISION;
	}
}


void respawn(void)
{
	CopyBody(1);
	self.effects |= EF_NODRAW; // prevent another CopyBody
	PutClientInServer();
}

/**
 * When sv_timeout is used this function returs strings like
 * "Timeout begins in 2 seconds!\n" or "Timeout ends in 23 seconds!\n".
 * Called by centerprint functions
 * @param addOneSecond boolean, set to 1 if the welcome-message centerprint asks for the text
 */
string getTimeoutText(float addOneSecond) {
	if (!sv_timeout || !timeoutStatus)
		return "";

	local string retStr;
	if (timeoutStatus == 1) {
		if (addOneSecond == 1) {
			retStr = strcat("Timeout begins in ", ftos(remainingLeadTime + 1), " seconds!\n");
		}
		else {
			retStr = strcat("Timeout begins in ", ftos(remainingLeadTime), " seconds!\n");
		}
		return retStr;
	}
	else if (timeoutStatus == 2) {
		if (addOneSecond) {
			retStr = strcat("Timeout ends in ", ftos(remainingTimeoutTime + 1), " seconds!\n");
			//don't show messages like "Timeout ends in 0 seconds"...
			if ((remainingTimeoutTime + 1) > 0)
				return retStr;
			else
				return "";
		}
		else {
			retStr = strcat("Timeout ends in ", ftos(remainingTimeoutTime), " seconds!\n");
			//don't show messages like "Timeout ends in 0 seconds"...
			if (remainingTimeoutTime > 0)
				return retStr;
			else
				return "";
		}
	}
	else return "";
}

float CalcRegen(float current, float stable, float regenfactor, float regenframetime)
{
	if(current > stable)
		return current;
	else if(current > stable - 0.25) // when close enough, "snap"
		return stable;
	else
		return min(stable, current + (stable - current) * regenfactor * regenframetime);
}

float CalcRot(float current, float stable, float rotfactor, float rotframetime)
{
	if(current < stable)
		return current;
	else if(current < stable + 0.25) // when close enough, "snap"
		return stable;
	else
		return max(stable, current + (stable - current) * rotfactor * rotframetime);
}

float CalcRotRegen(float current, float regenstable, float regenfactor, float regenlinear, float regenframetime, float rotstable, float rotfactor, float rotlinear, float rotframetime, float limit)
{
	if(current > rotstable)
	{
		if(rotframetime > 0)
		{
			current = CalcRot(current, rotstable, rotfactor, rotframetime);
			current = max(rotstable, current - rotlinear * rotframetime);
		}
	}
	else if(current < regenstable)
	{
		if(regenframetime > 0)
		{
			current = CalcRegen(current, regenstable, regenfactor, regenframetime);
			current = min(regenstable, current + regenlinear * regenframetime);
		}
	}

	if(current > limit)
		current = limit;

	return current;
}

void player_regen (void)
{
	float minh, maxh, limith, limita;
	GameHook_HealthArmorRotRegen = GameHook_HealthMaxMod = GameHook_ArmorHealthLimitMod = GameHook_RegenMod = GameHook_RotMod = 1;
	GameHookChain_HealthArmorFuelModsSet();
	if (GameHook_HealthArmorRotRegen)
	{
		limith = g_balance_health_limit * GameHook_ArmorHealthLimitMod;
		maxh = g_balance_health_rotstable * GameHook_HealthMaxMod;
		minh = g_balance_health_regenstable * GameHook_HealthMaxMod;
		self.health = CalcRotRegen(self.health, minh, g_balance_health_regen, g_balance_health_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished), maxh, g_balance_health_rot, g_balance_health_rotlinear, GameHook_RotMod * frametime * (time > self.pauserothealth_finished), limith);
		// if player rotted to death...  die!
		if(self.health < 1)
			self.event_damage(self, self, 1, DEATH_ROT, self.origin, '0 0 0');
		limita = g_balance_armor_limit * GameHook_ArmorHealthLimitMod;
		self.armorvalue = CalcRotRegen(self.armorvalue, g_balance_armor_regenstable, g_balance_armor_regen, g_balance_armor_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished), g_balance_armor_rotstable, g_balance_armor_rot, g_balance_armor_rotlinear, GameHook_RotMod * frametime * (time > self.pauserotarmor_finished), limita);

	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel = CalcRotRegen(self.ammo_fuel, g_balance_fuel_regenstable, g_balance_fuel_regen, g_balance_fuel_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished) * (self.items & IT_FUEL_REGEN != 0), g_balance_fuel_rotstable, g_balance_fuel_rot, g_balance_fuel_rotlinear, GameHook_RotMod * frametime * (time > self.pauserotfuel_finished), g_balance_fuel_limit);
}

void GetPressedKeys(void) {
	if (self.movement_x > 0) // get if movement keys are pressed
	{	// forward key pressed
		self.pressedkeys |= KEY_FORWARD;
		self.pressedkeys &~= KEY_BACKWARD;
	}
	else if (self.movement_x < 0)
	{	// backward key pressed
		self.pressedkeys |= KEY_BACKWARD;
		self.pressedkeys &~= KEY_FORWARD;
	}
	else
	{	// no x input
		self.pressedkeys &~= KEY_FORWARD;
		self.pressedkeys &~= KEY_BACKWARD;
	}

	if (self.movement_y > 0)
	{	// right key pressed
		self.pressedkeys |= KEY_RIGHT;
		self.pressedkeys &~= KEY_LEFT;
	}
	else if (self.movement_y < 0)
	{	// left key pressed
		self.pressedkeys |= KEY_LEFT;
		self.pressedkeys &~= KEY_RIGHT;
	}
	else
	{	// no y input
		self.pressedkeys &~= KEY_RIGHT;
		self.pressedkeys &~= KEY_LEFT;
	}

	if (self.BUTTON_JUMP) // get if jump and crouch keys are pressed
		self.pressedkeys |= KEY_JUMP;
	else
		self.pressedkeys &~= KEY_JUMP;
	if (self.BUTTON_CROUCH)
		self.pressedkeys |= KEY_CROUCH;
	else
		self.pressedkeys &~= KEY_CROUCH;
}

/*
======================
spectate mode routines
======================
*/
void SpectateCopy(entity spectatee) {
	GameHookChain_SpectateCopy(spectatee);
	self.armortype = spectatee.armortype;
	self.armorvalue = spectatee.armorvalue;
	self.ammo_cells = spectatee.ammo_cells;
	self.ammo_shells = spectatee.ammo_shells;
	self.ammo_nails = spectatee.ammo_nails;
	self.ammo_rockets = spectatee.ammo_rockets;
	self.ammo_fuel = spectatee.ammo_fuel;
	self.effects = spectatee.effects & EFMASK_CHEAP; // eat performance
	self.health = spectatee.health;
	self.impulse = 0;
	self.items = spectatee.items;
	self.pressedkeys = spectatee.pressedkeys;
	self.weapons = spectatee.weapons;
	self.switchweapon = spectatee.switchweapon;
	self.weapon = spectatee.weapon;
	self.punchangle = spectatee.punchangle;
	self.view_ofs = spectatee.view_ofs;
	self.v_angle = spectatee.v_angle;
	self.velocity = spectatee.velocity;
	self.dmg_take = spectatee.dmg_take;
	self.dmg_save = spectatee.dmg_save;
	self.dmg_inflictor = spectatee.dmg_inflictor;
	self.angles = spectatee.v_angle;
	self.fixangle = TRUE;
	setorigin(self, spectatee.origin);
	setsize(self, spectatee.mins, spectatee.maxs);
}

float SpectateUpdate() {
	if(!self.enemy)
		return 0;

	if (self == self.enemy)
		return 0;

	if(self.enemy.classname != "player")
		return 0;

	SpectateCopy(self.enemy);

	return 1;
}

float SpectateNext() {
	other = self.enemy;
	do
		other = find(other, classname, "player");
	while (other && self.team > 0 && other.team != self.team);
	if (!other) {
		do
			if (other == self.enemy)
				break;
			else
				other = find(other, classname, "player");
		while (other && self.team > 0 && other.team != self.team);
	}
	if (other) {
		self.enemy = other;
	}
	if(self.enemy.classname == "player") {
		ClientSetView(self.enemy);
		self.movetype = MOVETYPE_NONE;
		SpectateCopy(self.enemy);
		spectator_note.SendFlags = 1;
		return 1;
	} else {
		return 0;
	}
}

/*
=============
ShowRespawnCountdown()

Update a respawn countdown display.
=============
*/
void ShowRespawnCountdown()
{
	float number;
	if(self.deadflag == DEAD_NO) // just respawned?
		return;
	else
	{
		number = ceil(self.death_time - time);
		if(number <= 0)
			return;
		if(number <= self.respawn_countdown)
		{
			self.respawn_countdown = number - 1;
			if(ceil(self.death_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
				announce(self, strcat("announcer/robotic/", ftos(number), ".wav"));
		}
	}
}

void LeaveSpectatorMode()
{
	if(isJoinAllowed()) {
		if (GameHookChain_JoinHandle())
			return;

		if(!teamplay || g_campaign || g_balance_teams || (self.wasplayer && g_changeteam_banned) || self.team > 0) {
			self.classname = "player";
			if(g_campaign || g_balance_teams || g_balance_teams_force)
				JoinBestTeam(self, FALSE, TRUE);
			if(g_campaign)
				campaign_bots_may_start = 1;
			PutClientInServer();
			ScoreKeeper_Touch(self);
			if(self.classname == "player")
				bprint ("^4", self.netname, "^4 is playing now\n");
			if(!g_campaign)
				centerprint(self,""); // clear MOTD
			return;
		} else {
			//stuffcmd(self,"menu_showteamselect\n");
			msg_entity = self;
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_TEAMSELECT);
			return;
		}
	}
	else {
		//player may not join because of g_maxplayers is set
		centerprint_atprio(self, CENTERPRIO_MAPVOTE, PREVENT_JOIN_TEXT);
	}
}

/**
 * Determines whether the player is allowed to join. This depends on cvar
 * g_maxplayers, if it isn't used this function always return TRUE, otherwise
 * it checks whether the number of currently playing players exceeds g_maxplayers.
 * @return bool TRUE if the player is allowed to join, false otherwise
 */
float isJoinAllowed() {
	if (!g_maxplayers)
		return TRUE;

	local entity e;
	local float currentlyPlaying;
	FOR_EACH_REALPLAYER(e) {
		if(e.classname == "player")
			currentlyPlaying += 1;
	}
	if(currentlyPlaying < g_maxplayers)
		return TRUE;

	return FALSE;
}

/**
 * Checks whether the client is an observer or spectator, if so, he will get kicked after
 * g_maxplayers_spectator_blocktime seconds
 */
void checkSpectatorBlock() {
	if(self.classname == "spectator" || self.classname == "observer") {
		if( time > (self.spectatortime + g_maxplayers_spectator_blocktime) ) {
			sprint(self, "^7You were kicked from the server because you are spectator and spectators aren't allowed at the moment.\n");
			dropclient(self);
		}
	}
}

void ObserverThink()
{
	if (self.team > 0) {
		if (SpectateNext() == 1) {
			self.classname = "spectator";
			self.flags |= FL_JUMPRELEASED;
		}
	} else if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && !self.version_mismatch) {
			self.welcomemessage_time = 0;
			self.flags &~= FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK && !self.version_mismatch) {
			self.welcomemessage_time = 0;
			self.flags &~= FL_JUMPRELEASED;
			if(SpectateNext() == 1) {
				self.classname = "spectator";
			}
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_JUMP)) {
			self.flags |= FL_JUMPRELEASED;
			if(self.flags & FL_SPAWNING)
			{
				self.flags &~= FL_SPAWNING;
				LeaveSpectatorMode();
				return;
			}
		}
	}
	PrintWelcomeMessage(self);
}

void SpectatorThink()
{
	if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && !self.version_mismatch && self.team <= 0) {
			self.welcomemessage_time = 0;
			self.flags &~= FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK) {
			self.welcomemessage_time = 0;
			self.flags &~= FL_JUMPRELEASED;
			if(SpectateNext() == 1) {
				self.classname = "spectator";
			} else {
				self.classname = "observer";
				PutClientInServer();
			}
		} else if (self.BUTTON_ATCK2 && self.team <= 0) {
			self.welcomemessage_time = 0;
			PutObserverInServer(FALSE);
		} else {
			if(!SpectateUpdate())
				PutObserverInServer(FALSE);
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_ATCK2)) {
			self.flags |= FL_JUMPRELEASED;
			if (self.team <= 0)
			if (self.flags & FL_SPAWNING)
			{
				self.flags &~= FL_SPAWNING;
				LeaveSpectatorMode();
				return;
			}
		}
	}
	PrintWelcomeMessage(self);
	self.flags |= FL_CLIENT | FL_NOTARGET;
}

/*
=============
PlayerPreThink

Called every frame for each client before the physics are run
=============
*/
.float items_added;
void PlayerPreThink (void)
{
	self.stat_game_starttime = game_starttime;
	self.stat_leadlimit = leadlimit;

	if(blockSpectators && frametime)
		// WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
		checkSpectatorBlock();

	if(self.classname == "player") {
//		if(self.netname == "Wazat")
//			bprint(self.classname, "\n");

		CheckRules_Player();

		PrintWelcomeMessage(self);

		if (intermission_running)
		{
			IntermissionThink ();	// otherwise a button could be missed between
			return;					// the think tics
		}

		if(self.teleport_time)
		if(time > self.teleport_time)
		{
			self.teleport_time = 0;
			self.effects = self.effects - (self.effects & EF_NODRAW);
		}

		//don't allow the player to turn around while game is paused!
		if(timeoutStatus == 2) {
			self.v_angle = self.lastV_angle;
			self.angles = self.lastV_angle;
			self.fixangle = TRUE;
		}
		GameHookChain_PlayerPreThink();

		if(frametime) {
			Fire_ApplyDamage(self);
			player_effects();
		}
		if (PLAYER_REALLY_DEAD(self))
		{
			float button_pressed;
			if(frametime)
				player_anim();
			button_pressed = (self.BUTTON_ATCK || self.BUTTON_JUMP || self.BUTTON_ATCK2 || self.BUTTON_HOOK || self.BUTTON_USE);
			if (self.deadflag == DEAD_DYING)
			{
				if(g_forced_respawn)
					self.deadflag = DEAD_RESPAWNING;
				else if(!button_pressed)
					self.deadflag = DEAD_DEAD;
			}
			else if (self.deadflag == DEAD_DEAD)
			{
				if(button_pressed)
					self.deadflag = DEAD_RESPAWNABLE;
			}
			else if (self.deadflag == DEAD_RESPAWNABLE)
			{
				if(!button_pressed)
					self.deadflag = DEAD_RESPAWNING;
			}
			else if (self.deadflag == DEAD_RESPAWNING)
			{
				if(time > self.death_time)
				{
					self.death_time = time + 1; // only retry once a second
					respawn();
				}
			}
			ShowRespawnCountdown();
			return;
		}

		self.prevorigin = self.origin;

		FixPlayermodel();

		GrapplingHookFrame();

		W_WeaponFrame();
		Akimbo_WeaponFrame();
		if(frametime)
		{
			self.items &~= self.items_added;

			self.items_added = 0;
			if(self.items & IT_JETPACK)
				if(self.items & IT_FUEL_REGEN || self.ammo_fuel >= 0.01)
					self.items_added |= IT_FUEL;

			self.items |= self.items_added;
			player_regen();
			player_anim();
		}

		self.dmg_team = max(0, self.dmg_team - g_teamdamage_resetspeed * frametime);

		//self.angles_y=self.v_angle_y + 90;   // temp
	} else if(gameover) {
		if (intermission_running)
			IntermissionThink ();	// otherwise a button could be missed between
		return;
	} else if(self.classname == "observer") {
		ObserverThink();
	} else if(self.classname == "spectator") {
		SpectatorThink();
	}

	float oldspectatee_status;
	oldspectatee_status = self.spectatee_status & 255;
	if(self.classname == "spectator")
		self.spectatee_status = num_for_edict(self.enemy) | (self.enemy.BUTTON_ZOOM ? 256 : 0);
	else if(self.classname == "observer")
		self.spectatee_status = num_for_edict(self);
	else
		self.spectatee_status = (self.BUTTON_ZOOM ? 256 : 0);
	if((self.spectatee_status & 255) != (oldspectatee_status & 255))
	{
		GameHook_InitSpectator();
	}

	if(self.teamkill_soundtime)
	if(time > self.teamkill_soundtime)
	{
		self.teamkill_soundtime = 0;

		entity oldpusher, oldself;

		oldself = self; self = self.teamkill_soundsource;
		oldpusher = self.pusher; self.pusher = oldself;

		PlayerSound(playersound_teamshoot, CHAN_VOICE, VOICETYPE_LASTATTACKER_ONLY);

		self.pusher = oldpusher;
		self = oldself;
	}

	if(self.taunt_soundtime)
	if(time > self.taunt_soundtime)
	{
		self.taunt_soundtime = 0;
		PlayerSound(playersound_taunt, CHAN_VOICE, VOICETYPE_AUTOTAUNT);
	}

	target_voicescript_next(self);
}

/*
=============
PlayerPostThink

Called every frame for each client after the physics are run
=============
*/
.float idlekick_lasttimeleft;
void PlayerPostThink (void)
{
	// Savage: Check for nameless players
	if (strlen(strdecolorize(self.netname)) < 1) {
		self.netname = "Empty Name";
		//stuffcmd(self, "seta _cl_name Player\n");
	}

	if (frametime)
	if (clienttype(self) == CLIENTTYPE_REAL)
	{
		// WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
		float timeleft, drop, maxidle;
		if (sv_maxidle_forcespec && sv_spectate && self.classname == "player") {
			maxidle = sv_maxidle_forcespec;
			drop = FALSE;
		} else if (sv_maxidle) {
			maxidle = sv_maxidle;
			drop = TRUE;
		} else
			maxidle = 0;

		if (maxidle)
		if not(g_campaign)
		if not(GameHook_ForbidSpectators())
		if not(intermission_running) {
			timeleft = ceil(maxidle - (time - self.parm_idlesince));
			if (timeleft <= 0) {
				announce(self, "announcer/robotic/terminated.wav");
				if (drop) {
					bprint("^3", self.netname, "^3 was kicked for idling.\n");
					dropclient(self);
				} else {
					bprint("^3", self.netname, "^3 was moved to spectators for idling.\n");
					PlayerToSpec(self);
				}
				return;
			} else if(timeleft <= 10) {
				if(timeleft != self.idlekick_lasttimeleft)
				{
					centerprint_atprio(self, CENTERPRIO_IDLEKICK, strcat("^3Stop idling!\n^3", (drop ? "Disconnecting" : "Moving to spectators") , " in ", ftos(timeleft), "..."));
					announce(self, strcat("announcer/robotic/", ftos(timeleft), ".wav"));
				}
			} else
				centerprint_expire(self, CENTERPRIO_IDLEKICK);

			self.idlekick_lasttimeleft = timeleft;
		}
	}

	if(self.classname == "player") {
		CheckRules_Player();
		UpdateChatBubble();
		if (self.impulse)
			ImpulseCommands();
		if (intermission_running)
			return;		// intermission or finale

		GetPressedKeys();
	}

	/*
	float i;
	for(i = 0; i < 1000; ++i)
	{
		vector end;
		end = self.origin + '0 0 1024' + 512 * randomvec();
		tracebox(self.origin, self.mins, self.maxs, end, MOVE_NORMAL, self);
		if(trace_fraction < 1)
		if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		{
			print("I HIT SOLID: ", vtos(self.origin), " -> ", vtos(end), "\n");
			break;
		}
	}
	*/

	//pointparticles(particleeffectnum("machinegun_impact"), self.origin + self.view_ofs + '0 0 7', '0 0 0', 1);
}

void Client_ReadCvars()
{
	string s;
	CACHE_CVAR(g_spawn_furthest);
	CACHE_CVAR(sv_defaultcharacter);
	CACHE_CVAR(sv_defaultplayerskin);
	CACHE_CVAR(sv_defaultplayerskin_red);
	CACHE_CVAR(sv_defaultplayerskin_blue);
	CACHE_CVAR(sv_defaultplayerskin_yellow);
	CACHE_CVAR(sv_defaultplayerskin_pink);
	unzone_ifneeded(sv_defaultplayermodel);
	unzone_ifneeded(sv_defaultplayermodel_red);
	unzone_ifneeded(sv_defaultplayermodel_blue);
	unzone_ifneeded(sv_defaultplayermodel_yellow);
	unzone_ifneeded(sv_defaultplayermodel_pink);
	sv_defaultplayermodel = cvar_string_zone_ifneeded("sv_defaultplayermodel");
	sv_defaultplayermodel_red = cvar_string_zone_ifneeded("sv_defaultplayermodel_red");
	sv_defaultplayermodel_blue = cvar_string_zone_ifneeded("sv_defaultplayermodel_blue");
	sv_defaultplayermodel_yellow = cvar_string_zone_ifneeded("sv_defaultplayermodel_yellow");
	sv_defaultplayermodel_pink = cvar_string_zone_ifneeded("sv_defaultplayermodel_pink");
	s = cvar_string("sv_defaultplayercolors");
	if (s == "")
		sv_defaultplayercolors = -2;
	else
		sv_defaultplayercolors = stof(s);

	CACHE_CVAR(sv_servermodelsonly);
	CACHE_CVAR(sv_reset_on_join);
	CACHE_CVAR(g_teamdamage_resetspeed);
	CACHE_CVAR(g_forced_respawn);
	CACHE_CVAR(g_balance_armor_limit);
	CACHE_CVAR(g_balance_armor_regen);
	CACHE_CVAR(g_balance_armor_regenlinear);
	CACHE_CVAR(g_balance_armor_regenstable);
	CACHE_CVAR(g_balance_armor_rot);
	CACHE_CVAR(g_balance_armor_rotlinear);
	CACHE_CVAR(g_balance_armor_rotstable);
	CACHE_CVAR(g_balance_fuel_limit);
	CACHE_CVAR(g_balance_fuel_regen);
	CACHE_CVAR(g_balance_fuel_regenlinear);
	CACHE_CVAR(g_balance_fuel_regenstable);
	CACHE_CVAR(g_balance_fuel_rot);
	CACHE_CVAR(g_balance_fuel_rotlinear);
	CACHE_CVAR(g_balance_fuel_rotstable);
	CACHE_CVAR(g_balance_health_limit);
	CACHE_CVAR(g_balance_health_regen);
	CACHE_CVAR(g_balance_health_regenlinear);
	CACHE_CVAR(g_balance_health_regenstable);
	CACHE_CVAR(g_balance_health_rot);
	CACHE_CVAR(g_balance_health_rotlinear);
	CACHE_CVAR(g_balance_health_rotstable);
	CACHE_CVAR(g_balance_kill_delay);
	CACHE_CVAR(g_balance_pause_armor_rot_spawn);
	CACHE_CVAR(g_balance_pause_fuel_rot_spawn);
	CACHE_CVAR(g_balance_pause_health_regen_spawn);
	CACHE_CVAR(g_balance_pause_health_rot_spawn);
	CACHE_CVAR(g_changeteam_banned);
	CACHE_CVAR(g_maxplayers);
	CACHE_CVAR(g_maxplayers_spectator_blocktime);
	CACHE_CVAR(g_player_brightness);
	CACHE_CVAR(g_spawnshieldtime);
	CACHE_CVAR(g_spawnsound);
	CACHE_CVAR(leadlimit);
	CACHE_CVAR(sv_spectate);
	CACHE_CVAR(sv_timeout);
	CACHE_CVAR(sv_timeout_number);
	CACHE_CVAR(sv_maxidle);
	CACHE_CVAR(sv_maxidle_forcespec);
	if not(spectator_note) {
		spectator_note = NoteLine_New(Spectator_Note_Message);
		spectator_note.customizeentityforclient = Spectator_Note_Customize;
	}
}

void PutTeamToServer(float t) {
	entity e, oldself;
	FOR_EACH_CLIENT(e)
		if (e.team == t)
		if (e.classname != "player") {
			e.classname = "player";
			oldself = self;
			self = e;
			PutClientInServer();
			self = oldself;
		}
}

void Client_GetCvars() {
	stuffcmd(self, "sendcvar cl_retard\n"
			"sendcvar cl_autoswitch\n"
			"sendcvar cl_saboteur\n"
			"sendcvar cl_playerdetailreduction\n"
			"sendcvar scr_centertime\n"
			"sendcvar cl_gunalpha\n"
			"sendcvar cl_weaponpriority\n"
			"sendcvar cl_weaponpriority0\n"
			"sendcvar cl_weaponpriority1\n"
			"sendcvar cl_weaponpriority2\n"
			"sendcvar cl_weaponpriority3\n"
			"sendcvar cl_weaponpriority4\n"
			"sendcvar cl_weaponpriority5\n"
			"sendcvar cl_weaponpriority6\n"
			"sendcvar cl_weaponpriority7\n"
			"sendcvar cl_weaponpriority8\n"
			"sendcvar cl_weaponpriority9\n"
			"sendcvar cl_autotaunt\n"
			"sendcvar cl_voice_directional\n"
			"sendcvar cl_voice_directional_taunt_attenuation\n"
			"sendcvar cl_hitsound\n"
	);
#ifdef ALLOW_FORCEMODELS
	stuffcmd(self, "sendcvar cl_forceplayermodels\n"
			"sendcvar cl_forceplayermodelsfromnexuiz\n"
	);
#endif
	stuffcmd(self, "sendcvar cl_gunalign\n");
}

void Client_GetCvars_Parse() {
	string s = strcat1(argv(1));
	string val = strcat1(argv(2));
	if (s == "cl_retard") {
		if (stof(val)) {
			self.netname = retardplayername;
			self.retard = 1;
		}
	} else if (s == "cl_autoswitch")
		self.autoswitch = stof(val);
	else if (s == "cl_saboteur")
		self.saboteur = stof(val);
	else if (s == "cl_playerdetailreduction")
		self.cvar_cl_playerdetailreduction = stof(val);
	else if (s == "scr_centertime")
		self.cvar_scr_centertime = stof(val);
	else if (s == "cl_gunalpha")
		self.cvar_cl_gunalpha = stof(val);
	else if (s == "cl_weaponpriority") {
		unzone_ifneeded(self.cvar_cl_weaponpriority);
		self.cvar_cl_weaponpriority = strzone(W_FixWeaponOrder_ForceComplete(val));
		self.switchweapon = w_getbestweapon(self);
	} else if (substring(s, 0, 17) == "cl_weaponpriority") {
		float ind = stof(substring(s, 17, 1));
		unzone_ifneeded(self.cvar_cl_weaponpriorities[ind]);
		(self.cvar_cl_weaponpriorities[ind]) = strzone(W_FixWeaponOrder_AllowIncomplete(val));
	} else if (s == "cl_autotaunt")
		self.cvar_cl_autotaunt = stof(val);
	else if (s == "cl_voice_directional")
		self.cvar_cl_voice_directional = stof(val);
	else if (s == "cl_voice_directional_taunt_attenuation")
		self.cvar_cl_voice_directional_taunt_attenuation = stof(val);
	else if (s == "cl_hitsound")
		self.cvar_cl_hitsound = stof(val);
#ifdef ALLOW_FORCEMODELS
	else if (s == "cl_forceplayermodels")
		self.cvar_cl_forceplayermodels = stof(val);
	else if (s == "cl_forceplayermodelsfromnexuiz")
		self.cvar_cl_forceplayermodelsfromnexuiz = stof(val);
#endif
	else if (s == "cl_gunalign") {
		self.cvar_cl_gunalign = stof(val);
	}
}

void Client_GetCvars_Free() {
	unzone_ifneeded(self.cvar_cl_weaponpriority);
	self.cvar_cl_weaponpriority = "";
	float i;
	for (i = 0; i < 10; i++) {
		unzone_ifneeded(self.cvar_cl_weaponpriorities[i]);
		(self.cvar_cl_weaponpriorities[i]) = "";
	}
}
