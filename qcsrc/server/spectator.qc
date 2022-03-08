entity spectator_note;

#define spectator_note_customize Spectator_Note_Customize //compatibility with old save files
float(void) spectator_note_customize {
	if (other.classname == "player")
		return FALSE;

	return TRUE;
}

#define spectator_note_message Spectator_Note_Message //compatibility with old save files
void(void) spectator_note_message {
	string s = "";
	if (other.classname == "spectator") {
		s = strcat("^1Spectating ^7", strreplace("{", "{}", other.enemy.netname), "\n^1Press ^3{+attack}^1 for another player\n^1Press ^3{+attack2}^1 to observe");
	} else if (other.classname == "observer")
		s = "^1Observing\n^1Press ^3{+attack}^1 to spectate";

	s = strcat(s, "\n^1Game type is ^3", MapInfo_HumanString_FromType(gametype));
	if (other.team <= 0)
		s = strcat(s, "\n^1Press ^3{+jump}^1 to join");

	self.message = s;
}

void(entity spectatee) spectator_copy {
	gamehook_chain_spectator_copy(spectatee);
	self.armortype = spectatee.armortype;
	self.armorvalue = spectatee.armorvalue;
	self.ammo_cells = spectatee.ammo_cells;
	self.ammo_shells = spectatee.ammo_shells;
	self.ammo_nails = spectatee.ammo_nails;
	self.ammo_rockets = spectatee.ammo_rockets;
	self.ammo_fuel = spectatee.ammo_fuel;
	self.effects = spectatee.effects & EFFECT_MASK_CHEAP; // eat performance
	self.health = spectatee.health;
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

	spectator_copy(self.enemy);
	return 1;
}

float() spectator_spectate_next {
	other = self.enemy;
	do
		other = find(other, classname, "player");
	while (other && self.team > 0 && other.team != self.team);
	if not(other) {
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
	if (self.enemy.classname == "player") {
		client_set_view(self.enemy);
		self.movetype = MOVETYPE_NONE;
		spectator_copy(self.enemy);
		spectator_note.SendFlags = 1;
		return 1;
	} else {
		return 0;
	}
}

void() spectator_think {
	if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && self.team <= 0) {
			self.flags &= ~FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if (self.BUTTON_ATCK) {
			self.flags &= ~FL_JUMPRELEASED;
			if (spectator_spectate_next() == 1) {
				self.classname = "spectator";
			} else {
				self.classname = "observer";
				self.dmg_inflictor = NULL;
				client_put();
			}
		} else if (self.BUTTON_ATCK2 && self.team <= 0) {
			spectator_observer_spawn(FALSE);
		} else {
			if not(spectator_update())
				spectator_observer_spawn(FALSE);
		}
	} else {
		if not(self.BUTTON_ATCK || self.BUTTON_ATCK2) {
			self.flags |= FL_JUMPRELEASED;
			if (self.team <= 0)
			if (self.flags & FL_SPAWNING) {
				self.flags &= ~FL_SPAWNING;
				spectator_to_player();
				return;
			}
		}
	}
	self.flags |= FL_CLIENT | FL_NOTARGET;
	float oldspectatee_status;
	oldspectatee_status = self.spectatee_status & 255;
	self.spectatee_status = num_for_edict(self.enemy) | (self.enemy.BUTTON_ZOOM ? 256 : 0);
	if ((self.spectatee_status & 255) != (oldspectatee_status & 255))
		gamehook_InitSpectator();
}

void() spectator_observer_think {
	if (self.team > 0) {
		if (spectator_spectate_next() == 1) {
			self.classname = "spectator";
			self.flags |= FL_JUMPRELEASED;
		}
	} else if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP) {
			self.flags &= ~FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if (self.BUTTON_ATCK) {
			self.flags &= ~FL_JUMPRELEASED;
			if (spectator_spectate_next() == 1) {
				self.classname = "spectator";
			}
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_JUMP)) {
			self.flags |= FL_JUMPRELEASED;
			if (self.flags & FL_SPAWNING) {
				self.flags &= ~FL_SPAWNING;
				spectator_to_player();
				return;
			}
		}
	}
}

void() spectator_to_player {
	if (client_join_allowed()) {
		self.parm_idlesince = time;
		if (gamehook_chain_spectator_to_player_handle())
			return;

		team_teams_allowed(self);
		float skip_team_select = FALSE;
		if (team1 + team2 + team3 + team4 == -3) {
			skip_team_select = TRUE;
		}
		if (skip_team_select || !team_mode || g_campaign || g_balance_teams || (self.wasplayer && g_changeteam_banned) || self.team > 0) {
			self.dmg_inflictor = NULL;
			self.classname = "player";
			if (g_campaign || g_balance_teams || g_balance_teams_force)
				team_join_best(self, TRUE);

			if (g_campaign)
				campaign_bots_may_start = 1;

			client_put();
			if (self.classname == "player")
				bprint ("^4", self.netname, "^4 is playing now\n");

			if not(g_campaign)
				centerprint(self,""); // clear MOTD

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
	gamehook_chain_observer_spawn();
	player_clear(FALSE);
	spot = find(world, classname, "info_intermission");
	if not(spot)
		spot = spawn_select(TRUE);

	if not(spot)
		error("No spawnpoints for observers?!?\n");

	if (frags_team_reset || self.team <= 0)
	if (self.killcount != -666)
		bprint ("^4", self.netname, "^4 is spectating now\n");

	if (self.team >= 0) {
		score_clear(self); // clear scores when needed
	}
	self.spectatortime = time;
	self.classname = "observer";
	physics_set_view_offsets(self, PL_VIEW_OFS, PL_CROUCH_VIEW_OFS);
	self.spectatorspeed = 1;
	self.iscreature = FALSE;
	self.health = 1;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_TRIGGER;
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
	self.think = stdproc_nothing;
	self.nextthink = 0;
	client_put_to_spot(spot);
	setsize (self, '0 0 0', '0 0 0');
	self.items = 0;
	self.weapons = 0;
	player_body_remove();
	setmodel(self, "null");
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
	self.customizeentityforclient = NULL;
	if not(frags_team_reset)
		return;

	if (self.team != -1) {
		self.team = -1;
	}
	self.touch = NULL;
}

void() spectator_init {
	if not(spectator_note) {
		spectator_note = noteline_new(spectator_note_message);
		spectator_note.customizeentityforclient = spectator_note_customize;
	}
}
