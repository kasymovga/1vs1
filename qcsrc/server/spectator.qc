entity spectator_note;
var entity(entity e) spectator_camera_adjust_func;

#define spectator_note_customize Spectator_Note_Customize //compatibility with old save files
float(void) spectator_note_customize {
	if (other.classname == "player" && (other.clientcamera == other || clienttype(other.clientcamera) == CLIENTTYPE_NOTACLIENT))
		return FALSE;

	return TRUE;
}

#define spectator_note_message Spectator_Note_Message //compatibility with old save files
void(void) spectator_note_message {
	string s = "";
	if (SPECTATOR_IS_SPECTATOR(other)) {
		s = "^1Spectating ^7{1}\n^1Press ^3{+attack}^1 for another player";
		if (other.classname == "player")
			s = strcat(s, "\n^1Press ^3{+jump}^1 to stop spectating");
		else if (other.team <= 0 || !team_teams)
			s = strcat(s, "\n^1Press ^3{+attack2}^1 to observe");

		self.target = other.enemy.netname;
	} else if (other.classname == "observer") {
		s = "^1Observing";
		if (other.team <= 0 || !team_teams)
			s = strcat(s, "\n^1Press ^3{+attack}^1 to spectate");
	}
	s = strcat(s, "\n^1Game type is ^3{2}");
	self.target2 = game_type_title;
	if (other.team <= 0)
		s = strcat(s, "\n^1Press ^3{+jump}^1 to join");

	self.message = s;
}

void(void) spectator_impulse {
	if (self.impulse && self.impulse <= 19) {
		if (self.impulse == 10 || self.impulse == 15 || self.impulse == 18)
			self.spectatorspeed = bound(1, self.spectatorspeed + 0.5, 5);
		else if (self.impulse == 11)
			self.spectatorspeed = 1;
		else if (self.impulse == 12 || self.impulse == 16  || self.impulse == 19)
			self.spectatorspeed = bound(1, self.spectatorspeed - 0.5, 5);
		else if (self.impulse >= 1 && self.impulse <= 9)
			self.spectatorspeed = 1 + 0.5 * (self.impulse - 1);
	}
}

float(void) spectator_update {
	if not(self.enemy)
		return 0;

	if (self == self.enemy)
		return 0;

	if (self.enemy.classname != "player")
		return 0;

	return 1;
}

float() spectator_spectate_next {
	other = self.enemy;
	do
		other = find(other, classname, "player");
	while ((other == self) || (other && team_teams && self.team > 0 && other.team != self.team));
	if not(other) {
		do
			if (other == self.enemy)
				break;
			else
				other = find(other, classname, "player");
		while ((other == self) || (other && team_teams && self.team > 0 && other.team != self.team));
	}
	if (self.enemy) player_info_spec_update(self.enemy);
	if (other) {
		self.enemy = other;
		if (spectator_camera_adjust_func)
			self.clientcamera = spectator_camera_adjust_func(other);
		else
			self.clientcamera = other;

		if (self.clientcamera)
			self.clientdataent = self.clientcamera;
		else
			self.clientcamera = self.clientdataent = self.enemy;

		player_info_spec_update(other);
	}
	if (self.enemy) {
		spectator_note.SendFlags = 1;
		return 1;
	} else {
		return 0;
	}
}

void(void) spectator_player_stop {
	if (self.clientcamera == self) return;
	if (self.enemy)
		player_info_spec_update(self.enemy);

	self.enemy = NULL;
	self.clientcamera = self.clientdataent = self;
}

void(void) spectator_player_start {
	if (self.clientcamera != self) return;
	spectator_spectate_next();
}

void(entity(entity e) adjust_func) spectator_camera_adjust {
	entity cl;
	spectator_camera_adjust_func = adjust_func;
	entity camera;
	CLIENT_FOR_EACH(cl) {
		if (cl.classname == "spectator")
			camera = adjust_func(cl.clientcamera);
		else
			camera = adjust_func(cl);

		if (camera)
			cl.clientcamera = cl.clientdataent = camera;
	}
}

void(entity(entity e) adjust_func, entity camera) spectator_camera_unadjust {
	entity cl;
	if (spectator_camera_adjust_func == adjust_func)
		spectator_camera_adjust_func = NULL;

	CLIENT_FOR_EACH(cl)
		if (cl.clientcamera == camera) {
			if (cl.classname == "spectator")
				cl.clientcamera = cl.clientdataent = cl.enemy;
			else
				cl.clientcamera = cl.clientdataent = cl;
		}
}

void(void) spectator_camera_setup {
	entity e;
	if (spectator_camera_adjust_func) {
		e = spectator_camera_adjust_func(self);
		if not(e) e = self;
	} else
		e = self;

	self.clientcamera = self.clientdataent = e;
}

void(void) spectator_player_think {
	if (self.clientcamera == self) return;
	if (clienttype(self.clientcamera) == CLIENTTYPE_NOTACLIENT) return; //specing some non-player object
	entity oldenemy = self.enemy;
	if (self.BUTTON_ATCK && !self.delay) {
		if (spectator_spectate_next() != 1) {
			spectator_player_stop();
		}
	} else if (self.BUTTON_JUMP) {
		spectator_player_stop();
	} else if not(spectator_update()) {
		spectator_player_stop();
	}
	if (self.enemy != oldenemy)
		plugin_InitSpectator();

	self.delay = self.BUTTON_ATCK;
}

void() spectator_think {
	entity oldenemy = self.enemy;
	if (self.BUTTON_JUMP && self.team <= 0) {
		self.flags |= FL_SPAWNING;
	} else if (self.BUTTON_ATCK && !self.delay) {
		if (spectator_spectate_next() != 1) {
			spectator_observer_spawn(FALSE);
		}
	} else if (self.BUTTON_ATCK2 && (!team_teams || self.team <= 0)) {
		spectator_observer_spawn(FALSE);
	} else {
		if not(spectator_update()) {
			spectator_observer_spawn(FALSE);
		}
	}
	if not(self.BUTTON_ATCK || self.BUTTON_ATCK2 || self.BUTTON_JUMP) {
		if (self.team <= 0)
		if (self.flags & FL_SPAWNING) {
			self.flags &= ~FL_SPAWNING;
			spectator_to_player();
			return;
		}
	}
	if (self.enemy != oldenemy)
		plugin_InitSpectator();

	self.delay = self.BUTTON_ATCK;
}

void() spectator_observer_think {
	if (self.team > 0 && team_teams) {
		if (spectator_spectate_next() == 1) {
			self.classname = "spectator";
			spectator_think();
			return;
		}
	}
	if (self.BUTTON_JUMP && self.team <= 0) {
		self.flags |= FL_SPAWNING;
	} else if (self.BUTTON_ATCK) {
		if (spectator_spectate_next() == 1) {
			self.classname = "spectator";
		}
	} else {
		if (self.flags & FL_SPAWNING) {
			self.flags &= ~FL_SPAWNING;
			spectator_to_player();
			return;
		}
	}
}

void() spectator_to_player {
	if (client_join_allowed()) {
		self.parm_idlesince = time;
		if (plugin_chain_spectator_to_player_handle())
			return;

		team_teams_allowed(self);
		float skip_team_select = FALSE;
		if (team1 + team2 + team3 + team4 == -3) {
			skip_team_select = TRUE;
		}
		if (skip_team_select || !team_teams || g_campaign || g_balance_teams || (self.wasplayer && g_changeteam_banned) || self.team > 0) {
			self.dmg_inflictor = NULL;
			self.classname = "player";
			RM(score_player_set(self, SP_PLAYTIME, time - self.play_time);)
			if (g_campaign || g_balance_teams || g_balance_teams_force)
				team_join_best(self, TRUE);

			if (g_campaign)
				campaign_bots_may_start = 1;

			client_put();
			voip_setup(self);
			if (self.classname == "player") {
				print_all(PRINT_INFO, "^4{1}^4 is playing now", self.netname, "", "");
			}
			return;
		} else {
			msg_entity = self;
			net_write_byte(MSG_ONE, SVC_TEMPENTITY);
			net_write_byte(MSG_ONE, NET_TE_CSQC_TEAMSELECT);
			return;
		}
	}
}

void() spectator_note_update {
	spectator_note.SendFlags = 1;
}

void(float frags_team_reset) spectator_observer_spawn {
	entity spot;
	plugin_chain_observer_spawn();
	player_clear(FALSE);
	spot = find(world, classname, "info_intermission");
	if not(spot)
		spot = spawn_select(TRUE);

	if not(spot)
		error("No spawnpoints for observers?!?\n");

	if (frags_team_reset || self.team <= 0)
	if (self.killcount != -666)
		print_all(PRINT_INFO, "^4{1}^4 is spectating now", self.netname, "", "");

	if (frags_team_reset) {
		score_clear(self); // clear scores when needed
	}
	self.dmg_inflictor = NULL;
	self.spectatortime = time;
	self.classname = "observer";
	spectator_camera_setup();
	self.enemy = NULL;
	physics_set_view_offsets(self, PL_VIEW_OFS, PL_CROUCH_VIEW_OFS);
	self.spectatorspeed = 1;
	self.iscreature = FALSE;
	self.health = 1;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_QCWALK;
	self.flags = (FL_CLIENT | FL_NOTARGET);
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
	self.think = stdproc_nothing;
	self.nextthink = 0;
	self.clipgroup = 0;
	self.deadflag = DEAD_NO;
	client_put_to_spot(spot);
	self.items = 0;
	self.weapons = 0;
	player_body_remove();
	setmodel(self, "null");
	physics_set_sizes(self, PL_MIN, PL_MAX, PL_MIN, PL_MAX);
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
	self.delay = 0;
	spectator_note.SendFlags = 1;
	self.customizeentityforclient = NULL;
	if (frags_team_reset)
		self.team = -1;

	self.touch = NULL;
}

void() spectator_init {
	if not(spectator_note) {
		spectator_note = note_new(spectator_note_message);
		spectator_note.customizeentityforclient = spectator_note_customize;
	}
}
