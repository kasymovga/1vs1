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

	s = strcat(s, "\n^1Game type is ^3", MapInfo_HumanString_FromType(game));
	if (other.team <= 0)
		s = strcat(s, "\n^1Press ^3{+jump}^1 to join");

	self.message = s;
}

/*
======================
spectate mode routines
======================
*/
void spectator_spectate_copy(entity spectatee) {
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

	spectator_spectate_copy(self.enemy);
	return 1;
}

float() spectator_spectate_next {
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
		spectator_spectate_copy(self.enemy);
		spectator_note.SendFlags = 1;
		return 1;
	} else {
		return 0;
	}
}

void() spectator_think {
	if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && self.team <= 0) {
			self.flags &~= FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK) {
			self.flags &~= FL_JUMPRELEASED;
			if(spectator_spectate_next() == 1) {
				self.classname = "spectator";
			} else {
				self.classname = "observer";
				PutClientInServer();
			}
		} else if (self.BUTTON_ATCK2 && self.team <= 0) {
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
				spectator_to_player();
				return;
			}
		}
	}
	self.flags |= FL_CLIENT | FL_NOTARGET;
}

void() spectator_observer_think {
	if (self.team > 0) {
		if (spectator_spectate_next() == 1) {
			self.classname = "spectator";
			self.flags |= FL_JUMPRELEASED;
		}
	} else if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP) {
			self.flags &~= FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK) {
			self.flags &~= FL_JUMPRELEASED;
			if(spectator_spectate_next() == 1) {
				self.classname = "spectator";
			}
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_JUMP)) {
			self.flags |= FL_JUMPRELEASED;
			if(self.flags & FL_SPAWNING)
			{
				self.flags &~= FL_SPAWNING;
				spectator_to_player();
				return;
			}
		}
	}
}

void() spectator_to_player {
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
			msg_entity = self;
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_TEAMSELECT);
			return;
		}
	} else {
		//player may not join because of g_maxplayers is set
		centerprint_atprio(self, CENTERPRIO_MAPVOTE, PREVENT_JOIN_TEXT);
	}
}

void() spectator_note_update {
	spectator_note.SendFlags = 1;
}

void() spectator_init {
	if not(spectator_note) {
		spectator_note = NoteLine_New(Spectator_Note_Message);
		spectator_note.customizeentityforclient = Spectator_Note_Customize;
	}
}
