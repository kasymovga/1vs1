float sv_autotaunt;
float sv_taunt;
.float cvar_cl_autotaunt;
.float cvar_cl_voice_directional;
.float cvar_cl_voice_directional_taunt_attenuation;
float g_respawn_delay;
float g_respawn_mapsettings;
float g_respawn_mapsettings_delay;
float g_respawn_mapsettings_waves;
float g_respawn_waves;
float g_voice_flood_spv;
float g_voice_flood_spv_team;
float g_fullbrightplayers;
string g_player_allowed_models;
string g_player_allowed_models_red;
string g_player_allowed_models_blue;
string g_player_allowed_models_yellow;
string g_player_allowed_models_pink;
string g_player_forcemodel;
string g_player_forcemodel_red;
string g_player_forcemodel_blue;
string g_player_forcemodel_yellow;
string g_player_forcemodel_pink;
float g_player_forcecolor;
float g_player_forcecolor_red;
float g_player_forcecolor_blue;
float g_player_forcecolor_yellow;
float g_player_forcecolor_pink;
float g_player_forceskin;
float g_player_forceskin_red;
float g_player_forceskin_blue;
float g_player_forceskin_yellow;
float g_player_forceskin_pink;
float g_balance_armor_blockpercent;
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
float g_balance_pause_armor_rot_spawn;
float g_balance_pause_fuel_rot_spawn;
float g_balance_pause_health_regen_spawn;
float g_balance_pause_health_rot_spawn;
float g_forced_respawn;
float g_teamdamage_resetspeed;
float g_reset_on_join;
float g_player_brightness;
float g_spawnshieldtime;
float g_spawnfrags;
float g_spawnsound;
float g_player_pushfactor;
float g_player_body_pitch_maxangle;
float g_player_team_collisions;
float g_endmatch_on_leave;
string sv_announcer_extra_meleefrag;
string sv_announcer_extra_pushfrag;
string sv_announcer_extra_doublekill;
float sv_announcer_extra_doublekill_interval;
string sv_announcer_extra_telefrag;
string sv_announcer_extra_firstblood;
string sv_sound_frag;
float bot_taunt;
float bot_talk;
float sv_loddistance1;
float sv_loddistance2;
#ifdef ALLOW_FORCEMODELS
float sv_clforceplayermodels;
#endif

.entity pusher;

float(void) player_customize;
float(void) player_body_customize;

void(entity bb) player_body_spawn {
	self.body = spawn();
	self.body.customizeentityforclient = player_body_customize;
	if not(bb) {
		bb = spawn();
		bb.owner = self;
		bb.customizeentityforclient = player_customize;
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
}

void(void) player_body_remove {
	if (self.body) {
		sound_stop(self.body.body, CHAN_VOICE);
		sound_stop(self.body.body, CHAN_PAIN);
		remove(self.body.body);
		remove(self.body);
		self.body = world;
	}
}

void(void) player_corpse_think {
	if (self.frame != self.dead_frame) {
		anim_update(self);
		if (time >= self.animstate_endtime) {
			if (self.owner.maxs_z > 5) {
				self.owner.maxs_z = 5;
				setsize(self.owner, self.owner.mins, self.owner.maxs);
			}
			self.frame = self.dead_frame;
		}
	} else if (time >= self.fade_time) {
		if (self.owner.body == self)
			self.owner.body = world;

		remove(self);
		return;
	}
	self.nextthink = time;
}

void(entity body_to, entity body_from, float realloc_playermodel) player_body_copy {
	body_to.modelindex_lod0 = body_from.modelindex_lod0;
	body_to.modelindex_lod1 = body_from.modelindex_lod1;
	body_to.modelindex_lod2 = body_from.modelindex_lod2;
	body_to.modelindex_lod0_from_nexuiz = body_from.modelindex_lod0_from_nexuiz;
	if (realloc_playermodel) {
		str_unzone_ifneeded(body_to.playermodel);
		body_to.playermodel = str_zone_ifneeded(body_from.playermodel); //need independent copy here
	} else {
		body_to.playermodel = body_from.playermodel;
		body_from.playermodel = "";
	}
	setmodel(body_to, body_from.model);
}

entity(float keepvelocity, float _movetype) player_body_detach {
	if (self.effects & EF_NODRAW)
		return world;

	entity e = self.body;
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
	e.effects = self.effects;
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
	setsize(e, self.mins, self.maxs);
	e.reset = stdproc_remove;
	return e;
}

void(void) player_respawn {
	player_body_detach(1, MOVETYPE_TOSS);
	client_put();
}

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
}

void(float finished, string samp) play_countdown {
	if (clienttype(self) == CLIENTTYPE_REAL)
		if (floor(finished - time - frametime) != floor(finished - time))
			if (finished - time < 6)
				sound (self, CHAN_AUTO, samp, VOL_BASE, ATTN_NORM);
}

void() player_effects {
	if (!self.body.modelindex || PLAYER_REALLY_DEAD(self)) // don't apply the flags if the player is gibbed
		return;

	fire_apply_effect(self);
	gamehook_chain_player_effects();
	if (g_fullbrightplayers)
		self.effects = self.effects | EF_FULLBRIGHT;

	if not(g_spawnfrags)
	if (time >= map_starttime)
	if (time < self.spawnshieldtime)
		self.effects = self.effects | (EF_ADDITIVE | EF_FULLBRIGHT);

	self.body.effects = self.effects;
	self.body.body.effects = self.effects & EF_TELEPORT_BIT; //for teleportation
	self.body.angles_x = bound(-g_player_body_pitch_maxangle, (-g_player_body_pitch_maxangle / 90) * self.v_angle_x, g_player_body_pitch_maxangle);
	self.body.body.modelflags = self.modelflags; //for MF_ROCKET effect
	self.effects = 0;
}

void(entity to, entity from) player_anim_copy {
	to.akimbo_animation_shift = from.akimbo_animation_shift;
	to.akimbo_use_left_hand = from.akimbo_use_left_hand;
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
#undef PLAYERANIMCOPY
}

float player_anim_parseline_error;
void(entity e, string s) player_anim_parseline {
	float c;
	vector anim;
	c = tokenize_console(s);
	if (c < 2) {
		player_anim_parseline_error = TRUE;
		return;
	}
	string field_name = argv(0);
	if (field_name == "akimbo_shift") {
		e.akimbo_animation_shift = stof(argv(1));
		return;
	}
	if (field_name == "akimbo_use_left_hand") {
		e.akimbo_use_left_hand_x = stof(argv(1));
		e.akimbo_use_left_hand_y = stof(argv(2));
		e.akimbo_use_left_hand_z = stof(argv(3));
		return;
	}
	if (c < 4) {
		player_anim_parseline_error = TRUE;
		return;
	}
	anim_x = stof(argv(1));
	anim_y = stof(argv(2));
	anim_z = stof(argv(3));
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
#undef READFIELD
	player_anim_parseline_error = TRUE;
	print("Unknown field name: ", field_name, "\n");
}

void(entity e, string _model) player_anim_load {
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
	animfilename = strcat(_model, ".animinfo2");
	player_anim_parseline_error = FALSE;
	animfile = fopen(animfilename, FILE_READ);
	if (animfile >= 0) {
		while ((s = fgets(animfile)) != "") {
			player_anim_parseline(e, s);
		}
		fclose(animfile);
		if (player_anim_parseline_error)
			print("Parse error in ", animfilename, ", some player animations are broken\n");
	}
}

void() player_anim_setup {
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
	player_anim_load(self, self.body.model);
	if (self.anim_melee == '0 0 0')
		self.anim_melee = self.anim_shoot;

	if (self.anim_melee2 == '0 0 0')
		self.anim_melee2 = '0 1 2';

	// reset animstate now
	anim_set(self.body, self.anim_idle, TRUE, FALSE, TRUE);
}

void(entity e, .vector anim, float looping, float override, float restart) player_anim_set {
	if not(e.body)
		return;

	vector animv = e.anim;
	if (e.akimbo_animation_shift)
	if (akimbo_active(e))
			animv_x = animv_x + e.akimbo_animation_shift;

	anim_set(e.body, animv, looping, override, restart);
}

void(void) player_anim {
	if (self.body)
		anim_update(self.body);

	if (self.weaponentity)
		anim_update(self.weaponentity);

	if (PLAYER_REALLY_DEAD(self)) {
		return;
	}
	if (!self.body.animstate_override) {
		if (!(self.flags & FL_ONGROUND)) {
			if (self.crouch)
				player_anim_set(self, anim_duckjump, FALSE, TRUE, FALSE);
			else
				player_anim_set(self, anim_jump, FALSE, TRUE, FALSE);

		} else if (self.crouch) {
			if (self.movement_x * self.movement_x + self.movement_y * self.movement_y > 20)
				player_anim_set(self, anim_duckwalk, TRUE, FALSE, FALSE);
			else
				player_anim_set(self, anim_duckidle, TRUE, FALSE, FALSE);
		} else if ((self.movement_x * self.movement_x + self.movement_y * self.movement_y) > 20) {
			if (self.movement_x > 0 && self.movement_y == 0)
				player_anim_set(self, anim_run, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y == 0)
				player_anim_set(self, anim_runbackwards, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y > 0)
				player_anim_set(self, anim_straferight, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y < 0)
				player_anim_set(self, anim_strafeleft, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y > 0)
				player_anim_set(self, anim_forwardright, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y < 0)
				player_anim_set(self, anim_forwardleft, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y > 0)
				player_anim_set(self, anim_backright, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y < 0)
				player_anim_set(self, anim_backleft, TRUE, FALSE, FALSE);
			else
				player_anim_set(self, anim_run, TRUE, FALSE, FALSE);
		} else
			player_anim_set(self, anim_idle, TRUE, FALSE, FALSE);
	}
	if (self.weaponentity)
	if (!self.weaponentity.animstate_override)
		anim_set(self.weaponentity, self.weaponentity.anim_idle, TRUE, FALSE, FALSE);
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_corpse_damage {
	violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);

	// damage resistance (ignore most of the damage from a bullet or similar)
	_damage = max(_damage - 5, 1);
	entity b = self.body;
	entity o = b.owner;

	if (_damage > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (_damage > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM);

	if (_damage > 50)
		violence_gib_splash_at(hitloc, force * -0.1, 3, 1, self, attacker);
	if (_damage > 100)
		violence_gib_splash_at(hitloc, force * -0.2, 3, 1, self, attacker);

	o.health = o.health - _damage;
	self.dmg_take = self.dmg_take + _damage;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;
	if (o.health <= -75 && b.modelindex != 0) {
		// don't use any animations as a gib
		b.frame = 0;
		b.dead_frame = 0;
		// view just above the floor
		o.view_ofs = '0 0 4';
		violence_gib_splash(self, 1, 1, attacker);
		b.modelindex = 0; // restore later
		self.event_damage = world.event_damage;
		self.solid = SOLID_NOT; // restore later
	}
}

void(float killed) player_clear {
	float j;
	if (killed)
		portal_clear_all_later(self);
	else
		portal_clear_all(self);

	// reset fields the weapons may use just in case
	for (j = WEP_FIRST; j <= WEP_LAST; ++j) {
		weapon_action(j, WR_RESETPLAYER);
		weapon_action(j, WR_CLEAR);
		ATTACK_FINISHED_FOR(self, j) = 0;
	}
	gamehook_chain_player_clear(killed);
	//Clear waypoints
	WaypointSprite_PlayerDead();
	if (self.classname == "disconnecting") {
		str_unzone_ifneeded(self.body.playermodel);
		player_body_remove();
	}
}

float checkrules_firstblood;
void(entity attacker, entity inflictor, entity targ, float deathtype) player_obituary {
	string s, a;
	float p, w;
	s = targ.netname;
	a = attacker.netname;
	weapon_fragprefix = "";
	if (targ == attacker) {
		if not(clienttype(attacker) == CLIENTTYPE_REAL)
			bot_say(attacker, FALSE, world, cvar_string("bot_messages_suicide"), "");
		if (deathtype == DEATH_TEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", team_colored_name(targ.team)));
		} else if (deathtype == DEATH_AUTOTEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", team_colored_name(targ.team)));
			return;
		} else if (deathtype == DEATH_NOAMMO) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
		} else if (deathtype == DEATH_ROT) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
		} else if (deathtype == DEATH_MIRRORDAMAGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
		} else {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
		}
		w = DEATH_WEAPONOF(deathtype);
		if (WEP_VALID(w)) {
			weapon_deathtypestring = "couldn't resist the urge to self-destruct";
			weapon_deathtype = deathtype;
			weapon_action(w, WR_SUICIDEMESSAGE);
			bprint("^1", s, "^1 ", weapon_deathtypestring, "\n");
		} else if (deathtype == DEATH_KILL)
			bprint ("^1",s, "^1 couldn't take it anymore\n");
		else if (deathtype == DEATH_ROT)
			bprint ("^1",s, "^1 died\n");
		else if (deathtype == DEATH_NOAMMO)
			bprint ("^7",s, "^7 committed suicide. What's the point of living without ammo?\n");
		else if (deathtype == DEATH_MIRRORDAMAGE)
			bprint ("^1",s, "^1 didn't become friends with the Lord of Teamplay\n");
		else if (deathtype == DEATH_FIRE)
			bprint ("^1",s, "^1 burned to death\n");
		else if (deathtype != DEATH_TEAMCHANGE)
			bprint ("^1",s, "^1 couldn't resist the urge to self-destruct\n");

		if (deathtype != DEATH_TEAMCHANGE) {
			score_give_frag(attacker, targ, -1);
		}
		if (targ.killcount > 2)
			bprint ("^1",s,"^1 ended it all after a ",ftos(targ.killcount)," kill spree\n");
	} else if (attacker.classname == "player") {
		if not(clienttype(attacker) == CLIENTTYPE_REAL) {
			if (bot_talk)
			if (random() < bot_talk) {
				if (team_mode && attacker.team == targ.team)
					bot_say(attacker, FALSE, world, cvar_string("bot_messages_teamkill"), strcat(targ.netname, "^7: "));
				else
					bot_say(attacker, FALSE, world, cvar_string("bot_messages_frag"), strcat(targ.netname, "^7: "));
			}
			if (bot_taunt)
			if (random() <= bot_taunt) {
				entity oldself;
				oldself = self;
				self = attacker;
				player_voice_message("taunt", "");
				self = oldself;
			}
		}
		if not(clienttype(targ) == CLIENTTYPE_REAL)
		if (bot_talk)
		if (random() <= bot_talk) {
			if (team_mode && attacker.team == targ.team) {
				bot_say(targ, FALSE, world, cvar_string("bot_messages_teamkilled"), strcat(attacker.netname, "^7: "));
			} else {
				if (random() < 0.5)
					bot_say(targ, FALSE, world, cvar_string("bot_messages_fragged"), "");
				else
					bot_say(targ, FALSE, world, cvar_string("bot_messages_fragged_priv"), strcat(attacker.netname, "^7: "));
			}
		}
		if (team_mode && attacker.team == targ.team && !targ.saboteur) {
			centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s, ", a team mate!"));
			bprint ("^1", a, "^1 mows down a team mate\n");
			score_give_frag(attacker, targ, -1);
			if (targ.killcount > 2) {
				bprint ("^1",s,"'s ^1",ftos(targ.killcount)," kill spree was ended by a team mate!\n");
			}
			if (attacker.killcount > 2) {
				bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," kill spree by killing a team mate\n");
			}
			attacker.killcount = 0;
		} else {
			string blood_message, victim_message;
			if (!checkrules_firstblood) {
				checkrules_firstblood = TRUE;
				bprint("^1",a, "^1 drew first blood", "\n");
				blood_message = "^1First blood\n";
				victim_message = "^1First victim\n";  // or First casualty
				if (sv_announcer_extra_firstblood != "")
					announce(attacker, sv_announcer_extra_firstblood, "^5First ^1Blood");
			}
			w = DEATH_WEAPONOF(deathtype);
			if (WEP_VALID(w)) {
				weapon_deathtypestring = "was blasted by";
				weapon_deathtype = deathtype;
				weapon_action(w, WR_KILLMESSAGE);
				p = strstrofs(weapon_deathtypestring, "#", 0);
				if (p < 0)
					bprint("^1", s, "^1 ", weapon_deathtypestring, " ", a, "\n");
				else
					bprint("^1", s, "^1 ", substring(weapon_deathtypestring, 0, p), a, "^1", substring(weapon_deathtypestring, p+1, strlen(weapon_deathtypestring) - (p+1)), "\n");
			} else if (deathtype == DEATH_DROWN)
				bprint ("^1",s, "^1 was drowned by ", a, "\n");
			else if (deathtype == DEATH_SLIME)
				bprint ("^1",s, "^1 was slimed by ", a, "\n");
			else if (deathtype == DEATH_LAVA)
				bprint ("^1",s, "^1 was cooked by ", a, "\n");
			else if (deathtype == DEATH_FALL) {
				bprint ("^1",s, "^1 was grounded by ", a, "\n");
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag, "");
					announce(attacker, sv_announcer_extra_pushfrag, "");
				}
			} else if (deathtype == DEATH_SWAMP)
				bprint ("^1",s, "^1 was conserved by ", a, "\n");
			else if (deathtype == DEATH_HURTTRIGGER) {
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag, "");
					announce(attacker, sv_announcer_extra_pushfrag, "");
				}
				if (inflictor.message2 != "") {
					p = strstrofs(inflictor.message2, "#", 0);
					if (p < 0)
						bprint("^1", s, "^1 ", inflictor.message2, " ", a, "\n");
					else
						bprint("^1", s, "^1 ", substring(inflictor.message2, 0, p), a, "^1", substring(inflictor.message2, p+1, strlen(inflictor.message2) - (p+1)), "\n");
				}
			} else if (deathtype == DEATH_TURRET)
				bprint ("^1",s, "^1 was pushed into the line of fire by ^1", a, "\n");
			else if (deathtype == DEATH_FIRE)
				bprint ("^1",s, "^1 was burnt to death by ^1", a, "\n");
			else if not(gamehook_chain_player_obituary_frag(deathtype, targ, inflictor, attacker))
				bprint ("^1",s, "^1 was ", weapon_fragprefix, "^1fragged by ", a, "\n");

			if (g_spawnfrags && (targ.spawnshieldtime > time || attacker.spawnshieldtime > time)) {
				weapon_fragprefix = strcat("^3SPAWN", weapon_fragprefix);
			} else {
				score_give_frag(attacker, targ, 1);
			}
			if (targ.killcount > 2) {
				bprint ("^1",s,"'s ^1", ftos(targ.killcount), " kill spree was ended by ", a, "\n");
			}
			attacker.killcount = attacker.killcount + 1;
			if (attacker.killcount > 2) {
				bprint ("^1",a,"^1 has ",ftos(attacker.killcount)," frags in a row\n");
			}
			float fragtime = time;

			if (attacker.killcount == 3) {
				bprint (a,"^7 made a ^1TRIPLE FRAG\n");
				announce(attacker, "announcer/male/03kills.wav", "^1Triple Kill");
			} else if (attacker.killcount == 5) {
				bprint (a,"^7 unleashes ^1RAGE\n");
				announce(attacker, "announcer/male/05kills.wav", "^1Rage");
			} else if (attacker.killcount == 10) {
				bprint (a,"^7 starts the ^1MASSACRE!\n");
				announce(attacker, "announcer/male/10kills.wav", "^1MASSACRE");
			} else if (attacker.killcount == 15) {
				bprint (a,"^7 executes ^1MAYHEM!\n");
				announce(attacker, "announcer/male/15kills.wav", "^1MAYHEM!");
			} else if (attacker.killcount == 20) {
				bprint (a,"^7 is a ^1BERSERKER!\n");
				announce(attacker, "announcer/male/20kills.wav", "^1BERSERKER!");
			} else if (attacker.killcount == 25) {
				bprint (a,"^7 inflicts ^1CARNAGE!\n");
				announce(attacker, "announcer/male/25kills.wav", "^1CARNAGE!");
			} else if (attacker.killcount == 30) {
				bprint (a,"^7 unleashes ^1ARMAGEDDON!\n");
				announce(attacker, "announcer/male/30kills.wav", "^1ARMAGEDDON!!!");
			} else if (time - attacker.lastfrag < sv_announcer_extra_doublekill_interval && attacker.lastfrag && sv_announcer_extra_doublekill != "") {
					if (announce(attacker, sv_announcer_extra_doublekill, "^3Excellent"))
						fragtime = 0;
			}
			if (DEATH_ISWEAPON(deathtype, WEP_MELEE) && sv_announcer_extra_meleefrag != "") {
					announce(targ, sv_announcer_extra_meleefrag, "");
					announce(attacker, sv_announcer_extra_meleefrag, "");
			}
			centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ", weapon_fragprefix, "^4fragged ^7", s));
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ", weapon_fragprefix, "^1fragged by ^7", a));
			attacker.taunt_soundtime = time + 1;
			attacker.lastfrag = fragtime;
		}
	} else if (attacker.classname == "monster") {
		centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were fragged by ^7", attacker.netname));
		bprint ("^1",s, "^1 was killed by ", attacker.netname, "\n");
	} else {
		if not(clienttype(targ) == CLIENTTYPE_REAL)
		if (bot_talk)
		if (random() <= bot_talk)
			bot_say(targ, FALSE, world, cvar_string("bot_messages_suicide"), "");

		centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!"));
		if (deathtype == DEATH_HURTTRIGGER && inflictor.message != "")
			bprint ("^1",s, "^1 ", inflictor.message, "\n");
		else if (deathtype == DEATH_DROWN)
			bprint ("^1",s, "^1 drowned\n");
		else if (deathtype == DEATH_SLIME)
			bprint ("^1",s, "^1 was slimed\n");
		else if (deathtype == DEATH_LAVA)
			bprint ("^1",s, "^1 turned into hot slag\n");
		else if (deathtype == DEATH_FALL)
			bprint ("^1",s, "^1 hit the ground with a crunch\n");
		else if (deathtype == DEATH_SWAMP)
			bprint ("^1",s, "^1 is now conserved for centuries to come\n");
		else if (deathtype == DEATH_TURRET)
			bprint ("^1",s, "^1 was mowed down by a turret \n");
		else if (deathtype == DEATH_FIRE)
			bprint ("^1",s, "^1 burnt to death\n");
		else
			bprint ("^1",s, "^1 died\n");

		score_give_frag(targ, targ, -1);
		if (score_player_add(targ, SP_SCORE, 0) == -5) {
			announce(targ, "announcer/male/botlike.wav", "");
		}
		if (targ.killcount > 2)
			bprint ("^1",s,"^1 died with a ",ftos(targ.killcount)," kill spree\n");
	}
	targ.death_origin = targ.origin;
	// FIXME: this should go in client_put
	if (targ.killcount)
		targ.killcount = 0;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_damage {
	float take, save, waves, sdelay, dh, da;
	gamehook_chain_player_damage_mod = 1;
	if (gamehook_chain_player_damage_handle(inflictor, attacker, _damage, deathtype, hitloc, force))
		return;

	dh = max(self.health, 0);
	da = max(self.armorvalue, 0);
	_damage = _damage * gamehook_chain_player_damage_mod;
	if (DEATH_ISWEAPON(deathtype, WEP_TUBA)) {
		// tuba causes blood to come out of the ears
		vector ear1, ear2;
		vector d;
		float f;
		ear1 = self.origin;
		ear1_z += 0.125 * self.view_ofs_z + 0.875 * self.maxs_z; // 7/8
		ear2 = ear1;
		makevectors(self.angles);
		ear1 += v_right * -10;
		ear2 += v_right * +10;
		d = inflictor.origin - self.origin;
		f = (d * v_right) / vlen(d); // this is cos of angle of d and v_right!
		force = v_right * vlen(force);
		violence_gib_splash_at(ear1, force * -1, 2, bound(0, _damage, 25) / 2 * (0.5 - 0.5 * f), self, attacker);
		violence_gib_splash_at(ear2, force,      2, bound(0, _damage, 25) / 2 * (0.5 + 0.5 * f), self, attacker);
		if (f > 0) {
			hitloc = ear1;
			force = force * -1;
		} else {
			hitloc = ear2;
			// force is already good
		}
	} else
		violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);

	save = bound(0, _damage * gamehook_chain_ArmorBlockPercentMod() * g_balance_armor_blockpercent, self.armorvalue);
	take = bound(0, _damage - save, _damage);
	if (save > 10)
		sound (self, CHAN_PROJECTILE, "misc/armorimpact.wav", VOL_BASE, ATTN_NORM);
	else if (take > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (take > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM); // FIXME possibly remove them?

	if (take > 50)
		violence_gib_splash_at(hitloc, force * -0.1, 3, 1, self, attacker);

	if (take > 100)
		violence_gib_splash_at(hitloc, force * -0.2, 3, 1, self, attacker);

	if (time > self.spawnshieldtime || g_spawnfrags) {
		self.armorvalue = self.armorvalue - save;
		self.health = self.health - take;
		// pause regeneration for 5 seconds
		self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_health_regen);
		if (time > self.pain_finished) { //Don't switch pain sequences like crazy
			self.pain_finished = time + 0.5;	//Supajoe
			if (self.classname != "body") { // pain anim is BORKED on our ZYMs, FIXME remove this once we have good models
				if (random() > 0.5)
					anim_set(self.body, self.anim_pain1, FALSE, TRUE, TRUE);
				else
					anim_set(self.body, self.anim_pain2, FALSE, TRUE, TRUE);
			}
			// exclude pain sounds for laserjumps as long as you aren't REALLY low on health and would die of the next two
			if (!DEATH_ISWEAPON(deathtype, WEP_LASER) || attacker != self || self.health < 2 * g_balance_laser_primary_damage * g_balance_selfdamagepercent + 1) {
				if (self.health > 75) // TODO make a "gentle" version?
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain100), VOL_BASE, ATTN_NORM);
				else if (self.health > 50)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain75), VOL_BASE, ATTN_NORM);
				else if (self.health > 25)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain50), VOL_BASE, ATTN_NORM);
				else if (self.health > 1)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain25), VOL_BASE, ATTN_NORM);
			}
			// throw off bot aim temporarily
			float shake;
			shake = _damage * 5 / (bound(0,skill,100) + 1);
			self.v_angle_x = self.v_angle_x + (random() * 2 - 1) * shake;
			self.v_angle_y = self.v_angle_y + (random() * 2 - 1) * shake;
		}
	}
	self.dmg_save = self.dmg_save + save;//max(save - 10, 0);
	self.dmg_take = self.dmg_take + take;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;
	if (attacker == self) {
		// don't reset pushltime for self damage as it may be an attempt to
		// escape a lava pit or similar
		//self.pushltime = 0;
	} else if (attacker.classname == "player") {
		self.pusher = attacker;
		self.pushltime = time + g_maxpushtime;
	} else if (time < self.pushltime) {
		attacker = self.pusher;
		self.pushltime = max(self.pushltime, time + 0.6);
	} else
		self.pushltime = 0;

	if (self.health < 1)
	if not(gamehook_player_death_handle(attacker, inflictor, deathtype)) {
		float defer_client_kill_now_team_change;
		defer_client_kill_now_team_change = FALSE;
		float switchweapon_save = self.weapon;
		if (deathtype == DEATH_DROWN)
			sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_drown), VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_death), VOL_BASE, ATTN_NORM);

		// get rid of kill indicator
		if (self.killindicator) {
			if (self.killindicator.team)
				defer_client_kill_now_team_change = TRUE;

			if (self.classname == "body")
			if (deathtype == DEATH_KILL) {
				// for the lemmings fans, a small harmless explosion
				pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
			}
		}
        entity_drop_entities(self);
		// clear selected player display
		if not(gamehook_chain_player_death_weapon_throw_handle())
			weapon_throw(randomvec() * 125 + '0 0 200', (self.mins + self.maxs) * 0.5, FALSE);

		self.switchweapon = switchweapon_save;
		// print an obituary message
		player_obituary(attacker, inflictor, self, deathtype);
		if (sv_sound_frag != "")
		if (clienttype(attacker) == CLIENTTYPE_REAL)
		if (attacker != self)
		if (team_is_different_teams(attacker, self))
			sound_play2(attacker, sv_sound_frag);

		player_clear(TRUE);
		// make the corpse upright (not tilted)
		self.angles_x = 0;
		self.angles_z = 0;
		// don't spin
		self.avelocity = '0 0 0';
		// view from the floor
		self.view_ofs = '0 0 -8';
		// shootable corpse
		self.solid = SOLID_CORPSE;
		// don't stick to the floor
		self.flags &~= FL_ONGROUND;
		// dying animation
		self.deadflag = DEAD_DYING;
		// when to allow respawn
		sdelay = 0;
		waves = 0;
		if (g_respawn_mapsettings) {
			sdelay = g_respawn_mapsettings_delay;
			waves = g_respawn_mapsettings_waves;
		}
		if (!sdelay)
			sdelay = g_respawn_delay;

		if (!waves)
			waves = g_respawn_waves;

		if (waves)
			self.death_time = ceil((time + sdelay) / waves) * waves;
		else
			self.death_time = time + sdelay;

		if ((sdelay + waves >= 5.0) && (self.death_time - time > 1.75))
			self.respawn_countdown = 10; // first number to count down from is 10
		else
			self.respawn_countdown = -1; // do not count down

		if (random() < 0.5) {
			anim_set(self.body, self.anim_die1, FALSE, TRUE, TRUE);
			self.body.dead_frame = self.anim_dead1_x;
		} else {
			anim_set(self.body, self.anim_die2, FALSE, TRUE, TRUE);
			self.body.dead_frame = self.anim_dead2_x;
		}
		// set damage function to corpse damage
		self.event_damage = player_corpse_damage;
		// call the corpse damage function just in case it wants to gib
		self.event_damage(inflictor, attacker, 0, deathtype, hitloc, force);
		self.body.think = player_corpse_think;
		self.body.fade_time = time + 15;
		self.body.nextthink = time;
		if (clienttype(self) == CLIENTTYPE_REAL) {
			self.fixangle = TRUE;
			//msg_entity = self;
			//WriteByte (MSG_ONE, SVC_SETANGLE);
			//WriteAngle (MSG_ONE, self.v_angle_x);
			//WriteAngle (MSG_ONE, self.v_angle_y);
			//WriteAngle (MSG_ONE, 80);
		}
		if (defer_client_kill_now_team_change)
			client_kill_now_team_change(self, self.killindicator.team);
	}
}

string allvoicesamples;
float player_voice_message_sample_not_found;
float player_voice_message_sample_fixed;
stringfield(string type) player_voice_message_sample_field {
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch (type) {
#define _VOICEMSG(m) case #m: return playersound_##m;
	ALLVOICEMSGS
#undef _VOICEMSG
	}
	player_voice_message_sample_not_found = 1;
	return playersound_taunt;
}

stringfield(string type) player_sound_sample_field {
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch (type) {
#define _VOICEMSG(m) case #m: return playersound_##m;
	ALLPLAYERSOUNDS
#undef _VOICEMSG
	}
	player_voice_message_sample_not_found = 1;
	return playersound_taunt;
}

void(string f) player_precache_sounds {
	float fh;
	string s;
	fh = fopen(f, FILE_READ);
	if (fh < 0)
		return;

	while ((s = fgets(fh))) {
		if (tokenize_console(s) != 3)
			continue;

		sound_random_precache(argv(1), stof(argv(2)));
	}
	fclose(fh);
	if not(allvoicesamples) {
#define _VOICEMSG(m) allvoicesamples = strcat(allvoicesamples, " ", #m);
		ALLVOICEMSGS
#undef _VOICEMSG
		allvoicesamples = strzone(substring(allvoicesamples, 1, strlen(allvoicesamples) - 1));
	}
}

void() player_clear_sounds {
#define _VOICEMSG(m) if (self.playersound_##m) { strunzone(self.playersound_##m); self.playersound_##m = NULL; }
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

void(entity to, entity from) player_copy_sounds {
#define _VOICEMSG(m) to.playersound_##m = str_zone_ifneeded(from.playersound_##m);
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

void(string f, float first) player_load_sounds {
	float fh;
	string s;
	var .string field;
	fh = fopen(f, FILE_READ);
	if (fh < 0)
		return;

	while ((s = fgets(fh))) {
		if (tokenize_console(s) != 3)
			continue;

		field = player_sound_sample_field(argv(0));
		if (player_voice_message_sample_not_found)
			field = player_voice_message_sample_field(argv(0));

		if (player_voice_message_sample_not_found)
			continue;

		if (player_voice_message_sample_fixed)
			if not(first)
				continue;

		if (self.field)
			strunzone(self.field);

		self.field = strzone(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
}

.float modelindex_for_playersound;
void() player_update_sounds {
	if (self.body.modelindex_lod0 == self.body.modelindex_for_playersound)
		return;

	self.body.modelindex_for_playersound = self.body.modelindex_lod0;
	player_clear_sounds();
	player_load_sounds("sound/player/default.sounds", 1);
	player_load_sounds(strcat(self.body.model, ".sounds"), 0);
}

void(string type, string msg) player_voice_message {
	var .string sample;
	float ownteam;
	if (self.classname != "player")
		return;

	sample = player_voice_message_sample_field(type);
	if (player_voice_message_sample_not_found) {
		sprint(self, strcat("Invalid voice. Use one of: ", allvoicesamples, "\n"));
		return;
	}
	ownteam = (type != "taunt" && type != "teamshot");
	float flood;
	float flood_spv;
	var .float flood_field;
	flood = 0;
	if (ownteam) {
		flood_spv = g_voice_flood_spv_team;
		flood_field = floodcontrol_voiceteam;
	} else {
		flood_spv = g_voice_flood_spv;
		flood_field = floodcontrol_voice;
	}
	if (time >= self.flood_field)
		self.flood_field = max(time, self.flood_field) + flood_spv;
	else
		flood = 1;

	if (timeoutStatus == 2) //when game is paused, no flood protection
		self.flood_field = flood = 0;

	if (msg != "")
		chat_say(self, ownteam, world, msg, 0);

	if (flood)
		return;

	string s = sound_random_by_str(self.sample);
	if (type == "taunt") {
		if (self.classname == "player")
			if (self.deadflag == DEAD_NO)
				anim_set(self.body, self.anim_taunt, FALSE, TRUE, TRUE);
		if (!sv_taunt)
			return;

		FOR_EACH_REALCLIENT(msg_entity) {
			if (msg_entity.cvar_cl_voice_directional >= 1) {
				if (msg_entity == self || !self.body)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
				else
					sound_to(MSG_ONE, self.body.body, CHAN_VOICE, s, VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
			} else
				sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
		}
	} else if (type == "teamshoot") {
		if (self.pusher)
			if (self.pusher.team == self.team)
			{
				msg_entity = self.pusher;
				if (clienttype(msg_entity) == CLIENTTYPE_REAL)
				{
					if (msg_entity.cvar_cl_voice_directional == 1)
						sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
					else
						sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
				}
				msg_entity = self;
				if (clienttype(msg_entity) == CLIENTTYPE_REAL)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASE, ATTN_NONE);
			}
	} else {
		FOR_EACH_REALCLIENT(msg_entity)
			if (!team_mode || msg_entity.team == self.team)
			{
				if (msg_entity.cvar_cl_voice_directional == 1)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
				else
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
			}
	}
}

float(entity plr, entity viewer) player_alpha {
	plr = akimbo_owner(plr);
	float dalpha = 1;
	if (plr.classname == "observer") {
		if (plr == viewer) {
			return dalpha;
		}
		return -1;
	} else if (plr.classname == "spectator") {
		return -1;
	}
	if (plr.deadflag) {
		return dalpha;
	}
	if (viewer.classname == "spectator") {
		viewer = viewer.enemy;
	}
	float sa = gamehook_chain_player_alpha_mod(plr, viewer, dalpha);
	if (plr == viewer && sa < 0.01) {
		sa = 0.01;
	} else if (sa <= 0) {
		sa = -1;
	}
	return sa;
}

void(string modelname) player_setup_lod {
	string s;
	entity pl;
	FOR_EACH_PLAYER(pl)
		if (pl.body)
		if (pl.body.playermodel == modelname) {
			player_body_copy(self.body, pl.body, TRUE);
			player_anim_copy(self, pl);
			player_copy_sounds(self, pl);
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

	s = whichpack(self.body.model);
	str_unzone_ifneeded(self.body.playermodel);
	self.body.playermodel = str_zone_ifneeded(modelname); //need independent copy here
	self.body.modelindex_lod0_from_nexuiz = ((s == "") || (substring(s, 0, 4) == "data"));
	player_anim_setup();
	player_update_sounds();
}

string(void) player_allowed_model_list {
	if (team_mode)
	if (self.team > 0) {
		if (self.team == COLOR_TEAM1) {
			if (g_player_allowed_models_red != "")
				return g_player_allowed_models_red;
		} else if (self.team == COLOR_TEAM2) {
			if (g_player_allowed_models_blue != "")
				return g_player_allowed_models_blue;
		} else if (self.team == COLOR_TEAM3) {
			if (g_player_allowed_models_yellow != "")
				return g_player_allowed_models_yellow;
		} else if (self.team == COLOR_TEAM4) {
			if (g_player_allowed_models_pink != "")
				return g_player_allowed_models_pink;
		}
	}
	return g_player_allowed_models;
}

string(string _playermodel) player_allowed_model {
	string allowed_models = player_allowed_model_list();
	string first_allowed_model = str_car(allowed_models);
	if (first_allowed_model == "")
		return _playermodel;

	if (strstrofs(first_allowed_model, ":", 0) > 0) {
		first_allowed_model = substring(first_allowed_model, 0, strstrofs(first_allowed_model, ":", 0));
	}
	if (_playermodel == "")
		return first_allowed_model;

	if (strstrofs(strcat(" ", allowed_models, " "), strcat(" ", _playermodel, " "), 0) >= 0 ||
			strstrofs(strcat(" ", allowed_models), strcat(" ", _playermodel, ":"), 0) >= 0)
		return _playermodel;

	return first_allowed_model;
}

float(string _playermodel, float _skin) player_allowed_skin {
	string allowed_models = player_allowed_model_list();
	if (str_car(allowed_models) == "")
		return _skin;

	if (strstrofs(strcat(" ", allowed_models, " "), strcat(" ", _playermodel, " "), 0) >= 0 ||
			strstrofs(strcat(" ", allowed_models), strcat(" ", _playermodel, ":", ftos(_skin), " "), 0) >= 0)
		return _skin;

	float allowed_skin_pos = strstrofs(strcat(" ", allowed_models), strcat(" ", _playermodel, ":"), 0);
	if (allowed_skin_pos >= 0) {
		allowed_skin_pos = allowed_skin_pos + strlen(_playermodel) + 1;
		return stof(str_car(substring(allowed_models, allowed_skin_pos, -1)));
	}
	return _skin;
}

string(string _playermodel) player_check_model {
	string fallback = player_allowed_model("models/player/marine.zym");
	_playermodel = player_allowed_model(_playermodel);
	if (strlen(_playermodel) < 4)
		return fallback;
	
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

		if (_playermodel != strtolower(_playermodel))
			return fallback;

		if (!file_exists(_playermodel))
			return fallback;
	}
	return _playermodel;
}

void() player_setup_model {
	string forcemodel;
	float forceskin, forcecolor, chmdl, oldskin;
	vector m1, m2;
	if (team_mode) {
		forcemodel =
				((self.team == COLOR_TEAM1) ? g_player_forcemodel_red :
				((self.team == COLOR_TEAM2) ? g_player_forcemodel_blue :
				((self.team == COLOR_TEAM3) ? g_player_forcemodel_yellow :
				((self.team == COLOR_TEAM4) ? g_player_forcemodel_pink : g_player_forcemodel))));

		forceskin =
				((self.team == COLOR_TEAM1) ? g_player_forceskin_red :
				((self.team == COLOR_TEAM2) ? g_player_forceskin_blue :
				((self.team == COLOR_TEAM3) ? g_player_forceskin_yellow :
				((self.team == COLOR_TEAM4) ? g_player_forceskin_pink : g_player_forceskin))));

		forcecolor =
				((self.team == COLOR_TEAM1) ? g_player_forcecolor_red :
				((self.team == COLOR_TEAM2) ? g_player_forcecolor_blue :
				((self.team == COLOR_TEAM3) ? g_player_forcecolor_yellow :
				((self.team == COLOR_TEAM4) ? g_player_forcecolor_pink : g_player_forcecolor))));

		if (forcecolor < 0)
			forcecolor = (self.team - 1) * 17;
	} else {
		forceskin = g_player_forceskin;
		forcecolor = g_player_forcecolor;
		forcemodel = g_player_forcemodel;
	}
	if (forcemodel != "" && forcemodel != "0") {
		if (forcemodel != self.body.playermodel) {
			m1 = self.mins;
			m2 = self.maxs;
			player_setup_lod(forcemodel);
			setsize(self, m1, m2);
			chmdl = TRUE;
		}
		oldskin = self.skinindex;
		if (forceskin >= 0)
			self.skinindex = forceskin;
	} else {
		if (self.playermodel != "" || self.body.playermodel == "") {
			string s = player_check_model(self.playermodel);
			if (s != self.body.playermodel) {
				m1 = self.mins;
				m2 = self.maxs;
				player_setup_lod(player_check_model(self.playermodel));
				setsize(self, m1, m2);
				chmdl = TRUE;
			}
			self.playermodel = "";
		}
		oldskin = self.skinindex;
		if (self.playerskin != "") {
			self.skinindex = player_allowed_skin(self.playermodel, stof(self.playerskin));
			self.playerskin = "";
		}
		self.skinindex = (team_mode ? ((self.skinindex == 6) ? 6 : math_mod(self.skinindex, 3)) : self.skinindex); //what bad about skins 3, 4 and 5?
	}
	if (chmdl || oldskin != self.skinindex)
		player_species_setup();

	if (forcecolor > -2) {
		float colors = gamehook_chain_player_colors_mod(forcecolor);
		if (self.clientcolors != colors)
			player_set_colors(self, colors);
	}
	self.body.colormap = self.colormap;
}

void(entity player) player_to_spec {
	if (player.classname == "player" || (player.classname == "spectator" && player.team >= 0))
	if not(g_campaign)
	if not(gamehook_forbid_specatators()) {
		entity oldself = self;
		self = player;
		player_clear(FALSE);
		player.classname = "observer";
		if (spectator_block)
			sprint(player, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));

		client_put();
		score_touch(player);
		self = oldself;
		spectator_note_update();
		if (team_mode)
			team_balance_audit(FALSE);

		player_leave();
	}
}

float(float current, float stable, float regenfactor, float regenframetime) player_calc_regen {
	if (current > stable)
		return current;

	if (current > stable - 0.25) // when close enough, "snap"
		return stable;

	return min(stable, current + (stable - current) * regenfactor * regenframetime);
}

float(float current, float stable, float rotfactor, float rotframetime) player_calc_rot {
	if (current < stable)
		return current;

	if (current < stable + 0.25) // when close enough, "snap"
		return stable;

	return max(stable, current + (stable - current) * rotfactor * rotframetime);
}

float(float current, float regenstable, float regenfactor, float regenlinear, float regenframetime, float rotstable, float rotfactor, float rotlinear, float rotframetime, float limit) player_calc_rot_regen {
	if (current > rotstable) {
		if (rotframetime > 0) {
			current = player_calc_rot(current, rotstable, rotfactor, rotframetime);
			current = max(rotstable, current - rotlinear * rotframetime);
		}
	} else if (current < regenstable) {
		if (regenframetime > 0) {
			current = player_calc_regen(current, regenstable, regenfactor, regenframetime);
			current = min(regenstable, current + regenlinear * regenframetime);
		}
	}
	if (current > limit)
		current = limit;

	return current;
}

void() player_respawn_countdown {
	float number;
	if (self.deadflag == DEAD_NO) // just respawned?
		return;

	number = ceil(self.death_time - time);
	if (number <= 0)
		return;

	if (number <= self.respawn_countdown) {
		self.respawn_countdown = number - 1;
		if (ceil(self.death_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
			announce(self, strcat("announcer/robotic/", ftos(number), ".wav"), "");
	}
}


void() player_regen {
	float minh, maxh, limith, limita;
	gamehook_player_health_armor_rot_regen = gamehook_player_health_max_mod = gamehook_player_armor_health_limit_mod = gamehook_player_regen_mod = gamehook_player_rot_mod = 1;
	gamehook_chain_player_health_armor_fuel_mods_set();
	if (gamehook_player_health_armor_rot_regen) {
		limith = g_balance_health_limit * gamehook_player_armor_health_limit_mod;
		maxh = g_balance_health_rotstable * gamehook_player_health_max_mod;
		minh = g_balance_health_regenstable * gamehook_player_health_max_mod;
		self.health = player_calc_rot_regen(self.health, minh, g_balance_health_regen, g_balance_health_regenlinear, gamehook_player_regen_mod * frametime * (time > self.pauseregen_finished), maxh, g_balance_health_rot, g_balance_health_rotlinear, gamehook_player_rot_mod * frametime * (time > self.pauserothealth_finished), limith);
		// if player rotted to death...  die!
		if (self.health < 1)
			self.event_damage(self, self, 1, DEATH_ROT, self.origin, '0 0 0');

		limita = g_balance_armor_limit * gamehook_player_armor_health_limit_mod;
		self.armorvalue = player_calc_rot_regen(self.armorvalue, g_balance_armor_regenstable, g_balance_armor_regen, g_balance_armor_regenlinear, gamehook_player_regen_mod * frametime * (time > self.pauseregen_finished), g_balance_armor_rotstable, g_balance_armor_rot, g_balance_armor_rotlinear, gamehook_player_rot_mod * frametime * (time > self.pauserotarmor_finished), limita);
	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel = player_calc_rot_regen(self.ammo_fuel, g_balance_fuel_regenstable, g_balance_fuel_regen, g_balance_fuel_regenlinear, gamehook_player_regen_mod * frametime * (time > self.pauseregen_finished) * (self.items & IT_FUEL_REGEN != 0), g_balance_fuel_rotstable, g_balance_fuel_rot, g_balance_fuel_rotlinear, gamehook_player_rot_mod * frametime * (time > self.pauserotfuel_finished), g_balance_fuel_limit);
}

.float items_added;
void() player_think {
	if (self.deadflag == DEAD_NO)
	if not(map_finished)
	if not(warmup_active)
		self.play_time = self.play_time + frametime;

	if (self.teleport_time)
	if (time > self.teleport_time) {
		self.teleport_time = 0;
		self.effects = self.effects - (self.effects & EF_NODRAW);
	}
	//don't allow the player to turn around while game is paused!
	if (timeoutStatus == 2) {
		self.v_angle = self.lastV_angle;
		self.angles = self.lastV_angle;
		self.fixangle = TRUE;
	}
	gamehook_chain_player_think();
	if (frametime) {
		fire_apply_damage(self);
		player_effects();
	}
	if (PLAYER_REALLY_DEAD(self)) {
		float button_pressed;
		if (frametime)
			player_anim();

		button_pressed = (self.BUTTON_ATCK || self.BUTTON_JUMP || self.BUTTON_ATCK2 || self.BUTTON_HOOK || self.BUTTON_USE);
		if (self.deadflag == DEAD_DYING) {
			if (g_forced_respawn)
				self.deadflag = DEAD_RESPAWNING;
			else if (!button_pressed)
				self.deadflag = DEAD_DEAD;
		} else if (self.deadflag == DEAD_DEAD) {
			if (button_pressed)
				self.deadflag = DEAD_RESPAWNABLE;
		} else if (self.deadflag == DEAD_RESPAWNABLE) {
			if (!button_pressed)
				self.deadflag = DEAD_RESPAWNING;
		} else if (self.deadflag == DEAD_RESPAWNING) {
			if (time > self.death_time) {
				self.death_time = time + 1; // only retry once a second
				player_respawn();
			}
		}
		player_respawn_countdown();
		return;
	}
	player_setup_model();
	weapon_frame();
	akimbo_weapon_frame();
	if (frametime) {
		self.items &~= self.items_added;
		self.items_added = 0;
		if (self.items & IT_JETPACK)
			if (self.items & IT_FUEL_REGEN || self.ammo_fuel > 0 || !g_jetpack_fuel)
				self.items_added |= IT_FUEL;

		self.items |= self.items_added;
		player_regen();
		player_anim();
	}
	self.dmg_team = max(0, self.dmg_team - g_teamdamage_resetspeed * frametime);
	if (self.teamkill_soundtime)
	if (time > self.teamkill_soundtime) {
		self.teamkill_soundtime = 0;
		entity oldpusher, oldself;
		oldself = self; self = self.teamkill_soundsource;
		oldpusher = self.pusher; self.pusher = oldself;
		if (self.pusher)
		if (self.pusher.team == self.team) {
			msg_entity = self.pusher;
			if (clienttype(msg_entity) == CLIENTTYPE_REAL) {
				if (msg_entity.cvar_cl_voice_directional == 1)
					sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_MIN);
				else
					sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_NONE);
			}
		}
		self.pusher = oldpusher;
		self = oldself;
	}
	if (self.taunt_soundtime)
	if (time > self.taunt_soundtime) {
		self.taunt_soundtime = 0;
		if (sv_taunt)
		if (sv_autotaunt) {
			float tauntrand = random();
			FOR_EACH_REALCLIENT(msg_entity)
				if (tauntrand < msg_entity.cvar_cl_autotaunt)
				{
					if (msg_entity.cvar_cl_voice_directional >= 1)
						sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_taunt), VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
					else
						sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_taunt), VOL_BASEVOICE, ATTN_NONE);
				}
		}
	}
}

/*
 * Impulse map:
 *
 * 0 reserved (no input)
 * 1 to 9, 14: weapon shortcuts
 * 10: next weapon according to linear list
 * 11: most recently used weapon
 * 12: previous weapon according to linear list
 * 13: best weapon according to priority list
 * 15: next weapon according to priority list
 * 16: previous weapon according to priority list
 * 17: throw weapon
 * 18: next weapon according to sbar_hudselector 1 list
 * 19: previous weapon according to sbar_hudselector 1 list
 * 20: reload if needed
 *
 * 30 to 39: create waypoints
 * 47: clear personal waypoints
 * 48: clear team waypoints
 *
 * TODO:
 * 200 to 209: prev weapon shortcuts
 * 210 to 219: best weapon shortcuts
 * 220 to 229: next weapon shortcuts
 * 230 to 253: individual weapons (up to 24)
 */
void(void) player_impulse {
	float imp;
	vector org;
	float i;
	float m;
	entity e, e2;
	imp = self.impulse;
	if (!imp || map_finished)
		return;
	self.impulse = 0;

	if (timeoutStatus == 2) //don't allow any impulses while the game is paused
		return;

	if (imp >= 1 && imp <= 9) {
		// weapon switching impulses
		if (self.deadflag == DEAD_NO)
			weapon_next_on_impulse(imp);
		else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 10 && imp <= 20) {
		if (self.deadflag == DEAD_NO) {
			switch (imp) {
			case 10:
				weapon_next(0);
				break;
			case 11:
				weapon_switch(self.cnt); // previously used
				break;
			case 12:
				weapon_previous(0);
				break;
			case 13:
				weapon_switch(weapon_best(self));
				break;
			case 14:
				weapon_next_on_impulse(0);
				break;
			case 15:
				weapon_next(2);
				break;
			case 16:
				weapon_previous(2);
				break;
			case 17:
				if not(gamehook_chain_ThrowWeaponHandle())
					weapon_throw(weapon_calculate_projectile_velocity(self.velocity, v_forward * 750), '0 0 0', TRUE);

				break;
			case 18:
				weapon_next(1);
				break;
			case 19:
				weapon_previous(1);
				break;
			case 20:
				weapon_reload();
				break;
			}
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 200 && imp <= 229) {
		if (self.deadflag == DEAD_NO) {
			// custom order weapon cycling
			i = math_mod(imp, 10);
			m = (imp - (210 + i)); // <0 for prev, =0 for best, >0 for next
			weapon_cycle(self.(cvar_cl_weaponpriorities[i]), m);
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 230 && imp <= 253) {
		if (self.deadflag == DEAD_NO) {
			weapon_switch(imp - 230 + WEP_FIRST);
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 30 && imp <= 49) { // deploy waypoints
		entity wp;
		switch (imp) {
		case 30:
			wp = WaypointSprite_DeployPersonal("waypoint", self.origin);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
				WaypointSprite_Ping(wp);
			}
			sprint(self, "personal waypoint spawned at location\n");
			break;
		case 31:
			wp = WaypointSprite_DeployPersonal("waypoint", self.cursor_trace_endpos);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
				WaypointSprite_Ping(wp);
			}
			break;
		case 32:
			if (vlen(self.death_origin)) {
				wp = WaypointSprite_DeployPersonal("waypoint", self.death_origin);
				if (wp) {
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "personal waypoint spawned at death location\n");
			}
			break;
		case 33:
			if (self.deadflag == DEAD_NO && team_mode) {
				wp = WaypointSprite_Attach("helpme", TRUE);
				if (wp)
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HELPME, '1 0.5 0'); // TODO choose better color

				if (!wp)
					wp = self.waypointsprite_attachedforcarrier; // flag sprite?

				if (wp)
					WaypointSprite_Ping(wp);

				sprint(self, "HELP ME attached\n");
			}
			break;
		case 34:
			wp = WaypointSprite_DeployFixed("here", FALSE, self.origin);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
				WaypointSprite_Ping(wp);
			}
			sprint(self, "HERE spawned at location\n");
			break;
		case 35:
			wp = WaypointSprite_DeployFixed("here", FALSE, self.cursor_trace_endpos);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
				WaypointSprite_Ping(wp);
			}
			break;
		case 36:
			if (vlen(self.death_origin)) {
				wp = WaypointSprite_DeployFixed("here", FALSE, self.death_origin);
				if (wp) {
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "HERE spawned at death location\n");
			}
			break;
		case 37:
			wp = WaypointSprite_DeployFixed("danger", FALSE, self.origin);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
				WaypointSprite_Ping(wp);
			}
			sprint(self, "DANGER spawned at location\n");
			break;
		case 38:
			wp = WaypointSprite_DeployFixed("danger", FALSE, self.cursor_trace_endpos);
			if (wp) {
				WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
				WaypointSprite_Ping(wp);
			}
			break;
		case 39:
			if (vlen(self.death_origin)) {
				wp = WaypointSprite_DeployFixed("danger", FALSE, self.death_origin);
				if (wp) {
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "DANGER spawned at death location\n");
			}
			break;
		case 47:
			WaypointSprite_ClearPersonal();
			sprint(self, "personal waypoint cleared\n");
			break;
		case 48:
			WaypointSprite_ClearOwned();
			sprint(self, "all waypoints cleared\n");
			break;
		}
	} else if (imp >= 103 && imp <= 107) {
		if (g_waypointeditor) {
			switch (imp) {
			case 103:
				waypoint_schedulerelink(waypoint_spawn(self.origin, self.origin, 0));
				bprint(strcat("Waypoint spawned at ",vtos(self.origin),"\n"));
				break;
			case 104:
				e = navigation_findnearestwaypoint(self, FALSE);
				if (e)
				if not(e.wpflags & WAYPOINTFLAG_GENERATED) {
					bprint(strcat("Waypoint removed at ",vtos(e.origin),"\n"));
					waypoint_remove(e);
				}
				break;
			case 105:
				waypoint_schedulerelinkall();
				break;
			case 106:
				waypoint_saveall();
				break;
			case 107:
				for (e = findchain(classname, "waypoint"); e; e = e.chain) {
					e.colormod_x = 1;
					e.effects &~= EF_NODEPTHTEST | EF_RED | EF_BLUE;
				}
				e2 = navigation_findnearestwaypoint(self, FALSE);
				navigation_markroutes(e2);
				i = 0;
				m = 0;
				for (e = findchain(classname, "waypoint"); e; e = e.chain) {
					if (e.wpcost >= 10000000) {
						print("unreachable: ", etos(e), " ", vtos(e.origin), "\n");
						e.colormod_x = 0.1;
						e.effects |= EF_NODEPTHTEST | EF_BLUE;
						++i;
						++m;
					}
				}
				if (i)
					print(ftos(i), " waypoints cannot be reached from here in any way (marked with blue light)\n");

				navigation_markroutes_inverted(e2);
				i = 0;
				for (e = findchain(classname, "waypoint"); e; e = e.chain) {
					if (e.wpcost >= 10000000) {
						print("cannot reach me: ", etos(e), " ", vtos(e.origin), "\n");
						e.colormod_x = 0.1;
						if not(e.effects & EF_NODEPTHTEST) // not already reported before
							++m;
						e.effects |= EF_NODEPTHTEST | EF_RED;
						++i;
					}
				}
				if (i)
					print(ftos(i), " waypoints cannot walk to here in any way (marked with red light)\n");

				if (m)
					print(ftos(m), " waypoints have been marked total\n");

				i = 0;
				for (e = findchain(classname, "info_player_deathmatch"); e; e = e.chain) {
					org = e.origin;
					trace_box(e.origin, PL_MIN, PL_MAX, e.origin - '0 0 512', TRACE_MOVE_NOMONSTERS, world);
					setorigin(e, trace_endpos);
					if (navigation_findnearestwaypoint(e, FALSE)) {
						setorigin(e, org);
						e.effects &~= EF_NODEPTHTEST;
						e.model = "";
					} else {
						setorigin(e, org);
						print("spawn without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
						e.effects |= EF_NODEPTHTEST;
						setmodel(e, self.body.model);
						e.frame = self.body.frame;
						e.skin = self.body.skin;
						setsize(e, '0 0 0', '0 0 0');
						++i;
					}
				}
				if (i)
					print(ftos(i), " spawnpoints have no nearest waypoint (marked by player model)\n");

				break;
			}
		}
	}
}


void() player_post_think {
	entity bb = self.body.body;
	if (bb) {
		setorigin(bb, self.origin);
		bb.angles = self.angles;
		bb.effects = self.effects;
		bb.health = self.health; //for entcs
		bb.armorvalue = self.armorvalue; //for entcs
		setsize(bb, self.mins, self.maxs);
	}
	if (self.impulse)
		player_impulse();

	if (map_intermission_running)
		return;		// intermission or finale

	self.pressedkeys = 0;
	if (self.movement_x > 0)
		self.pressedkeys |= KEY_FORWARD;
	else if (self.movement_x < 0)
		self.pressedkeys |= KEY_BACKWARD;

	if (self.movement_y > 0)
		self.pressedkeys |= KEY_RIGHT;
	else if (self.movement_y < 0)
		self.pressedkeys |= KEY_LEFT;

	self.pressedkeys = self.pressedkeys + ((self.BUTTON_JUMP ? KEY_JUMP : 0) + (self.BUTTON_CROUCH ? KEY_CROUCH : 0));
}

float(void) player_real_customize {
	if (other.enemy == self)
	if (other.classname == "spectator")
		return TRUE;

	if (other == self)
		return TRUE;

	return FALSE;
}

float(void) player_customize {
	self.alpha = player_alpha(self.owner, other);
	if (self.alpha < 0)
		return FALSE;

	if (self.owner == other)
		return FALSE;
	else if (self.owner == other.enemy && other.classname == "spectator")
		self.exteriormodeltoclient = other;
	else
		self.exteriormodeltoclient = world;

	if (gamehook_chain_PlayerVisibleThroughWallFor(self.owner, other))
		self.effects |= EF_NODEPTHTEST;
	else
		self.effects &~= EF_NODEPTHTEST;

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
	if (gamehook_chain_PlayerVisibleThroughWallFor(o, other))
		self.effects |= EF_NODEPTHTEST;
	else
		self.effects &~= EF_NODEPTHTEST;

	if (!self.modelindex && PLAYER_REALLY_DEAD(o))
		return TRUE;

	modelsource = self;
#ifdef ALLOW_FORCEMODELS
	if (other.cvar_cl_forceplayermodelsfromnexuiz)
		if not(self.modelindex_lod0_from_nexuiz)
			modelsource = other.body;

	if (other.cvar_cl_forceplayermodels && sv_clforceplayermodels)
		modelsource = other.body;
#endif
	self.skin = modelsource.owner.skinindex;
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

void(entity pl) player_body_setup {
	pl.movetype = MOVETYPE_QCWALK;
	pl.solid = SOLID_SLIDEBOX;
	pl.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | (g_playerclip_collisions ? DPCONTENTS_PLAYERCLIP : 0);
	if (player_independent)
		PLAYER_MAKE_INDEPENDENT(pl);

	if (team_mode)
	if (g_sideview || !g_player_team_collisions)
		pl.clipgroup = pl.team;
}

float player_real_count;
void(entity spot) player_spawn {
	entity oldself, oldother;
	player_clear(FALSE);
	self.iscreature = TRUE;
	player_body_setup(self);
	self.flags = FL_CLIENT;
	self.takedamage = DAMAGE_AIM;
	self.effects = 0;
	self.air_finished = time + 12;
	self.keys = 0;
	self.touch = push_touch;
	self.pushfactor = g_player_pushfactor;
	if not(self.body)
		player_body_spawn(world);

	self.body.nextthink = 0;
	setmodel(self, "null");
	if not(gamehook_chain_player_equip_handle()) {
		self.ammo_shells = player_start_ammo_shells;
		self.ammo_nails = player_start_ammo_nails;
		self.ammo_rockets = player_start_ammo_rockets;
		self.ammo_cells = player_start_ammo_cells;
		self.ammo_fuel = player_start_ammo_fuel;
		self.health = player_start_health;
		self.armorvalue = player_start_armorvalue;
		self.weapons = player_start_weapons;
	}
	self.items = player_start_items;
	if (!self.switchweapon || !player_hasweapon(self, self.switchweapon, TRUE, FALSE))
		self.switchweapon = weapon_best(self);

	if (!self.cnt || self.cnt == self.switchweapon || !player_hasweapon(self, self.cnt, TRUE, FALSE)) {
		self.cnt = weaypon_cycle_get(self, self.cvar_cl_weaponpriority, -1, -1, 0);
	}
	self.weapon = 0;
	self.spawnshieldtime = time + g_spawnshieldtime;
	self.pauserotarmor_finished = time + g_balance_pause_armor_rot_spawn;
	self.pauserothealth_finished = time + g_balance_pause_health_rot_spawn;
	self.pauserotfuel_finished = time + g_balance_pause_fuel_rot_spawn;
	self.pauseregen_finished = time + g_balance_pause_health_regen_spawn;
	//extend the pause of rotting if client was reset at the beginning of the countdown
	if (!map_restart_active && time < map_starttime) {
		self.spawnshieldtime += map_starttime - time;
		self.pauserotarmor_finished += map_starttime - time;
		self.pauserothealth_finished += map_starttime - time;
		self.pauseregen_finished += map_starttime - time;
	}
	self.damageforcescale = 2;
	self.death_time = 0;
	self.dead_frame = 0;
	self.alpha = 0;
	self.fade_time = 0;
	self.pain_frame = 0;
	self.pain_finished = 0;
	self.pushltime = 0;
	self.think = NULL;
	self.nextthink = 0;
	self.dmg_team = 0;
	client_put_to_spot(spot);
	physics_mark_as_teleported(self, 0);
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.punchvector = '0 0 0';
	self.oldvelocity = self.velocity;
	self.waterlevel = 0; //prevent wrong waterlevel handing in server frame for bots
	self.fire_endtime = -1;
	msg_entity = self;
	self.customizeentityforclient = player_real_customize;
	player_setup_model();
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
	self.event_damage = player_damage;
	self.bot_attack = TRUE;
	self.statdraintime = time + 5;
	self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = 0;
	if (self.killcount == -666) {
		rank_distribute(self);
		score_clear(self);
		self.killcount = 0;
	}
	weapon_model_spawn();
	self.alpha = 1;
	self.colormod = '1 1 1' * g_player_brightness;
	if (g_spawnsound)
		sound (self, CHAN_TRIGGER, "misc/spawn.wav", VOL_BASE, ATTN_NORM);

	oldself = self;
	oldother = other;
	self = spot;
	other = spot;
	activator = oldself;
	trigger_use_targets();
	activator = world;
	self = oldself;
	other = oldother;
	player_effects();
	gamehook_chain_spawn(spot);
	antilag_teleported(self);
	self.wasplayer = TRUE;
	entity e;
	float n;
	FOR_EACH_REALPLAYER(e) n++;
	if not(warmup_active)
	if not(map_finished)
	if (n > player_real_count)
	if (g_reset_on_join)
	if (n == g_reset_on_join) {
		ready_restart();
	}
	player_real_count = n;
}

void(void) player_leave {
	float n;
	entity e;
	FOR_EACH_REALPLAYER(e) n++;
	if not(warmup_active)
	if not(map_finished)
	if (n < player_real_count)
	if (g_endmatch_on_leave)
	if (n <= g_endmatch_on_leave) {
		cvar_set("timelimit", "-1");
	}
	player_real_count = n;
}

void(string pattern) player_precache_all_models {
	float globhandle, i, n;
	string s, f;
	globhandle = search_begin(pattern, TRUE, FALSE);
	if (globhandle < 0)
		return;

	n = search_getsize(globhandle);
	for (i = 0; i < n; ++i) {
		f = search_getfilename(globhandle, i);
		precache_model(f);
		s = substring(f, -9,5);
		if (s != "_lod1")
		if (s != "_lod2")
			player_precache_sounds(strcat(f, ".sounds"));
	}
	search_end(globhandle);
}

float(entity plr, float wep) player_can_fire {
	if (PLAYER_DEAD(plr))
		return FALSE;

	if (time < map_starttime)
	if (!map_restart_active)
		return FALSE;

	if (timeoutStatus == 2) //don't allow the player to shoot while game is paused
		return FALSE;

	return gamehook_chain_PlayerCanFire(plr, wep);
}

.float hasweapon_complain_spam;
float(entity cl, float wpn, float andammo, float complain) player_hasweapon {
	float weaponbit, f;
	entity oldself;
	if (time < cl.hasweapon_complain_spam)
		complain = 0;

	if (complain)
		cl.hasweapon_complain_spam = time + 0.2;

	if (wpn < WEP_FIRST || wpn > WEP_LAST) {
		if (complain)
			sprint(cl, "Invalid weapon\n");
		return FALSE;
	}
	weaponbit = weapon_bit(wpn);
	if (cl.weapons & weaponbit) {
		if (andammo) {
			if (cl.items & IT_UNLIMITED_WEAPON_AMMO) {
				f = 1;
			} else {
				oldself = self;
				self = cl;
				f = weapon_action(wpn, WR_CHECKAMMO1);
				f = f + weapon_action(wpn, WR_CHECKAMMO2);
				self = oldself;
			}
			if (!f) {
				if (complain)
				if (clienttype(cl) == CLIENTTYPE_REAL) {
					sound_play2(cl, "weapons/unavailable.wav");
					sprint(cl, strcat("You don't have any ammo for the ^2", weapon_name(wpn), "\n"));
				}
				return FALSE;
			}
		}
		return TRUE;
	}
	if (complain)
	if (clienttype(cl) == CLIENTTYPE_REAL) {
		// DRESK - 3/16/07
		// Report Proper Weapon Status / Modified Weapon Ownership Message
		if (weapon_spawned_list & weaponbit) {
			sprint(cl, strcat("You do not have the ^2", weapon_name(wpn), "\n") );
			if (self.cvar_cl_showweaponspawns) {
				entity e;
				string s;
				e = weapon_info(wpn);
				s = e.model2;
				for (e = weapon_spawn_chain; e; e = e.enemy) {
					if (e.weapons != weaponbit)
						continue;

					WaypointSprite_Spawn(
						s,
						1, 0,
						world, e.origin,
						cl, 0,
						world, enemy,
						0
					);
				}
			}
		} else
			sprint(cl, "Requested weapon is ^1NOT AVAILABLE^7 in this map\n");

		sound_play2(cl, "weapons/unavailable.wav");
	}
	return FALSE;
}

// decolorizes and team colors the player name when needed
string(entity p) player_name {
    string t;
    if (team_mode && !map_intermission_running && p.classname == "player") {
        t = team_color_code(p.team);
        return strcat(t, strdecolorize(p.netname));
    } else
        return p.netname;
}

void(entity pl, float _color) player_set_colors {
	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;
	float t = pl.team;
	if (team_mode)
		setcolor(pl, 16*pants + pants);
	else
		setcolor(pl, shirt + pants);

	pl.team = t;
}

void(entity pl, float t, float s, float noprint) player_set_team {
	float _team = team_from_index(t - 1);
	if (!_team)
		return;

	pl.team = _team;
	if (!noprint && t != s) {
		//bprint(pl.netname, " has changed to ", team_name_by_no(t), "\n");
		bprint(pl.netname, "^7 has changed from ", team_name_by_no(s), " to ", team_name_by_no(t), "\n");
	}
	score_touch(pl);
}

entity(entity pl) player_entity {
	if (pl.classname == "player")
		return gamehook_chain_player_entity(pl);

	return pl;
}

void(entity e, float chan, string s, float vol, float attn) player_sound {
	FOR_EACH_REALCLIENT(msg_entity) {
		if (msg_entity == e)
			sound_to_at(MSG_ONE, e, e.origin, chan, s, vol, attn);
		else
			sound_to_at(MSG_ONE, e.body.body, e.origin, chan, s, vol, attn);
	}
}

var float(string s, float i) player_cmd_client_handle_next;
float(string s, float i) player_cmd_client_handle {
	if (s == "modelselect") {
		if (g_player_forcemodel != "" && g_player_forcemodel != "0") {
			centerprint(self, "Player model forced");
		} else {
			msg_entity = self;
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_MODELSELECT);
			WriteString(MSG_ONE, self.body.playermodel);
			WriteByte(MSG_ONE, stof(self.body.playerskin));
			WriteString(MSG_ONE, player_allowed_model_list());
		}
		return TRUE;
	}
	return player_cmd_client_handle_next(s, i);
}

var void(void(string item, string cmd) Add_Item) player_gamemenu_add_items_next;
void(void(string item, string cmd) add) player_gamemenu_add_items {
	if (g_player_forcemodel == "" || g_player_forcemodel == "0")
		add("Change model", "cmd modelselect;");

	player_gamemenu_add_items_next(add);
}

float player_init_done;
void() player_init {
	player_precache_sounds("sound/player/default.sounds");
	player_precache_all_models("models/player/*.zym");
	player_precache_all_models("models/player/*.dpm");
	player_precache_all_models("models/player/*.md3");
	player_precache_all_models("models/player/*.psk");
	CVAR_CACHE(g_respawn_delay);
	CVAR_CACHE(g_respawn_mapsettings);
	CVAR_CACHE(g_respawn_mapsettings_delay);
	CVAR_CACHE(g_respawn_mapsettings_waves);
	CVAR_CACHE(g_respawn_waves);
	CVAR_CACHE(g_voice_flood_spv);
	CVAR_CACHE(g_voice_flood_spv_team);
	CVAR_CACHE(g_fullbrightplayers);
	CVAR_CACHE_STR(g_player_allowed_models);
	CVAR_CACHE_STR(g_player_allowed_models_red);
	CVAR_CACHE_STR(g_player_allowed_models_blue);
	CVAR_CACHE_STR(g_player_allowed_models_yellow);
	CVAR_CACHE_STR(g_player_allowed_models_pink);
	CVAR_CACHE_STR(g_player_forcemodel);
	CVAR_CACHE_STR(g_player_forcemodel_red);
	CVAR_CACHE_STR(g_player_forcemodel_blue);
	CVAR_CACHE_STR(g_player_forcemodel_yellow);
	CVAR_CACHE_STR(g_player_forcemodel_pink);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_red, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_blue, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_yellow, -2);
	CVAR_CACHE_CHECK_EMPTY(g_player_forcecolor_pink, -2);
	CVAR_CACHE(g_player_forceskin);
	CVAR_CACHE(g_player_forceskin_red);
	CVAR_CACHE(g_player_forceskin_blue);
	CVAR_CACHE(g_player_forceskin_yellow);
	CVAR_CACHE(g_player_forceskin_pink);
	CVAR_CACHE(g_balance_armor_blockpercent);
	CVAR_CACHE(g_balance_armor_regen);
	CVAR_CACHE(g_balance_armor_regenlinear);
	CVAR_CACHE(g_balance_armor_regenstable);
	CVAR_CACHE(g_balance_armor_rot);
	CVAR_CACHE(g_balance_armor_rotlinear);
	CVAR_CACHE(g_balance_armor_rotstable);
	CVAR_CACHE(g_balance_armor_limit);
	CVAR_CACHE(g_balance_fuel_limit);
	CVAR_CACHE(g_balance_fuel_regen);
	CVAR_CACHE(g_balance_fuel_regenlinear);
	CVAR_CACHE(g_balance_fuel_regenstable);
	CVAR_CACHE(g_balance_fuel_rot);
	CVAR_CACHE(g_balance_fuel_rotlinear);
	CVAR_CACHE(g_balance_fuel_rotstable);
	CVAR_CACHE(g_balance_health_limit);
	CVAR_CACHE(g_balance_health_regen);
	CVAR_CACHE(g_balance_health_regenlinear);
	CVAR_CACHE(g_balance_health_regenstable);
	CVAR_CACHE(g_balance_health_rot);
	CVAR_CACHE(g_balance_health_rotlinear);
	CVAR_CACHE(g_balance_health_rotstable);
	CVAR_CACHE(g_balance_pause_armor_rot_spawn);
	CVAR_CACHE(g_balance_pause_fuel_rot_spawn);
	CVAR_CACHE(g_balance_pause_health_regen_spawn);
	CVAR_CACHE(g_balance_pause_health_rot_spawn);
	CVAR_CACHE(g_forced_respawn);
	CVAR_CACHE(g_teamdamage_resetspeed);
	CVAR_CACHE(g_reset_on_join);
	CVAR_CACHE(g_player_brightness);
	CVAR_CACHE(g_player_pushfactor);
	CVAR_CACHE(g_player_body_pitch_maxangle);
	CVAR_CACHE(g_player_team_collisions);
	CVAR_CACHE(g_spawnshieldtime);
	CVAR_CACHE(g_spawnfrags);
	CVAR_CACHE(g_spawnsound);
	CVAR_CACHE(g_reset_on_join);
	CVAR_CACHE(g_endmatch_on_leave);
	CVAR_CACHE(sv_autotaunt);
	CVAR_CACHE(sv_taunt);
	CVAR_CACHE(sv_loddistance1);
	CVAR_CACHE(sv_loddistance2);
	PL_VIEW_OFS = '0 0 1' * cvar("g_player_view_ofs");
	PL_MIN = '-1 -1 0' * cvar("g_player_maxsxy") + '0 0 -24';
	PL_MAX = '1 1 0' * cvar("g_player_maxsxy") + '0 0 1' * cvar("g_player_maxsz");
	PL_CROUCH_VIEW_OFS = '0 0 1' * cvar("g_player_crouch_view_ofs");
	PL_CROUCH_MIN = '-1 -1 0' * cvar("g_player_maxsxy") + '0 0 -24';
	PL_CROUCH_MAX = '1 1 0' * cvar("g_player_maxsxy") + '0 0 1' * cvar("g_player_crouch_maxsz");
	if (sv_loddistance2 <= sv_loddistance1)
		sv_loddistance2 = 1073741824; // enough to turn off LOD 2 reliably

#ifdef ALLOW_FORCEMODELS
	CVAR_CACHE(sv_clforceplayermodels);
#endif
	if (cvar("sv_defaultcharacter")) { //compatibility with old cvars
		string s;
		if ((s = cvar_string("sv_defaultplayermodel")) != "") {
			str_unzone_ifneeded(g_player_forcemodel);
			g_player_forcemodel = str_zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_blue")) != "") {
			str_unzone_ifneeded(g_player_forcemodel_blue);
			g_player_forcemodel_blue = str_zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_red")) != "") {
			str_unzone_ifneeded(g_player_forcemodel_red);
			g_player_forcemodel_red = str_zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_yellow")) != "") {
			str_unzone_ifneeded(g_player_forcemodel_yellow);
			g_player_forcemodel_yellow = str_zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_pink")) != "") {
			str_unzone_ifneeded(g_player_forcemodel_pink);
			g_player_forcemodel_pink = str_zone_ifneeded(s);
		}
		g_player_forcecolor = ((cvar_string("sv_defaultplayercolors") == "") ? g_player_forcecolor : cvar("sv_defaultplayercolors"));
		g_player_forceskin = ((cvar_string("sv_defaultplayerskin") == "") ? g_player_forceskin : cvar("sv_defaultplayerskin"));
	}
	if (g_player_forcemodel_blue == "" || g_player_forcemodel_blue == "0") {
		str_unzone_ifneeded(g_player_forcemodel_blue);
		g_player_forcemodel_blue = str_zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_red == "" || g_player_forcemodel_red == "0") {
		str_unzone_ifneeded(g_player_forcemodel_red);
		g_player_forcemodel_red = str_zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_yellow == "" || g_player_forcemodel_yellow == "0") {
		str_unzone_ifneeded(g_player_forcemodel_yellow);
		g_player_forcemodel_yellow = str_zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_pink == "" || g_player_forcemodel_pink == "0") {
		str_unzone_ifneeded(g_player_forcemodel_pink);
		g_player_forcemodel_pink = str_zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forceskin_blue < 0)
		g_player_forceskin_blue = g_player_forceskin;

	if (g_player_forceskin_red < 0)
		g_player_forceskin_red = g_player_forceskin;

	if (g_player_forceskin_yellow < 0)
		g_player_forceskin_yellow = g_player_forceskin;

	if (g_player_forceskin_pink < 0)
		g_player_forceskin_pink = g_player_forceskin;

#define EXTRA_ANNOUNCER(x) do { str_unzone_ifneeded(sv_announcer_extra_##x); sv_announcer_extra_##x = cvar_string_zone_ifneeded("sv_announcer_extra_"#x); if (sv_announcer_extra_##x != "") { precache_sound(sv_announcer_extra_##x); print("Extra announcer sound "#x" ", sv_announcer_extra_##x, "\n");} } while (0)
	//Extra sounds
	EXTRA_ANNOUNCER(meleefrag);
	EXTRA_ANNOUNCER(pushfrag);
	CVAR_CACHE(sv_announcer_extra_doublekill_interval);
	if (sv_announcer_extra_doublekill_interval) {
		EXTRA_ANNOUNCER(doublekill);
	}
	EXTRA_ANNOUNCER(telefrag);
	EXTRA_ANNOUNCER(firstblood);
#undef EXTRA_ANNOUNCER
	CVAR_CACHE_STR(sv_sound_frag);
	if (sv_sound_frag != "")
		precache_sound(sv_sound_frag);

	CVAR_CACHE(bot_taunt);
	CVAR_CACHE(bot_talk);
	CVAR_CACHE(g_maxpushtime);
	CVAR_CACHE(g_playerclip_collisions);
	if (player_init_done)
		return;

	player_init_done = TRUE;
	player_cmd_client_handle_next = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = player_cmd_client_handle;
	player_gamemenu_add_items_next = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = player_gamemenu_add_items;
}
