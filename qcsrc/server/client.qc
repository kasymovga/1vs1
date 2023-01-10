float g_balance_kill_delay;
float g_changeteam_banned;
float g_maxplayers;
float g_voice_chat_public;
float sv_timeout_number;
float sv_maxidle;
float sv_maxidle_forcespec;
float sv_maxconnects_per_address;
float sv_foginterval;
float g_buttons_hookuse_swap;
float CLIENT_SCORE_VERSION;
float CLIENT_ABILITY_HOOKUSESWAP;
float client_ability_hookuseswap;

void(entity cl, vector a) client_view_angles_set {
	cl.v_angle = a;
	if (clienttype(cl) == CLIENTTYPE_REAL) {
		msg_entity = cl;
		net_write_byte(MSG_ONE, SVC_SETANGLE);
		net_write_angle(MSG_ONE, a_x);
		net_write_angle(MSG_ONE, a_y);
		net_write_angle(MSG_ONE, a_z);
	}
}

void(entity to) client_set_view {
	vector a = to.angles;
	a_z = 0;
	if not(clienttype(self) == CLIENTTYPE_REAL)
		return;

	msg_entity = self;
	net_write_byte(MSG_ONE, SVC_SETVIEW);
	net_write_entity(MSG_ONE, to);
}

void(entity spot) client_put_to_spot{
	self.deadflag = DEAD_NO;
	self.angles = spot.angles;
	self.angles_z = 0;
	self.crouch = FALSE;
	teleport_origin_set(self, spot.origin, 0);
	client_view_angles_set(self, self.angles);
	client_set_view(self);
}

.float just_connected;
void(void) client_put {
	if (self.just_connected) {
		self.team = -1;
		self.just_connected = FALSE;
		if (time + 5 < map_starttime)
			announce(self, "announcer/robotic/prepareforbattle.wav", "^3Prepare for Battle");
	}
	entity e;
	FOR_EACH_PLAYER(e)
		e.entcs.SendFlags |= 16;

	float oldteam = self.team;
	if (clienttype(self) == CLIENTTYPE_BOT) {
		self.classname = "player";
	}
	if (map_finished)
		self.classname = "observer";

	if (self.classname == "player") {
		entity spot;
		if (self.team < 0) {
			if (clienttype(self) == CLIENTTYPE_BOT)
				self.team = self.bot_forced_team;

			team_join_best(self, FALSE);
		}
		spot = plugin_client_put_spawn_point();
		if (!spot) {
			if (clienttype(self) == CLIENTTYPE_REAL)
				centerprint(self, "Sorry, no spawnpoints available!\nHope your team can fix it...");

			print(self.netname, " not have place to spawn\n");
			spectator_observer_spawn(FALSE);
		} else
			player_spawn(spot);
	} else if (self.classname == "observer") {
		spectator_observer_spawn(TRUE);
	}
	if (self.team != oldteam)
		score_touch(self);

}

float(entity to, float sf) client_init_send {
	float i, t;
	net_write_byte(MSG_ENTITY, NET_CSQC_INIT);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		weapon_info_send();
	}
	if (sf & 2) {
		t = 0;
		if (g_campaign)
			t |= 1;

		if (to.netaddress == "local")
			t |= 4;

		if (g_buttons_hookuse_swap)
			t |= 8;

		if (client_button_atck2_busy)
			t |= 16;

		if (g_recoil_extra)
			t |= 32;

		net_write_byte(MSG_ENTITY, t);
	}
	if (sf & 4) {
		if (sv_foginterval && client_fog != "")
			net_write_string(MSG_ENTITY, client_fog);
		else
			net_write_string(MSG_ENTITY, "");
	}
	if (sf & 8) {
		net_write_string(MSG_ENTITY, cvar_string("sv_vote_commands"));
	}
	if (sf & 16)
		game_menu_send();

	if (sf & 32) {
		net_write_byte(MSG_ENTITY, team_mode);
		t = 0;
		if (team_mode) {
			team_teams_allowed(self);
			if (team1 >= 0) t |= 1;
			if (team2 >= 0) t |= 2;
			if (team3 >= 0) t |= 4;
			if (team4 >= 0) t |= 8;
		}
		net_write_byte(MSG_ENTITY, t);
	}
	if (sf & 64) {
		projectile_info_send();
	}
	if (sf & 128) {
		net_write_string(MSG_ENTITY, map_description);
		string s;
		s = strcat("This is ^1Rexuiz^7 ", cvar_string("rexuizversion"));
		string profile = cvar_string("g_profile");
		if (profile != "")
			s = strcat(s, "\n^8g_profile ^3", profile, "^8");

		if (g_campaign)
			s = campaign_message;
		else {
			string motd = cvar_string("sv_motd");
			if (motd != "")
				s = strcat(s, "\n\n^8MOTD:\n^7", strreplace("\\n", "\n", cvar_string("sv_motd")));
		}
		net_write_string(MSG_ENTITY, s);
	}
	return TRUE;
}

entity client_init;
void() client_init_spawn {
	client_init = spawn();
	net_link_entity(client_init, FALSE, 0, client_init_send);
}

void(void) client_parms_new { //called by engine
	// initialize parms for a new player
	parm1 = -(86400 * 366);
	parm2 = 0;
	parm3 = 0;
	parm4 = 0;
	plugin_client_parms_new();
}

void(void) client_parms_change { //called by engine
	// save parms for level change
	parm1 = self.parm_idlesince - time;
	parm2 = self.muted;
	parm3 = self.ability_class;
	plugin_client_parms_change();
}

void(void) client_parms_decode {
	// load parms
	self.parm_idlesince = parm1;
	if (self.parm_idlesince == -(86400 * 366))
		self.parm_idlesince = time;

	if (parm2) {
		print("Client #", ftos(num_for_edict(self)), " muted by parm2\n");
		self.muted = TRUE;
	}
	self.ability_class = parm3;
	// whatever happens, allow 60 seconds of idling directly after connect for map loading
	self.parm_idlesince = max(self.parm_idlesince, time - sv_maxidle + 60);
	plugin_client_parms_decode();
	voip_setup(self);
}

void(entity cl, float _team) client_kill_now_team_change {
	if (_team == -2) {
		player_to_spec(cl);
	} else if (_team == -1) {
		cl.team = -1;
		team_join_best(cl, FALSE);
	} else
		team_change(cl, _team, FALSE);
}

void(entity cl, float _team) client_kill_now {
	if (_team)
		client_kill_now_team_change(cl, _team);
	else
		damage(cl, cl, cl, 100000, DEATH_KILL, cl.origin, '0 0 0');

	if (cl.killindicator) {
		remove(cl.killindicator);
		cl.killindicator = world;
	}
}

void(void) client_killindicator_think {
	if (self.owner.classname != "player") {
		self.owner.killindicator = world;
		remove(self);
		return;
	}
	if (self.cnt <= 0) {
		client_kill_now(self.owner, self.team);
		return;
	} else {
		if (self.cnt <= 10)
			setmodel(self, strcat("models/sprites/", ftos(self.cnt), ".spr32"));

		if (clienttype(self.owner) == CLIENTTYPE_REAL) {
			if (self.cnt <= 10)
				announce(self.owner, strcat("announcer/robotic/", ftos(self.cnt), ".wav"), "");

			if (self.owner.killindicator.team) {
				if (self.owner.killindicator.team == -1)
					centerprint(self.owner, strcat("Changing team in ", ftos(self.cnt), " seconds"));
				else
					centerprint(self.owner, strcat("Changing to ", team_colored_name(self.owner.killindicator.team), " in ", ftos(self.cnt), " seconds"));
			} else
				centerprint(self.owner, strcat("^1Suicide in ", ftos(self.cnt), " seconds"));
		}
		self.nextthink = time + 1;
		self.cnt -= 1;
	}
}

void(float destteam) client_team_change_kill {
	if not(self.killindicator) {
		if (g_balance_kill_delay <= 0 || self.classname != "player" || self.deadflag != DEAD_NO || team_fast_switch_allowed(self, destteam)) {
			client_kill_now(self, destteam);
		} else {
			self.killindicator = spawn();
			self.killindicator.owner = self;
			self.killindicator.scale = 0.5;
			self.killindicator.team = destteam;
			setattachment(self.killindicator, self, "");
			setorigin(self.killindicator, '0 0 52');
			self.killindicator.think = client_killindicator_think;
			self.killindicator.nextthink = time + (self.lip) * 0.05;
			self.killindicator.cnt = ceil(g_balance_kill_delay);
			self.killindicator.count = bound(0, ceil(g_balance_kill_delay), 10);
			sprint(self, strcat("^1You'll be dead in ", ftos(self.killindicator.cnt), " seconds\n"));
			self.lip = 0;
		}
	}
	if (self.killindicator) {
		self.killindicator.team = destteam;
		if (destteam)
			self.killindicator.colormod = team_color(destteam);
		else
			self.killindicator.colormod = '0 0 0';
	}
}

void(float destteam) client_team_change {
	float t, c0;
	if not(team_mode) {
		if (destteam >= 0)
			player_set_colors(self, destteam);

		return;
	}
	if (self.team <= 0)
	if (destteam > 0)
	if not(client_join_allowed()) {
		return;
	}
	if (self.classname == "player")
	if (destteam == -1) {
		team_teams_allowed(self);
		t = team_find_smallest(self);
		switch (self.team) {
		case COLOR_TEAM1: c0 = team1; break;
		case COLOR_TEAM2: c0 = team2; break;
		case COLOR_TEAM3: c0 = team3; break;
		case COLOR_TEAM4: c0 = team4; break;
		default:          c0 = 999;
		}
		switch (t) {
		case 1:
			if (c0 > team1)
				destteam = COLOR_TEAM1;

			break;
		case 2:
			if (c0 > team2)
				destteam = COLOR_TEAM2;

			break;
		case 3:
			if (c0 > team3)
				destteam = COLOR_TEAM3;

			break;
		case 4:
			if (c0 > team4)
				destteam = COLOR_TEAM4;

			break;
		}
		if (destteam == -1)
			return;
	}
	if (destteam == self.team && destteam >= 0 && !self.killindicator)
		return;

	client_team_change_kill(destteam);
}

void(void) client_kill { //called by engine, "kill" command
	client_team_change_kill(0);
}

void(entity e) client_fix_cvars{
	stuffcmd(e, strcat("\nin_bindmap 0 0\n", plugin_client_fix_cvars(), "\n"));
}

float() client_preconnect_abort {
	if (self.just_connected)
		return FALSE;

	if (ban_maybe_enforce(self))
		return TRUE;

	entity e;
	if (sv_maxconnects_per_address > 0) {
		float n;
		n = 0;
		FOR_EACH_CLIENT(e)
			if (e.netaddress == self.netaddress)
				n++;

		if (n + 1 > sv_maxconnects_per_address) {
			sprint(self, strcat("^1Connections limit for ", self.netaddress, " exceeded\n"));
			dropclient(self);
			return TRUE;
		}
	}
	self.just_connected = TRUE;
	self.team = -1;
	self.retard = -1;
	string tail = cvar_string("sv_retard_nets");
	string head;
	string address_check = strcat(self.netaddress, ".");
	if (self.netname == client_retardplayername)
		self.retard = 1;

	while (tail != "") {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "")
			continue;

		if (strstrofs(address_check, head, 0) == 0) {
			self.retard = 1;
			print("Retard connected with address ", address_check, " and pattern ", head, "\n");
			break;
		}
	}
	return FALSE;
}

float client_playerid_last;
void(void) client_connect { //called by engine
	if not(self.flags & FL_CLIENT) {
		if (client_preconnect_abort())
			return;

		self.flags = FL_CLIENT;
	}
	if (self.retard > 0)
		self.netname = client_retardplayername;

	client_parms_decode();
	self.disableclientprediction = -1;
	self.classname = "player_joining";
	self.team = -1; //clear engine assigned values
	if (player_count<0)
		player_count = 0;

	score_attach(self);
	if not(self.scorekeeper.rank)
		self.scorekeeper.rank = 1000;

	score_touch(self);
	self.play_time = 0;
	bot_clientconnect();
	if (g_campaign) {
		self.classname = "player";
		campaign_bots_may_start = 1;
	} else if (plugin_forbid_specatators()) {
		self.classname = "player";
	} else {
		self.classname = "observer";
	}
	self.playerid = (client_playerid_last = client_playerid_last + 1);
	//stuffcmd(self, "set tmpviewsize $viewsize \n");
	bprint ("^4", self.netname, "^4#", ftos(num_for_edict(self)) , " connected\n");
	stuffcmd(self, strcat(client_stuff, "\n"));
	stuffcmd(self, "cl_particles_reloadeffects\n");
	client_fix_cvars(self);
	// get other cvars from player
	client_cvars_request();
	entcs_attach();
	bot_relinkplayerlist();
	self.spectatortime = time;
	if (spectator_block) {
		sprint(self, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));
	}
	self.jointime = time;
	self.allowedTimeouts = sv_timeout_number;
	if (clienttype(self) == CLIENTTYPE_REAL) {
		if (!sv_foginterval && client_fog != "")
			stuffcmd(self, strcat("\nfog ", client_fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));

		plugin_chain_client_connect_real();
		vote_client_connect();
	}
	plugin_chain_client_connect();
}

void(void) client_disconnect { //called by engine
	if not(self.flags & FL_CLIENT) {
		print("Warning: client_disconnect without client_connect\n");
		return;
	}
	bot_clientdisconnect();
	entcs_detach();
	bprint ("^4",self.netname);
	bprint ("^4 disconnected\n");
	string s;
	if ((s = cvar_string("g_ragequit_message")) != "")
	if (clienttype(self) == CLIENTTYPE_REAL)
	if (time > map_starttime)
	if (!team_mode || team_teams > 1)
	if (!map_finished)
	if (self.classname == "player") {
		entity e;
		FOR_EACH_REALPLAYER(e) {
			if (e != self) {
				chat_print(strcat("^3* ", self.netname, " ", s, "\n"));
				break;
			}
		}
	}
	self.classname = "disconnecting";
	player_clear(FALSE);
	self.flags &= ~FL_CLIENT;
	self.just_connected = FALSE;
	self.team = -1;
	if (self.killindicator)
		remove (self.killindicator);

	WaypointSprite_PlayerGone();
	bot_relinkplayerlist();
	score_detach(self);
	if (self.clientstatus)
		strunzone(self.clientstatus);

	player_sound_clear();
	self.playerid = 0;
	self.retard = 0;
	self.saboteur = 0;
	self.stacker = 0;
	self.muted = 0;
	ready_count();
	client_cvars_free();
	if (clienttype(self) == CLIENTTYPE_REAL) {
		plugin_chain_client_disconnect_real();
		vote_client_connect();
	}
	if (team_mode) {
		team_balance_audit(FALSE);
	}
	player_leave();
}

/**
 * Determines whether the player is allowed to join. This depends on cvar
 * g_maxplayers, if it isn't used this function always return TRUE, otherwise
 * it checks whether the number of currently playing players exceeds g_maxplayers.
 * @return bool TRUE if the player is allowed to join, false otherwise
 */
float() client_join_allowed {
	if (team_mode)
	if (team_teams > 1)
	if (self.saboteur > 1)
		return FALSE;

	if (map_finished)
		return FALSE;

	if (!g_maxplayers)
		return TRUE;

	entity e = NULL;
	float currentlyPlaying = 0;
	FOR_EACH_REALCLIENT(e) {
		if (e != self) //avoid wrong self-counting in teamplay
		if (e.classname == "player" || (team_mode && e.team > 0))
			currentlyPlaying += 1;
	}
	if (currentlyPlaying < g_maxplayers)
		return TRUE;

	centerprint_atprio(self, CENTERPRINT_PRIO_MAPVOTE, "^1You may not join the game at this time.\n\nThe player limit reached maximum capacity.");
	return FALSE;
}

/**
 * Checks whether the client is an observer or spectator, if so, he will get kicked after
 * g_maxplayers_spectator_blocktime seconds
 */
void(void) client_check_spectator_block {
	if (self.classname == "spectator" || self.classname == "observer") {
		if (time > (self.spectatortime + g_maxplayers_spectator_blocktime)) {
			sprint(self, "^7You were kicked from the server because you are spectator and spectators aren't allowed at the moment.\n");
			dropclient(self);
		}
	}
}

void(void) client_pre_think { //called by engine
	if (client_ability_hookuseswap) {
		if ((self.abilities & CLIENT_ABILITY_HOOKUSESWAP) || g_buttons_hookuse_swap) {
			BUTTON_HOOK = buttonuse;
			BUTTON_USE = button6;
		} else {
			BUTTON_HOOK = button6;
			BUTTON_USE = buttonuse;
		}
	}
	if (frametime) {
		if (warmup_active)
			self.stat_map_starttime = time;
		else
			self.stat_map_starttime = map_starttime;
	}
	self.stat_leadlimit = score_leadlimit;
	if (spectator_block && frametime)
		// WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
		client_check_spectator_block();

	if (map_intermission_running) {
		return;
	}
	if (self.classname == "player") {
		player_think();
		self.spectatee_status = (self.BUTTON_ZOOM ? 256 : 0);
	} else if (self.classname == "observer") {
		spectator_observer_think();
		self.spectatee_status = num_for_edict(self);
	} else if (self.classname == "spectator") {
		spectator_think();
	}
}

.float idlekick_lasttimeleft;
void(void) client_post_think { //called by engine
	// Savage: Check for nameless players
	string s = strdecolorize(self.netname);
	s = strreplace(" ", "", s);
	s = strreplace(" ", "", s);
	s = strreplace("", "", s);
	if (strlen(strdecolorize(s)) < 1) {
		self.netname = "Empty Name";
		//stuffcmd(self, "seta _cl_name Player\n");
	}
	if (frametime)
	if (clienttype(self) == CLIENTTYPE_REAL && (self.classname == "player" || self.team < 0)) {
		// WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
		float timeleft, drop = FALSE, maxidle;
		if (sv_maxidle_forcespec && self.classname == "player") {
			maxidle = sv_maxidle_forcespec;
		} else if (sv_maxidle) {
			maxidle = sv_maxidle;
			drop = TRUE;
		} else
			maxidle = 0;

		if (maxidle)
		if not(g_campaign)
		if not(plugin_forbid_specatators())
		if not(map_intermission_running) {
			timeleft = ceil(maxidle - (time - self.parm_idlesince));
			if (timeleft <= 0) {
				announce(self, "announcer/robotic/terminated.wav", "^1Terminated");
				if (drop) {
					bprint("^3", self.netname, "^3 was kicked for idling.\n");
					dropclient(self);
				} else {
					bprint("^3", self.netname, "^3 was moved to spectators for idling.\n");
					player_to_spec(self);
				}
				return;
			} else if (timeleft <= 10) {
				if (timeleft != self.idlekick_lasttimeleft) {
					centerprint_atprio(self, CENTERPRINT_PRIO_IDLEKICK, strcat("^3Stop idling!\n^3", (drop ? "Disconnecting" : "Moving to spectators") , " in ", ftos(timeleft), "..."));
					announce(self, strcat("announcer/robotic/", ftos(timeleft), ".wav"), "");
				}
			} else
				centerprint_expire(self, CENTERPRINT_PRIO_IDLEKICK);

			self.idlekick_lasttimeleft = timeleft;
		}
	}
	if (self.impulse) {
		if (map_finished) {
			map_vote_impulse();
		} else if (self.classname == "player")
			player_impulse();
		else if (self.classname == "observer") {
			spectator_impulse();
		}
		self.impulse = 0;
	}
	if (self.classname == "player")
		player_post_think();
}

void(entity e, string args, float set) client_ability_hookuseswap_init {
	if not(e)
		client_ability_hookuseswap = TRUE;
}

void() client_initialize {
	if not(client_retardplayername)
		client_retardplayername = strzone(cvar_string("sv_retardplayername"));

	CVAR_CACHE(g_balance_kill_delay);
	CVAR_CACHE(g_changeteam_banned);
	CVAR_CACHE(g_maxplayers);
	CVAR_CACHE(g_maxplayers_spectator_blocktime);
	CVAR_CACHE(g_voice_chat_public);
	voip_setup_all();
	CVAR_CACHE(sv_timeout_number);
	CVAR_CACHE(sv_maxidle);
	CVAR_CACHE(sv_maxidle_forcespec);
	CVAR_CACHE(sv_maxconnects_per_address);
	CVAR_CACHE(g_buttons_hookuse_swap);
	CVAR_CACHE(sv_foginterval);
	if (client_fog == "")
		client_fog = world.fog;

	if (g_buttons_hookuse_swap) {
		BUTTON_HOOK = buttonuse;
		BUTTON_USE = button6;
	} else {
		BUTTON_HOOK = button6;
		BUTTON_USE = buttonuse;
	}
	CLIENT_ABILITY_HOOKUSESWAP = ability_register("hookuseswap", client_ability_hookuseswap_init);
	client_version_init();
}

void client_cvars_request() {
	stuffcmd(self,
			"sendcvar cl_autoswitch\n"
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
			"sendcvar cl_voice\n"
			"sendcvar cl_netfps\n"
			"sendcvar cl_simpleitems\n"
			"sendcvar _cl_rate\n"
			"sendcvar voipvolume\n"
	);
	stuffcmd(self, "sendcvar cl_gunalign\n");
	stuffcmd(self, "sendcvar cl_gunalign_force_center\n");
	stuffcmd(self, "sendcvar cl_showweaponspawns\n");
	stuffcmd(self, "sendcvar _cl_id\n");
}

void() client_cvars_parse {
	string s = strcat1(argv(1));
	string val = strcat1(argv(2));
	float f;
	if (s == "cl_autoswitch")
		self.autoswitch = stof(val);
	else if (s == "cl_playerdetailreduction")
		self.cvar_cl_playerdetailreduction = stof(val);
	else if (s == "scr_centertime")
		self.cvar_scr_centertime = stof(val);
	else if (s == "cl_gunalpha")
		self.cvar_cl_gunalpha = stof(val);
	else if (s == "cl_weaponpriority") {
		str_unzone_ifneeded(self.cvar_cl_weaponpriority);
		self.cvar_cl_weaponpriority = str_zone_ifneeded(weapon_fix_order_force_complete(val));
		self.switchweapon = weapon_best(self);
	} else if (substring(s, 0, 17) == "cl_weaponpriority") {
		float ind = stof(substring(s, 17, 1));
		str_unzone_ifneeded(self.cvar_cl_weaponpriorities[ind]);
		(self.cvar_cl_weaponpriorities[ind]) = str_zone_ifneeded(weapon_fix_order_allow_incomplete(val));
	} else if (s == "cl_autotaunt")
		self.cvar_cl_autotaunt = stof(val);
	else if (s == "cl_voice") {
		f = stof(val);
		if (f <= 0) {
			self.cvar_cl_voice_directional = -1;
		} else {
			stuffcmd(self,
					"sendcvar cl_voice_directional\n"
					"sendcvar cl_voice_directional_taunt_attenuation\n");
			self.cvar_cl_voice_directional = 0;
		}
	} else if (s == "cl_voice_directional") {
		if (self.cvar_cl_voice_directional >= 0)
			self.cvar_cl_voice_directional = stof(val);
	} else if (s == "cl_voice_directional_taunt_attenuation")
		self.cvar_cl_voice_directional_taunt_attenuation = stof(val);
	else if (s == "cl_gunalign") {
		self.cvar_cl_gunalign = (stof(val) & 7) + (self.cvar_cl_gunalign & 8);
		if (self.weaponentity)
			self.weaponentity.cnt = 0;
	} else if (s == "cl_gunalign_force_center") {
		if (stof(val))
			self.cvar_cl_gunalign = self.cvar_cl_gunalign | 8;
		else
			self.cvar_cl_gunalign = self.cvar_cl_gunalign & 7;

		if (self.weaponentity)
			self.weaponentity.cnt = 0;
	} else if (s == "cl_simpleitems") {
		self.cvar_cl_simpleitems = stof(val);
	} else if (s == "cl_netfps") {
		f = stof(val);
		float reqfps = ceil(max(1.5 / sys_ticrate, 1.8 / cvar("sv_clmovement_inputtimeout")));
		if (f < reqfps) {
			stuffcmd(self, strcat("seta cl_netfps ", ftos(reqfps), "\n"));
		}
	} else if (s == "cl_showweaponspawns") {
		self.cvar_cl_showweaponspawns = stof(val);
	} else if (s == "_cl_rate") {
		f = stof(val);
		float reqrate = ceil(max(1.5 / sys_ticrate, 1.8 / cvar("sv_clmovement_inputtimeout"))) * 125;
		if (f < reqrate)
			stuffcmd(self, strcat("rate ", ftos(reqrate), "\n"));
	} else if (s == "_cl_id" && self.clid == "") {
		if (strlen(val) == 16) {
			self.clid = strzone(val);
		} else {
			self.clid = strftime(TRUE, "%y%m%d%H%M%S");
			for (f = 0; f < 4; f++) {
				self.clid = strcat(self.clid, DIGIT_DEC_TO_HEX(floor(random() * 16)));
			}
			self.clid = strzone(self.clid);
			stuffcmd(self, strcat("seta _cl_id ", self.clid, "\n"));
		}
		if (self.scorekeeper) {
			rank_load();
		}
	} else if (s == "voipvolume") {
		if (stof(val) > 0) {
			voip_enable(self);
		} else
			voip_disable(self);
	}
}

void() client_cvars_free {
	str_unzone_ifneeded(self.cvar_cl_weaponpriority);
	self.cvar_cl_weaponpriority = "";
	float i;
	for (i = 0; i < 10; i++) {
		str_unzone_ifneeded(self.cvar_cl_weaponpriorities[i]);
		(self.cvar_cl_weaponpriorities[i]) = "";
	}
	str_unzone_ifneeded(self.clid);
	self.clid = "";
}

void(string _name) client_mute_ifneeded {
	string s;
	float i;
	for (i = 0; ; ++i) {
		s = cvar_string(strcat("sv_player_mute_namepattern", ftos(i)));
		if (s == "")
			break;

		if (strstrofs(strdecolorize(_name), s, 0) >= 0) {
			print(_name, " muted with pattern ", s, "\n");
			self.muted = TRUE;
			voip_setup(self);
		}
	}
}

entity(float tokens, float idx) client_entity_from_argv {
	string s;
	entity e = NULL, head;
	float n;
	s = NULL;
	client_entity_from_argv_firsttoken = -1;
	if (tokens > idx) {
		if (substring(argv(idx), 0, 1) == "#") {
			s = substring(argv(idx), 1, -1);
			++idx;
			if (s == "")
				if (tokens > idx) {
					s = argv(idx);
					++idx;
				}
			client_entity_from_argv_firsttoken = idx;
			if (s == ftos(stof(s))) {
				e = edict_num(stof(s));
				if (e.flags & FL_CLIENT)
					return e;
			}
		} else {
			// it must be a nick name
			s = argv(idx);
			++idx;
			client_entity_from_argv_firsttoken = idx;
			n = 0;
			FOR_EACH_CLIENT(head)
			if (head.netname == s) {
				e = head;
				++n;
			}
			if (n == 1)
				return e;

			s = strdecolorize(s);
			n = 0;
			FOR_EACH_CLIENT(head)
			if (strdecolorize(head.netname) == s) {
				e = head;
				++n;
			}
			if (n == 1)
				return e;
		}
	}
	return world;
}

void(entity pl, float tstart, float dt) client_write_recordmarker {
	// also write a marker into demo files for demotc-race-record-extractor to find
	stuffcmd(pl, strcat( strcat("//", strconv(2, 0, 0, game_type_name(game_type)), " RECORD SET ", TIME_ENCODED_TOSTRING(TIME_ENCODE(dt))),
			" ", ftos(tstart), " ", ftos(dt), "\n"));
}
