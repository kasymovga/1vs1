/**
 * The point of these entities is to avoid the problems
 * with clientprediction.
 * If you add SendEntity to players, the engine will not
 * do any prediction anymore, and you'd have to write the whole
 * prediction code in CSQC, you want that? :P
 * Data can depend on gamemode. For now, it serves as GPS entities
 * in onslaught... YAY ;)
 */

// Beware: do not redefine those in other files
// and NO, you cannot use ".version", which already exists (at least
// it did when I added this) But you have to use .Version
// Capital V

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

		if (gamehook_chain_PlayerVisibleThroughWallFor(o,other)) {
			self.effects |= EFFECT_FULLBRIGHT;
		} else
			self.effects &= ~EFFECT_FULLBRIGHT;
	}
	return TRUE;
}

float(entity to, float sf) entcs_send {
	WriteByte(MSG_ENTITY, NET_CSQC_ENTCS);
	sf = sf & 31;
	entity o = self.owner;
	if (self.effects & EFFECT_FULLBRIGHT)
		sf |= 64;

	if (team_mode)
	if (o.team == to.team) {
		sf |= 160;
	}

	if not(sf & 128)
	if (gamehook_chain_PlayerCanSeeHealthFor(to, o))
		sf |= 128;

	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteByte(MSG_ENTITY, num_for_edict(o));
		WriteShort(MSG_ENTITY, num_for_edict(self.enemy));
	}
	if (sf & 64) {
		if (sf & 2) {
			WriteShort(MSG_ENTITY, self.origin_x);
			WriteShort(MSG_ENTITY, self.origin_y);
		}
		if (sf & 4) {
			WriteShort(MSG_ENTITY, self.origin_z);
			WriteShort(MSG_ENTITY, self.angles_y);
		}
	}
	if (sf & 8)
		WriteShort(MSG_ENTITY, self.view_ofs_z);

	if (sf & 128)
	if (sf & 16) {
		WriteByte(MSG_ENTITY, NET_BOUND_TO_BYTE(self.health));
		WriteByte(MSG_ENTITY, NET_BOUND_TO_BYTE(self.armorvalue));
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

entity() entcs_attach {
	local entity ent;
	ent = spawn();
	self.entcs = ent;
	ent.classname = "entcs_sender_v2";
	ent.cnt = 1;
	ent.owner = self;
	ent.think = entcs_think;
	ent.nextthink = time;
	net_link_entity(ent, FALSE, 0, entcs_send);
	ent.customizeentityforclient = entcs_customize;
	return ent;
}

void() entcs_detach {
	if (self.entcs) {
		remove(self.entcs);
		self.entcs = world;
	}
}
