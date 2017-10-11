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

.entity entcs;

void entcs_init()
{
	print("Initializing ClientSide information entities\n");
};

float entcs_customize_no_teamcheck()
{
	entity o;
	o = self.owner;
	if(PLAYER_REALLY_DEAD(o))
		return FALSE;
	if(o.classname != "player")
		return FALSE;
	if(other == o)
		return FALSE;

	return TRUE;
}

float entcs_customize()
{
	entity o;
	o = self.owner;
	if(PLAYER_REALLY_DEAD(o))
		return FALSE;
	if(o.classname != "player")
		return FALSE;
	if(other == o)
		return FALSE;
	if(other.team > 0)
	if(o.team != other.team)
		return FALSE;
	return TRUE;
}

float entcs_customize_enemy()
{
	entity o;
	o = self.owner;
	if(PLAYER_REALLY_DEAD(o))
		return FALSE;
	if(o.classname != "player")
		return FALSE;

	if (o == other)
		return FALSE;

	if(other.classname == "player")
	if(teamplay)
	if(o.team == other.team)
		return FALSE;

	if (Player_CalculateAlpha(o, other) < 0.25)
		return FALSE;

	return TRUE;
}

float entcs_send(entity to, float sf)
{
	entity o;
	o = self.owner;
	WriteByte(MSG_ENTITY, ENT_CLIENT_ENTCS);
	WriteByte(MSG_ENTITY, num_for_edict(o));
	WriteShort(MSG_ENTITY, o.origin_x);
	WriteShort(MSG_ENTITY, o.origin_y);
	WriteShort(MSG_ENTITY, o.origin_z);
	WriteByte(MSG_ENTITY, bound(0, o.health, 255));
	return TRUE;
};

float entcs_send_enemy(entity to, float sf)
{
	entity o;
	o = self.owner;
	WriteByte(MSG_ENTITY, ENT_CLIENT_ENTCS_ENEMY);
	WriteByte(MSG_ENTITY, num_for_edict(o));
	return TRUE;
};

void entcs_think()
{
	self.nextthink = time;

	entity o;
	o = self.owner;

	if(o.origin != self.origin || o.angles != self.angles)
	{
		setorigin(self, o.origin);
		self.angles = o.angles;
		if not(self.cnt)
			self.SendFlags |= 1;
	}
};

entity attach_entcs()
{
	local entity ent;

	ent = spawn();
	self.entcs = ent;
	if (teamplay) {
		ent.classname = "entcs_sender_v2";
		ent.owner = self;
		ent.think = entcs_think;
		ent.nextthink = time;

		Net_LinkEntity(ent, FALSE, 0, entcs_send);
		if (GameHook_RadarShowEnemiesAllowed())
			ent.customizeentityforclient = entcs_customize_no_teamcheck;
		else
			ent.customizeentityforclient = entcs_customize;

		ent.entcs = spawn();
		ent = ent.entcs;
	}

	ent.classname = "entcs_sender_v2_enemy";
	ent.cnt = 1;
	ent.owner = self;
	ent.think = entcs_think;
	ent.nextthink = time;

	Net_LinkEntity(ent, TRUE, 0, entcs_send_enemy);
	ent.customizeentityforclient = entcs_customize_enemy;


	return ent;
};

void detach_entcs()
{
	if (self.entcs) {
		if (self.entcs.entcs)
			remove(self.entcs.entcs);
		remove(self.entcs);
		self.entcs = world;
	}
};
