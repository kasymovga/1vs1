float() entcs_customize {
	entity o;
	o = self.owner;
	if(PLAYER_REALLY_DEAD(o))
		return FALSE;

	if (o.classname != "player")
		return FALSE;

	if(other == o)
		return FALSE;

	if(other.classname == "spectator")
	if(other.enemy == o)
		return FALSE;

	if (team_mode && o.team == other.team) {
		self.effects |= EFFECT_FULLBRIGHT;
	} else {
		if (o.body.body == self.enemy)
		if (player_alpha(o, other) < 0.25)
			return FALSE;

		if (plugin_chain_PlayerVisibleThroughWallFor(o,other)) {
			self.effects |= EFFECT_FULLBRIGHT;
		} else
			self.effects &= ~EFFECT_FULLBRIGHT;
	}
	return TRUE;
}

float(entity to, float sf) entcs_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_ENTCS);
	sf = sf & 31;
	entity o = self.owner;
	if (self.effects & EFFECT_FULLBRIGHT)
		sf |= 64;

	if (team_mode)
	if (o.team == to.team) {
		sf |= 160;
	}

	if not(sf & 128)
	if (plugin_chain_PlayerCanSeeHealthFor(to, o))
		sf |= 128;

	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		net_write_byte(MSG_ENTITY, num_for_edict(o));
		net_write_short(MSG_ENTITY, num_for_edict(self.enemy));
	}
	if (sf & 64) {
		if (sf & 2) {
			net_write_short(MSG_ENTITY, self.origin_x);
			net_write_short(MSG_ENTITY, self.origin_y);
		}
		if (sf & 4) {
			net_write_short(MSG_ENTITY, self.origin_z);
			net_write_short(MSG_ENTITY, self.angles_y);
		}
	}
	if (sf & 8)
		net_write_short(MSG_ENTITY, self.view_ofs_z);

	if (sf & 128)
	if (sf & 16) {
		net_write_byte(MSG_ENTITY, NET_BOUND_TO_BYTE(self.health));
		net_write_byte(MSG_ENTITY, NET_BOUND_TO_BYTE(self.armorvalue));
	}
	return TRUE;
}

void() entcs_think {
	self.nextthink = time;
	entity o = player_entity(self.owner);
	if (o.body)
		o = o.body.body;

	if (self.enemy != o) {
		self.enemy = o;
		self.SendFlags |= 1;
	}
	vector v = o.origin;
	if (v_x != self.origin_x || v_y != self.origin_y) {
		self.origin_x = v_x;
		self.origin_y = v_y;
		self.SendFlags |= 2;
	}
	if (v_z != self.origin_z || o.angles_y != self.angles_y) {
		self.angles_y = o.angles_y;
		self.origin_z = v_z;
		self.SendFlags |= 4;
	}
	if (o.maxs_z != self.view_ofs_z) {
		self.view_ofs_z = o.maxs_z;
		self.SendFlags |= 8;
	}
	if (o.health != floor(self.health) || o.armorvalue != floor(self.armorvalue)) {
		self.health = o.health;
		self.armorvalue = o.armorvalue;
		self.SendFlags |= 16;
	}
}

void(entity plr) entcs_spec_update {
	if (plr.entcs.weaponentity) {
		plr.entcs.weaponentity.SendFlags = 1;
	}
}

void(void) entcs_spec_message {
	float isspec = (other.enemy == self.owner);
	string s = (isspec ? "^2Spectating this player:" : "^2Spectating you:");
	if not(isspec)
		s = strcat(s, "\n^9type ^7showspec 0^9 to hide\n");

	entity e;
	float spectators = 0, hidden = 0;
	CLIENT_FOR_EACH_REAL(e)
		if (e.enemy == self.owner && !(e.client_flags & CLIENT_FLAG_RM_ANONSPEC)) {
			spectators++;
			if (spectators < 8) {
				s = strcat(s, "\n", strreplace("\n", "", e.netname));
			} else
				hidden++;
		}
	if (hidden)
		s = strcat(s, "\n^9(", ftos(hidden), " more)");

	s = strcat(s, "\n");
	str_unzone_ifneeded(self.message);
	if (spectators)
		self.message = strzone(s);
	else
		self.message = "";
}

float(void) entcs_spec_customize {
	if (self.owner.classname != "player") return FALSE;
	if not(other.client_flags & CLIENT_FLAG_RM_SHOWSPEC) return FALSE;
	if (other == self.owner || other.enemy == self.owner) return TRUE;
	return FALSE;
}

entity() entcs_attach {
	entity ent = spawn();
	self.entcs = ent;
	ent.classname = "entcs_sender_v2";
	ent.cnt = 1;
	ent.owner = self;
	ent.think = entcs_think;
	ent.nextthink = time;
	net_link_entity(ent, FALSE, 0, entcs_send);
	ent.customizeentityforclient = entcs_customize;
	RM({
		ent.weaponentity = noteline_new(entcs_spec_message);
		ent.weaponentity.owner = self;
		ent.weaponentity.customizeentityforclient = entcs_spec_customize;
	})
	return ent;
}

void() entcs_detach {
	if (self.entcs) {
		if (self.entcs.weaponentity)
			remove(self.entcs.weaponentity);

		remove(self.entcs);
		self.entcs = NULL;
	}
}
