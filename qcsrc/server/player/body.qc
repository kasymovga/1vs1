string g_player_allowed_models;
string g_player_allowed_models_red;
string g_player_allowed_models_blue;
string g_player_allowed_models_yellow;
string g_player_allowed_models_pink;
float g_player_forcecolor;
float g_player_forcecolor_red;
float g_player_forcecolor_blue;
float g_player_forcecolor_yellow;
float g_player_forcecolor_pink;
float g_player_brightness;

float(void) player_body_customize;
float(void) player_body_torso_customize;
float(void) player_body_base_customize;

void(void) player_species_setup {
	float glob, i, j, fh = -1, len, sk;
	string fn, l;
	entity pl;
	FOR_EACH_PLAYER(pl)
		if (pl != self)
		if (pl.body)
		if (pl.body.playermodel == self.body.playermodel)
		if (pl.body.skinindex == self.body.skinindex) {
			self.species = pl.species;
			player_sound_copy(self, pl);
			return;
		}
	self.species = SPECIES_HUMAN;
	glob = search_begin("models/player/*.txt", TRUE, TRUE);
	if (glob < 0)
		return;

	for (j = 0; j <= 1; ++j) {
		for (i = 0; i < search_getsize(glob); ++i) {
			fn = search_getfilename(glob, i);
			if (fh > 0)
				fclose(fh);

			fh = fopen(fn, FILE_READ);
			if (fh < 0)
				continue;

			fgets(fh); fgets(fh);
			sk = stof(fgets(fh));
			if (sk == (j ? 0 : self.skinindex)) // 2nd pass skips the skin test
			if (fgets(fh) == self.body.model) {
				l = fgets(fh);
				len = tokenize_console(l);
				if (len != 2)
					continue;

				if (argv(0) != "species")
					continue;

				switch (argv(1)) {
				case "human":       self.species = SPECIES_HUMAN;       goto speciesfound;
				case "alien":       self.species = SPECIES_ALIEN;       goto speciesfound;
				case "robot_shiny": self.species = SPECIES_ROBOT_SHINY; goto speciesfound;
				case "robot_rusty": self.species = SPECIES_ROBOT_RUSTY; goto speciesfound;
				case "robot_solid": self.species = SPECIES_ROBOT_SOLID; goto speciesfound;
				case "animal":      self.species = SPECIES_ANIMAL;      goto speciesfound;
				case "reserved":    self.species = SPECIES_RESERVED;    goto speciesfound;
				}
			}
		}
	}
	print("No skin file for ", self.body.model, ":", ftos(self.skinindex), "\n");
:speciesfound
	if (fh > 0)
		fclose(fh);

	search_end(glob);
	player_sound_update();
}

void(entity bb) player_body_spawn {
	self.body = spawn();
	self.body.customizeentityforclient = player_body_customize;
	if not(bb) {
		bb = spawn();
		bb.owner = self;
		bb.customizeentityforclient = player_body_base_customize;
		setorigin(bb, self.origin);
		bb.effects = self.effects;
		setsize(bb, self.mins, self.maxs);
		setmodel(bb, "null");
		bb.culltracemode = CULLTRACEMODE_PLAYER;
	}
	self.body.body = bb;
	setattachment(self.body, bb, "");
	self.body.owner = self;
	chat_bubble_spawn();
	if (!self.dmg_inflictor || self.dmg_inflictor.classname != "dmg_inflictor" || self.dmg_inflictor.owner != self || wasfreed(self.dmg_inflictor)) { //spectator copy dmg_inflictor, so we need extra checks here
		if (clienttype(self) == CLIENTTYPE_REAL) {
			self.dmg_inflictor = spawn();
			self.dmg_inflictor.classname = "dmg_inflictor";
			self.dmg_inflictor.owner = self;
		} else
			self.dmg_inflictor = NULL;
	}

}

void(void) player_body_remove {
	if (self.body) {
		sound_stop(self.body.body, CHAN_VOICE);
		sound_stop(self.body.body, CHAN_PAIN);
		remove(self.body.body);
		if (self.body.exteriorweaponentity) remove(self.body.exteriorweaponentity);
		if (self.body.weaponentity) remove(self.body.weaponentity);
		remove(self.body);
		self.body = world;
	}
	if (self.dmg_inflictor) {
		if (self.dmg_inflictor.classname == "dmg_inflictor" && self.dmg_inflictor.owner == self && !wasfreed(self.dmg_inflictor)) {
			remove(self.dmg_inflictor);
			self.dmg_inflictor = NULL;
		} else {
			self.dmg_inflictor = NULL;
			player_dmg_inflictor_fix();
		}
	}
}

void(entity body_to, entity body_from, float realloc_playermodel) player_body_copy {
	body_to.modelindex_lod0 = body_from.modelindex_lod0;
	body_to.modelindex_lod1 = body_from.modelindex_lod1;
	body_to.modelindex_lod2 = body_from.modelindex_lod2;
	body_to.modelindex_lod0_from_nexuiz = body_from.modelindex_lod0_from_nexuiz;
	body_to.scale = body_from.scale;
	body_to.usecolormod = body_from.usecolormod;
	setorigin(body_to, body_from.origin);
	if (realloc_playermodel) {
		str_unzone_ifneeded(body_to.playermodel);
		body_to.playermodel = str_zone_ifneeded(body_from.playermodel); //need independent copy here
	} else {
		body_to.playermodel = body_from.playermodel;
		body_from.playermodel = "";
	}
	setmodel(body_to, body_from.model);
	if (body_from.weaponentity) {
		if not(body_to.weaponentity) {
			body_to.weaponentity = spawn();
			body_to.weaponentity.owner = body_to.owner;
			body_to.weaponentity.customizeentityforclient = player_body_torso_customize;
		}
		setmodel(body_to.weaponentity, body_from.weaponentity.model);
		body_to.weaponentity.tag_entity = body_to;
		body_to.weaponentity.tag_index = body_from.weaponentity.tag_index;
	} else if (body_to.weaponentity) {
		remove(body_to.weaponentity);
		body_to.weaponentity = NULL;
	}
	if (body_from.exteriorweaponentity) {
		if not(body_to.exteriorweaponentity) {
			body_to.exteriorweaponentity = spawn();
			body_to.exteriorweaponentity.owner = body_to.owner;
			body_to.exteriorweaponentity.customizeentityforclient = player_body_torso_customize;
		}
		setmodel(body_to.exteriorweaponentity, body_from.exteriorweaponentity.model);
		setorigin(body_to.exteriorweaponentity, body_from.exteriorweaponentity.origin);
		body_to.exteriorweaponentity.tag_entity = body_to.weaponentity;
		body_to.exteriorweaponentity.tag_index = body_from.exteriorweaponentity.tag_index;
	} else if (body_to.exteriorweaponentity) {
		remove(body_to.exteriorweaponentity);
		body_to.exteriorweaponentity = NULL;
	}
}

entity(float keepvelocity, float _movetype) player_body_detach {
	if (self.effects & EFFECT_NODRAW)
		return NULL;

	entity e = self.body;
	if not(e)
		return NULL;

	fire_move(self, e);
	e.owner = e;
	e.skinindex = self.skinindex;
	player_body_spawn(e.body);
	player_body_copy(self.body, e, FALSE);
	setattachment(e, world, "");
	e.body = e;
	e.enemy = self;
	e.iscreature = self.iscreature;
	e.angles = self.angles;
	e.avelocity = self.avelocity;
	e.classname = "body";
	e.damageforcescale = self.damageforcescale;
	e.event_damage = self.event_damage;
	e.pain_finished = self.pain_finished;
	e.health = self.health;
	e.armorvalue = self.armorvalue;
	e.armortype = self.armortype;
	e.species = self.species;
	e.movetype = _movetype;
	e.solid = self.solid;
	e.takedamage = self.takedamage;
	e.scale = self.scale;
	e.deadflag = self.deadflag;
	if (keepvelocity == 1)
		e.velocity = self.velocity;

	e.oldvelocity = self.velocity;
	//e.weapon = self.weapon;
	setorigin(e, self.origin);
	e.stand_maxs = self.stand_maxs;
	e.stand_mins = self.stand_mins;
	e.crouch_maxs = self.crouch_maxs;
	e.crouch_mins = self.crouch_mins;
	setsize(e, self.mins, self.maxs);
	e.reset = stdproc_remove;
	if (e.weaponentity) {
		e.weaponentity.owner = e;
		e.weaponentity.reset = stdproc_remove;
	}
	if (e.exteriorweaponentity) {
		e.exteriorweaponentity.owner = e;
		e.exteriorweaponentity.reset = stdproc_remove;
	}
	return e;
}

void(entity to, entity from) player_body_animation_copy {
	to.akimbo_animation_shift = from.akimbo_animation_shift;
	to.akimbo_use_left_hand = from.akimbo_use_left_hand;
	to.body.scale = from.body.scale;
	setorigin(to.body, from.body.origin);
	if (from.body.exteriorweaponentity && to.body.exteriorweaponentity)
		setorigin(to.body.exteriorweaponentity, from.body.exteriorweaponentity.origin);
#define PLAYERANIMCOPY(x,y,z) x.anim_ ## z = y.anim_ ## z;
	PLAYERANIMCOPY(to, from, die1)
	PLAYERANIMCOPY(to, from, die2)
	PLAYERANIMCOPY(to, from, draw)
	PLAYERANIMCOPY(to, from, duck)
	PLAYERANIMCOPY(to, from, duckwalk)
	PLAYERANIMCOPY(to, from, duckjump)
	PLAYERANIMCOPY(to, from, duckidle)
	PLAYERANIMCOPY(to, from, idle)
	PLAYERANIMCOPY(to, from, jump)
	PLAYERANIMCOPY(to, from, pain1)
	PLAYERANIMCOPY(to, from, pain2)
	PLAYERANIMCOPY(to, from, shoot)
	PLAYERANIMCOPY(to, from, taunt)
	PLAYERANIMCOPY(to, from, run)
	PLAYERANIMCOPY(to, from, runbackwards)
	PLAYERANIMCOPY(to, from, strafeleft)
	PLAYERANIMCOPY(to, from, straferight)
	PLAYERANIMCOPY(to, from, forwardright)
	PLAYERANIMCOPY(to, from, forwardleft)
	PLAYERANIMCOPY(to, from, backright)
	PLAYERANIMCOPY(to, from, backleft)
	PLAYERANIMCOPY(to, from, melee)
	PLAYERANIMCOPY(to, from, melee2)
	PLAYERANIMCOPY(to, from, dead1)
	PLAYERANIMCOPY(to, from, dead2)
	PLAYERANIMCOPY(to, from, stand)
#undef PLAYERANIMCOPY
}

float player_body_animation_parse_line_error;
void(entity e, string s) player_body_animation_parse_line {
	float c;
	vector anim;
	c = tokenize_console(s);
	if (c < 2) {
		player_body_animation_parse_line_error = TRUE;
		return;
	}
	string field_name = argv(0);
	if (field_name == "scale" && c >= 2) {
		e.body.scale = stof(argv(1));
		return;
	}
	if (field_name == "akimbo_shift" && c >= 2) {
		e.akimbo_animation_shift = stof(argv(1));
		return;
	}
	if (field_name == "usecolormod" && c >= 2) {
		e.body.usecolormod = stof(argv(1));
		return;
	}
	if (field_name == "akimbo_use_left_hand" && c >= 4) {
		e.akimbo_use_left_hand_x = stof(argv(1));
		e.akimbo_use_left_hand_y = stof(argv(2));
		e.akimbo_use_left_hand_z = stof(argv(3));
		return;
	}
	if (c < 4) {
		print("line ", s, " have not enough arguments\n");
		player_body_animation_parse_line_error = TRUE;
		return;
	}
	anim_x = stof(argv(1));
	anim_y = stof(argv(2));
	anim_z = stof(argv(3));
	if (field_name == "origin") {
		setorigin(e.body, anim);
		return;
	}
#define READFIELD(x) if (field_name == #x) { e.anim_ ## x = anim; return; }
	READFIELD(die1)
	READFIELD(die2)
	READFIELD(draw)
	READFIELD(duck)
	READFIELD(duckwalk)
	READFIELD(duckjump)
	READFIELD(duckidle)
	READFIELD(idle)
	READFIELD(jump)
	READFIELD(pain1)
	READFIELD(pain2)
	READFIELD(shoot)
	READFIELD(taunt)
	READFIELD(run)
	READFIELD(runbackwards)
	READFIELD(strafeleft)
	READFIELD(straferight)
	READFIELD(forwardright)
	READFIELD(forwardleft)
	READFIELD(backright)
	READFIELD(backleft)
	READFIELD(melee)
	READFIELD(melee2)
	READFIELD(dead1)
	READFIELD(dead2)
	READFIELD(stand)
#undef READFIELD
	player_body_animation_parse_line_error = TRUE;
	print("Unknown field name: ", field_name, "\n");
}

void(entity e, string _model) player_body_animation_q3_load {
	string s;
	float animinfo = fopen(strcat(_model, ".q3animations"), FILE_READ);
	float c;
	string arg0;
	vector headoffset, a;
	float animline = 0;
	float legshift = 0;
	if (animinfo < 0) return;
	while ((s = fgets(animinfo))) {
		c = strstrofs(s, "//", 0);
		if (c >= 0)
			s = substring(s, 0, c);

		c = tokenize_console(s);
		if (c <= 0) {
			continue;
		}
		arg0 = argv(0);
		if (c < 4)
			continue;

		if (strstrofs("0123456789", substring(arg0, 0, 1), 0) < 0) {
			if (arg0 == "headoffset") {
				//actually this offset mean something else
				//setorigin(e.body.exteriorweaponentity, stof(argv(1)) * '1 0 0' + stof(argv(2)) * '0 1 0' + stof(argv(2)) * '0 0 1');
			}
			continue;
		}
		a_x = stof(arg0) - legshift;
		a_y = stof(argv(1));
		a_z = stof(argv(3));
		switch (animline) {
		case 0: //DEATH1
			e.anim_die1 = a;
			break;
		case 1: //DEAD1
			e.anim_dead1 = a;
			break;
		case 2: //DEATH2
			e.anim_die2 = a;
			break;
		case 3: //DEAD2
			e.anim_dead2 = a;
			break;
		case 4: case 5: //DEATH3 DEAD3
			break;
		case 6: //GESTURE
			e.anim_taunt = a;
			break;
		case 7: //ATTACK
			e.anim_shoot = a;
			break;
		case 8: //ATTACK2
			e.anim_melee = a;
			break;
		case 9: //DROP
			e.anim_draw = a;
			break;
		case 10: //RAISE
			e.anim_draw_y += a_y;
			break;
		case 11: //STAND
			e.anim_stand = a;
			break;
		case 12: //STAND2
			break;
		case 13: //WALKCR
			legshift = a_x - e.anim_taunt_x;
			a_x -= legshift;
			e.anim_duckwalk = a;
			break;
		case 14: //WALK
			e.anim_strafeleft = a;
			e.anim_straferight = a;
			e.anim_forwardright = a;
			e.anim_forwardleft = a;
			break;
		case 15: //RUN
			e.anim_run = a;
			break;
		case 16: //BACK
			e.anim_runbackwards = a;
			e.anim_backleft = a;
			e.anim_backright = a;
			e.anim_pain1 = a;
			e.anim_pain2 = a;
			break;
		case 17: //SWIM
			break;
		case 18: //JUMP
			e.anim_jump = a;
			break;
		case 19: //LAND
			break;
		case 20: //JUMPB
			e.anim_melee2 = a;
			break;
		case 21: //LANDB
			break;
		case 22: //IDLE
			e.anim_idle = a;
			break;
		case 23: //IDLECR
			e.anim_duckidle = a;
			e.anim_duckjump = a;
			break;
		case 24: //TURN
			break;
		}
		animline++;
	}
	fclose(animinfo);
}

void(entity e, string _model) player_body_animation_load {
	float animfile;
	string animfilename, s;
	animfilename = strcat(_model, ".animinfo");
	animfile = fopen(animfilename, FILE_READ);
	anim_parseerror = FALSE;
	if (animfile >= 0) {
		anim_parseline(e, animfile, anim_die1);
		anim_parseline(e, animfile, anim_die2);
		anim_parseline(e, animfile, anim_draw);
		anim_parseline(e, animfile, anim_duck);
		anim_parseline(e, animfile, anim_duckwalk);
		anim_parseline(e, animfile, anim_duckjump);
		anim_parseline(e, animfile, anim_duckidle);
		anim_parseline(e, animfile, anim_idle);
		anim_parseline(e, animfile, anim_jump);
		anim_parseline(e, animfile, anim_pain1);
		anim_parseline(e, animfile, anim_pain2);
		anim_parseline(e, animfile, anim_shoot);
		anim_parseline(e, animfile, anim_taunt);
		anim_parseline(e, animfile, anim_run);
		anim_parseline(e, animfile, anim_runbackwards);
		anim_parseline(e, animfile, anim_strafeleft);
		anim_parseline(e, animfile, anim_straferight);
		anim_parseline(e, animfile, anim_forwardright);
		anim_parseline(e, animfile, anim_forwardleft);
		anim_parseline(e, animfile, anim_backright);
		anim_parseline(e, animfile, anim_backleft);
		fclose(animfile);
		// derived anims
		self.anim_dead1 = '0 1 1' + '1 0 0' * (self.anim_die1_x + self.anim_die1_y - 1);
		self.anim_dead2 = '0 1 1' + '1 0 0' * (self.anim_die2_x + self.anim_die2_y - 1);
		if (anim_parseerror)
			print("Parse error in ", animfilename, ", some player animations are broken\n");
	}
	e.body.scale = 1;
	e.body.usecolormod = 0;
	setorigin(e.body, '0 0 0');
	animfilename = strcat(_model, ".animinfo2");
	player_body_animation_parse_line_error = FALSE;
	animfile = fopen(animfilename, FILE_READ);
	if (animfile >= 0) {
		while ((s = fgets(animfile)) != "") {
			if (substring(s, 0, 1) == "/") continue;
			player_body_animation_parse_line(e, s);
		}
		fclose(animfile);
		if (player_body_animation_parse_line_error)
			print("Parse error in ", animfilename, ", some player animations are broken\n");
	}
	if (self.body.weaponentity)
		player_body_animation_q3_load(self, _model);
}

void() player_body_animation_setup {
	// defaults for legacy .zym models without animinfo files
	self.anim_die1 = '0 1 0.5'; // 2 seconds
	self.anim_die2 = '1 1 0.5'; // 2 seconds
	self.anim_draw = '2 1 3'; // TODO: analyze models and set framerate
	self.anim_duck = '3 1 100'; // this anim seems bogus in most models, so make it play VERY briefly!
	self.anim_duckwalk = '4 1 1';
	self.anim_duckjump = '5 1 100'; // zym anims keep playing until changed, so this only has to start the anim, landing will end it
	self.anim_duckidle = '6 1 1';
	self.anim_idle = '7 1 1';
	self.anim_jump = '8 1 100'; // zym anims keep playing until changed, so this only has to start the anim, landing will end it
	self.anim_pain1 = '9 1 2'; // 0.5 seconds
	self.anim_pain2 = '10 1 2'; // 0.5 seconds
	self.anim_shoot = '11 1 5'; // TODO: analyze models and set framerate
	self.anim_taunt = '12 1 0.33'; // FIXME?  there is no code using this anim
	self.anim_run = '13 1 1';
	self.anim_runbackwards = '14 1 1';
	self.anim_strafeleft = '15 1 1';
	self.anim_straferight = '16 1 1';
	self.anim_dead1 = '17 1 1';
	self.anim_dead2 = '18 1 1';
	self.anim_forwardright = '19 1 1';
	self.anim_forwardleft = '20 1 1';
	self.anim_backright = '21 1 1';
	self.anim_backleft  = '22 1 1';
	self.anim_melee = '0 0 0';
	self.anim_melee2 = '0 0 0';
	self.akimbo_animation_shift = 0;
	self.akimbo_use_left_hand = '0 0 0';
	player_body_animation_load(self, self.body.model);
	if (self.anim_melee == '0 0 0')
		self.anim_melee = self.anim_shoot;

	if (self.anim_melee2 == '0 0 0')
		self.anim_melee2 = '0 1 2';

	// reset animstate now
	anim_set(self.body, self.anim_idle, TRUE, FALSE, FALSE);
	if (self.body.weaponentity)
		anim_set(self.body.weaponentity, self.anim_stand, TRUE, FALSE, FALSE);
}

void(entity e, .vector anim, float looping, float override, float restart, float torsolegs) player_body_animation_set {
	if not(e.body)
		return;

	vector animv = e.anim;
	if (e.akimbo_animation_shift)
	if (akimbo_active(e))
			animv_x = animv_x + e.akimbo_animation_shift;

	if (e.body.weaponentity) {
		if (torsolegs & 1) { //Torso
			anim_set(e.body.weaponentity, animv, looping, override, restart);
			if (torsolegs & 2) //Legs with torso
				anim_set(e.body, animv, looping, override, restart);
		} else if (torsolegs & 2) //Legs only
			anim_set(e.body, animv, looping, override, restart);
	} else {
		anim_set(e.body, animv, looping, override, restart);
	}
}

void(void) player_body_animation {
	entity b = self.body;
	if (self.weaponentity)
	if (!self.weaponentity.animstate_override)
		anim_set(self.weaponentity, self.weaponentity.anim_idle, TRUE, FALSE, FALSE);

	if (!b || !b.modelindex || b.frame == b.dead_frame) //dead or gibbed
		return;

	anim_update(b);
	if (PLAYER_REALLY_DEAD(self)) {
		return;
	}
	if (b.weaponentity) {
		if (!b.weaponentity.animstate_override)
			anim_set(b.weaponentity, self.anim_stand, TRUE, FALSE, FALSE);

		anim_update(b.weaponentity);
	}
	if (!b.animstate_override) {
		if (!(self.flags & FL_ONGROUND)) {
			if (self.crouch)
				player_body_animation_set(self, anim_duckjump, FALSE, TRUE, FALSE, 2);
			else
				player_body_animation_set(self, anim_jump, FALSE, TRUE, FALSE, 2);
		} else if (self.crouch) {
			if (self.movement_x * self.movement_x + self.movement_y * self.movement_y > 20)
				player_body_animation_set(self, anim_duckwalk, TRUE, FALSE, FALSE, 2);
			else
				player_body_animation_set(self, anim_duckidle, TRUE, FALSE, FALSE, 2);
		} else if ((self.movement_x * self.movement_x + self.movement_y * self.movement_y) > 20) {
			if (self.movement_x > 0 && self.movement_y == 0)
				player_body_animation_set(self, anim_run, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x < 0 && self.movement_y == 0)
				player_body_animation_set(self, anim_runbackwards, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x == 0 && self.movement_y > 0)
				player_body_animation_set(self, anim_straferight, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x == 0 && self.movement_y < 0)
				player_body_animation_set(self, anim_strafeleft, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x > 0 && self.movement_y > 0)
				player_body_animation_set(self, anim_forwardright, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x > 0 && self.movement_y < 0)
				player_body_animation_set(self, anim_forwardleft, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x < 0 && self.movement_y > 0)
				player_body_animation_set(self, anim_backright, TRUE, FALSE, FALSE, 2);
			else if (self.movement_x < 0 && self.movement_y < 0)
				player_body_animation_set(self, anim_backleft, TRUE, FALSE, FALSE, 2);
			else
				player_body_animation_set(self, anim_run, TRUE, FALSE, FALSE, 2);
		} else
			player_body_animation_set(self, anim_idle, TRUE, FALSE, FALSE, 2);
	}
}

void(string modelname) player_body_setup_lod {
	string s;
	entity pl;
	FOR_EACH_PLAYER(pl)
		if (pl.body)
		if (pl.body.playermodel == modelname) {
			player_body_copy(self.body, pl.body, TRUE);
			player_body_animation_copy(self, pl);
			// reset animstate now
			player_body_animation_set(self, anim_idle, TRUE, FALSE, TRUE, 2);
			return;
		}
	s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod1", substring(modelname, -4, 4));
	if (file_exists(s)) {
		setmodel(self.body, s); // players have high precision
		self.body.modelindex_lod1 = self.body.modelindex;
	} else
		self.body.modelindex_lod1 = -1;

	s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
	if (file_exists(s)) {
		setmodel(self.body, s); // players have high precision
		self.body.modelindex_lod2 = self.body.modelindex;
	} else
		self.body.modelindex_lod2 = -1;

	setmodel(self.body, modelname); // players have high precision
	self.body.modelindex_lod0 = self.body.modelindex;
	if (self.body.modelindex_lod1 < 0)
		self.body.modelindex_lod1 = self.body.modelindex;

	if (self.body.modelindex_lod2 < 0)
		self.body.modelindex_lod2 = self.body.modelindex;

	s = strcat(substring(modelname, 0, strlen(modelname)-4), "_torso", substring(modelname, -4, 4));
	if (file_exists(s)) {
		if not(self.body.weaponentity) {
			self.body.weaponentity = spawn();
			self.body.weaponentity.owner = self;
			self.body.weaponentity.customizeentityforclient = player_body_torso_customize;
		}
		setmodel(self.body.weaponentity, s);
		setattachment(self.body.weaponentity, self.body, "tag_torso");
		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_head", substring(modelname, -4, 4));
		if (file_exists(s)) {
			if not(self.body.exteriorweaponentity) {
				self.body.exteriorweaponentity = spawn();
				self.body.exteriorweaponentity.owner = self;
				self.body.exteriorweaponentity.customizeentityforclient = player_body_torso_customize;
			}
			setmodel(self.body.exteriorweaponentity, s);
			setattachment(self.body.exteriorweaponentity, self.body.weaponentity, "tag_head");
		} else if (self.body.exteriorweaponentity) {
			remove(self.body.exteriorweaponentity);
			self.body.exteriorweaponentity = NULL;
		}
	} else {
		if (self.body.exteriorweaponentity) {
			remove(self.body.exteriorweaponentity);
			self.body.exteriorweaponentity = NULL;
		}
		if (self.body.weaponentity) {
			remove(self.body.weaponentity);
			self.body.weaponentity = NULL;
		}
	}
	s = whichpack(self.body.model);
	str_unzone_ifneeded(self.body.playermodel);
	self.body.playermodel = str_zone_ifneeded(modelname); //need independent copy here
	self.body.modelindex_lod0_from_nexuiz = ((s == "") || (substring(s, 0, 4) == "data"));
	player_body_animation_setup();
}

string() player_body_model_list_allowed {
	string l = g_player_allowed_models;
	if (team_mode)
	if (self.team > 0) {
		if (self.team == COLOR_TEAM1) {
			if (g_player_allowed_models_red != "")
				l = g_player_allowed_models_red;
		} else if (self.team == COLOR_TEAM2) {
			if (g_player_allowed_models_blue != "")
				l = g_player_allowed_models_blue;
		} else if (self.team == COLOR_TEAM3) {
			if (g_player_allowed_models_yellow != "")
				l = g_player_allowed_models_yellow;
		} else if (self.team == COLOR_TEAM4) {
			if (g_player_allowed_models_pink != "")
				l = g_player_allowed_models_pink;
		}
	}
	return plugin_chain_player_body_model_list_allowed_mod(l);
}

string(string _playermodel) player_body_model_allowed {
	string allowed_models = player_body_model_list_allowed();
	string first_allowed_model = "";
	string tail = allowed_models;
	string s = strcat(" ", allowed_models, " ");
	while ((tail != "")) {
		first_allowed_model = str_car(tail);
		if (first_allowed_model != "") break;
		tail = str_cdr(allowed_models);
	}
	if (first_allowed_model == "")
		return _playermodel;

	if (strstrofs(first_allowed_model, ":", 0) > 0) {
		first_allowed_model = substring(first_allowed_model, 0, strstrofs(first_allowed_model, ":", 0));
	}
	if (_playermodel == "")
		return first_allowed_model;

	if (strstrofs(s, strcat(" ", _playermodel, " "), 0) >= 0 ||
			strstrofs(s, strcat(" ", _playermodel, ":"), 0) >= 0)
		return _playermodel;

	if (substring(_playermodel, 0, 14) == "models/player/") {
		string playermodelshort = substring(_playermodel, 14, -1); //without models/player/ prefix
		if (strstrofs(s, strcat(" ", playermodelshort, " "), 0) >= 0 ||
				strstrofs(s, strcat(" ", playermodelshort, ":"), 0) >= 0)
			return _playermodel;
	}

	return first_allowed_model;
}

float(string _playermodel, float _skin) player_body_allowed_skin {
	string allowed_models = player_body_model_list_allowed();
	string playermodelshort = substring(_playermodel, 14, -1); //without models/player/ prefix
	string s = strcat(" ", allowed_models, " ");
	if (str_car(allowed_models) == "")
		return _skin;

	if (strstrofs(s, strcat(" ", _playermodel, " "), 0) >= 0 ||
			strstrofs(s, strcat(" ", _playermodel, ":", ftos(_skin), " "), 0) >= 0 ||
			strstrofs(s, strcat(" ", playermodelshort, " "), 0) >= 0 ||
			strstrofs(s, strcat(" ", playermodelshort, ":", ftos(_skin), " "), 0) >= 0)
		return _skin;

	float allowed_skin_pos = strstrofs(s, strcat(" ", _playermodel, ":"), 0);
	if (allowed_skin_pos >= 0) {
		allowed_skin_pos = allowed_skin_pos + strlen(_playermodel) + 1;
		return stof(str_car(substring(allowed_models, allowed_skin_pos, -1)));
	}
	return _skin;
}

string(string _playermodel) player_body_model_check {
	string fallback = player_body_model_allowed("models/player/marine.zym");
	_playermodel = player_body_model_allowed(_playermodel);
	if (strlen(_playermodel) < 4)
		return fallback;
	
	if (strstrofs(_playermodel, "/", 0) < 0) _playermodel = strcat("models/player/", _playermodel);
	if (substring(_playermodel,0,14) != "models/player/")
		return fallback;
	else {
		if (substring(_playermodel,-4,4) != ".zym")
		if (substring(_playermodel,-4,4) != ".dpm")
		if (substring(_playermodel,-4,4) != ".md3")
		if (substring(_playermodel,-4,4) != ".psk")
		if (substring(_playermodel,-4,4) != ".iqm")
			return fallback;
		// forbid the LOD models
		if (substring(_playermodel, -9,5) == "_lod1")
			return fallback;

		if (substring(_playermodel, -9,5) == "_lod2")
			return fallback;

		// forbid the torso/head models
		if (substring(_playermodel, -10,6) == "_torso")
			return fallback;

		if (substring(_playermodel, -9,5) == "_head")
			return fallback;

		if (substring(_playermodel, -15,5) == "_decompiled")
			return fallback;

		if (substring(_playermodel, -13,5) == "_compiled")
			return fallback;

		if (_playermodel != strtolower(_playermodel))
			return fallback;

		if (!file_exists(_playermodel))
			return fallback;
	}
	return _playermodel;
}

void() player_body_model_setup {
	float forcecolor, chmdl = FALSE, oldskin;
	vector m1, m2;
	if (team_mode) {
		forcecolor =
				((self.team == COLOR_TEAM1) ? g_player_forcecolor_red :
				((self.team == COLOR_TEAM2) ? g_player_forcecolor_blue :
				((self.team == COLOR_TEAM3) ? g_player_forcecolor_yellow :
				((self.team == COLOR_TEAM4) ? g_player_forcecolor_pink : g_player_forcecolor))));

		if (forcecolor < 0)
			forcecolor = (self.team - 1) * 17;
	} else {
		forcecolor = g_player_forcecolor;
	}
	if ((self.playermodel != "" && self.body.playermodel != self.playermodel) || self.body.playermodel == "") {
		self.playermodel = player_body_model_check(self.playermodel);
		if (self.playermodel != self.body.playermodel) {
			m1 = self.mins;
			m2 = self.maxs;
			player_body_setup_lod(self.playermodel);
			setsize(self, m1, m2);
			chmdl = (self.playermodel_save != self.playermodel);
		}
		if (self.playermodel != "") {
			str_unzone_ifneeded(self.playermodel_save);
			self.playermodel_save = strzone(self.playermodel);
			self.playermodel = "";
		}
	}
	oldskin = self.skinindex;
	if (self.playerskin != "") {
		self.skinindex = player_body_allowed_skin(self.playermodel_save, stof(self.playerskin));
		self.playerskin = "";
	}
	if (team_mode && self.playermodel == "models/player/nexus.zym" && self.skinindex >= 3 && self.skinindex <= 5) // nexys.zym have skins 3, 4 and 5 as fbgreen/fbred/fborange
		self.skinindex = 6;

	if (chmdl || oldskin != self.skinindex)
		player_species_setup();

	if (forcecolor > -2) {
		float colors = plugin_chain_player_colors_mod(forcecolor);
		if (self.clientcolors != colors)
			player_set_colors(self, colors);
	}
	if (self.body.colormap != self.colormap) {
		self.body.colormap = self.colormap;
		if (team_mode &&  self.body.usecolormod) {
			self.body.colormod = team_colormod(self.team);
			if (self.body.colormod == '0 0 0')
				self.body.colormod = '1 1 1';

			self.body.colormod *= (g_player_brightness ? g_player_brightness : 1);
		} else
			self.body.colormod = '1 1 1' * g_player_brightness;

		if (self.body.colormod == '1 1 1') self.body.colormod = '0 0 0';
		if (self.body.weaponentity) {
			self.body.weaponentity.colormap = self.body.colormap;
			self.body.weaponentity.colormod = self.body.colormod;
			if (self.body.exteriorweaponentity) {
				self.body.exteriorweaponentity.colormod = self.body.colormod;
			}
		}
	}
}

float(void) player_body_torso_customize {
	entity o = self.owner;
	self.alpha = player_alpha(o, other);
	if (self.alpha < 0)
		return FALSE;

	if (plugin_chain_PlayerVisibleThroughWallFor(o, other))
		self.effects |= EFFECT_NODEPTHTEST;
	else
		self.effects &= ~EFFECT_NODEPTHTEST;

	return TRUE;
}

float(void) player_body_customize {
	entity modelsource;
	entity o = self.owner;
	self.alpha = player_alpha(o, other);
	if (self.alpha < 0)
		return FALSE;

	if (self.tag_entity) {
		if (other == self.owner)
			self.tag_entity = other;
		else
			self.tag_entity = self.body;
	}
	if (plugin_chain_PlayerVisibleThroughWallFor(o, other))
		self.effects |= EFFECT_NODEPTHTEST;
	else
		self.effects &= ~EFFECT_NODEPTHTEST;

	if (!self.modelindex && PLAYER_REALLY_DEAD(o))
		return TRUE;

	modelsource = self;
	if (self.skin != modelsource.owner.skinindex) {
		self.skin = modelsource.owner.skinindex;
		if (self.weaponentity) {
			self.weaponentity.skin = self.skin;
			if (self.exteriorweaponentity) self.exteriorweaponentity.skin = self.skin;
		}
	}
	if (self.weaponentity) {
		self.weaponentity.alpha = self.alpha;
		if (self.exteriorweaponentity)
			self.exteriorweaponentity.alpha = self.alpha;
	}
	float distance;
	float f;
	if (other.cvar_cl_playerdetailreduction <= 0) {
		if (other.cvar_cl_playerdetailreduction <= -2)
			self.modelindex = modelsource.modelindex_lod2;
		else if (other.cvar_cl_playerdetailreduction <= -1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	} else {
		distance = vlen(o.origin - other.origin);
		f = (distance + 100.0) * other.cvar_cl_playerdetailreduction;
		if (f > sv_loddistance2)
			self.modelindex = modelsource.modelindex_lod2;
		else if (f > sv_loddistance1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	}
	return TRUE;
}

float(void) player_body_base_customize {
	self.alpha = player_alpha(self.owner, other);
	if (self.alpha < 0)
		return FALSE;

	if (self.owner == other)
		return FALSE;
	else if (self.owner == other.enemy && other.classname == "spectator")
		self.exteriormodeltoclient = other;
	else
		self.exteriormodeltoclient = world;

	if (plugin_chain_PlayerVisibleThroughWallFor(self.owner, other))
		self.effects |= EFFECT_NODEPTHTEST;
	else
		self.effects &= ~EFFECT_NODEPTHTEST;

	return TRUE;
}

var float(string s, float i) player_body_cmd_client_handle_next;
float(string s, float i) player_body_cmd_client_handle {
	if (s == "modelselect") {
		msg_entity = self;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_MODELSELECT);
		net_write_string(MSG_ONE, self.body.playermodel);
		net_write_byte(MSG_ONE, stof(self.body.playerskin));
		net_write_string(MSG_ONE, player_body_model_list_allowed());
		return TRUE;
	}
	return player_body_cmd_client_handle_next(s, i);
}

var void(void(string item, string cmd) Add_Item) player_body_gamemenu_add_items_next;
void(void(string item, string cmd) add) player_body_gamemenu_add_items {
	if (g_player_allowed_models == "" || str_cdr(g_player_allowed_models) != "")
		add("Change model", "cmd modelselect;");

	player_body_gamemenu_add_items_next(add);
}

void(string list) player_body_precache {
	string s, _skin = "", prefix, suffix, m;
	float glob, l, colon, n, i;
	for (; (s = str_car(list)) != ""; list = str_cdr(list)) {
		colon = strstrofs(s, ":", 0);
		if (colon > 0) {
			_skin = substring(s, colon + 1, -1);
			s = substring(s, 0, colon);
		}
		if (strstrofs(s, "/", 0) < 0)
			s = strcat("models/player/", s);

		l = strlen(s);
		if (l < 19) continue;
		prefix = substring(s, 0, l - 4);
		suffix = substring(s, l - 4, 4);
		print("Precaching player model: ", s, "\n");
		precache_model(s);
		m = strcat(prefix, "_lod1", suffix);
		if (file_exists(m))
			precache_model(m);

		m = strcat(prefix, "_lod2", suffix);
		if (file_exists(m))
			precache_model(m);

		m = strcat(prefix, "_torso", suffix);
		if (file_exists(m))
			precache_model(m);

		m = strcat(prefix, "_head", suffix);
		if (file_exists(m))
			precache_model(m);

		if (colon > 0) {
			player_sound_precache(strcat(s, "_", _skin, ".sounds"));
		} else {
			glob = search_begin(strcat(s, "_*.sounds"), TRUE, FALSE);
			if (glob >= 0) {
				n = search_getsize(glob);
				for (i = 0; i < n; i++)
					player_sound_precache(search_getfilename(glob, i));

				search_end(glob);
			}
		}
		player_sound_precache(strcat(s, ".sounds"));
	}
}

void(string pattern) player_body_precache_all_models {
	float glob, i, n, n2, j;
	string s, f;
	glob = search_begin(pattern, TRUE, FALSE);
	if (glob < 0)
		return;

	n = search_getsize(glob);
	for (i = 0; i < n; ++i) {
		f = search_getfilename(glob, i);
		if (substring(f, -15, 11) == "_decompiled")
			continue;

		if (substring(f, -13, 9) == "_compiled")
			continue;

		s = substring(f, -9,5);
		if (s == "_lod1" || s == "_lod2")
			continue;

		player_body_precache(f);
	}
	search_end(glob);
}

float player_body_init_done;
void(void) player_body_init {
	CVAR_CACHE_STR(g_player_allowed_models);
	CVAR_CACHE_STR(g_player_allowed_models_red);
	CVAR_CACHE_STR(g_player_allowed_models_blue);
	CVAR_CACHE_STR(g_player_allowed_models_yellow);
	CVAR_CACHE_STR(g_player_allowed_models_pink);
	string g_player_forcemodel = cvar_string("g_player_forcemodel");
	string g_player_forcemodel_red = cvar_string("g_player_forcemodel_red");
	string g_player_forcemodel_blue = cvar_string("g_player_forcemodel_blue");
	string g_player_forcemodel_yellow = cvar_string("g_player_forcemodel_yellow");
	string g_player_forcemodel_pink = cvar_string("g_player_forcemodel_pink");
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_red, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_blue, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_yellow, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_pink, -2);
	float g_player_forceskin = cvar("g_player_forceskin");
	float g_player_forceskin_red = cvar("g_player_forceskin_red");
	float g_player_forceskin_blue = cvar("g_player_forceskin_blue");
	float g_player_forceskin_yellow = cvar("g_player_forceskin_yellow");
	float g_player_forceskin_pink = cvar("g_player_forceskin_pink");
	CVAR_CACHE(g_player_brightness);
	if (g_player_forcemodel != "" && g_player_forcemodel != "0") {
		str_unzone_ifneeded(g_player_allowed_models);
		str_unzone_ifneeded(g_player_allowed_models_red);
		str_unzone_ifneeded(g_player_allowed_models_blue);
		str_unzone_ifneeded(g_player_allowed_models_yellow);
		str_unzone_ifneeded(g_player_allowed_models_pink);
		g_player_allowed_models = strcat(g_player_forcemodel, (g_player_forceskin >= 0 ? strcat(":", ftos(g_player_forceskin)) : ""));
		if (g_player_forcemodel_blue == "" || g_player_forcemodel_blue == "0") {
			g_player_allowed_models_blue = "";
		} else
			g_player_allowed_models_blue = strcat(g_player_forcemodel_blue, (g_player_forceskin_blue >= 0 ? strcat(":", ftos(g_player_forceskin_blue)) : ""));

		if (g_player_forcemodel_red == "" || g_player_forcemodel_red == "0") {
			g_player_allowed_models_red = "";
		} else
			g_player_allowed_models_red = strcat(g_player_forcemodel_red, (g_player_forceskin_red >= 0 ? strcat(":", ftos(g_player_forceskin_red)) : ""));

		if (g_player_forcemodel_yellow == "" || g_player_forcemodel_yellow == "0") {
			g_player_allowed_models_yellow = "";
		} else
			g_player_allowed_models_yellow = strcat(g_player_forcemodel_yellow, (g_player_forceskin_yellow >= 0 ? strcat(":", ftos(g_player_forceskin_yellow)) : ""));

		if (g_player_forcemodel_pink == "" || g_player_forcemodel_pink == "0") {
			g_player_allowed_models_pink = "";
		} else
			g_player_allowed_models_pink = strcat(g_player_forcemodel_pink, (g_player_forceskin_pink >= 0 ? strcat(":", ftos(g_player_forceskin_pink)) : ""));

		g_player_allowed_models = str_zone_ifneeded(g_player_allowed_models);
		g_player_allowed_models_red = str_zone_ifneeded(g_player_allowed_models_red);
		g_player_allowed_models_blue = str_zone_ifneeded(g_player_allowed_models_blue);
		g_player_allowed_models_yellow = str_zone_ifneeded(g_player_allowed_models_yellow);
		g_player_allowed_models_pink = str_zone_ifneeded(g_player_allowed_models_pink);
	}
	if (str_car(g_player_allowed_models) == "") {
		player_body_precache_all_models("models/player/*.zym");
		player_body_precache_all_models("models/player/*.dpm");
		player_body_precache_all_models("models/player/*.md3");
		player_body_precache_all_models("models/player/*.psk");
		player_body_precache_all_models("models/player/*.iqm");
	} else {
		player_body_precache(g_player_allowed_models);
		player_body_precache(g_player_allowed_models_red);
		player_body_precache(g_player_allowed_models_blue);
		player_body_precache(g_player_allowed_models_yellow);
		player_body_precache(g_player_allowed_models_pink);
	}
	if (player_body_init_done) return;
	player_body_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = player_body_cmd_client_handle;
	player_body_gamemenu_add_items_next = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = player_body_gamemenu_add_items;
	player_body_init_done = TRUE;
}
