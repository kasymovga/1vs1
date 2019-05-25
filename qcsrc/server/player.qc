// autotaunt system
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
float g_jetpack_attenuation;
float g_fullbrightplayers;
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
float sv_servermodelsonly;
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
float sv_reset_on_join;
float g_player_brightness;
float g_spawnshieldtime;
float g_spawnsound;
float g_player_pushfactor;
float reset_on_join_done;
string sv_announcer_extra_meleefrag;
string sv_announcer_extra_pushfrag;
string sv_announcer_extra_doublekill;
float sv_announcer_extra_doublekill_interval;
string sv_announcer_extra_telefrag;
string sv_announcer_extra_firstblood;
float bot_taunt;
float bot_talk;

.entity pusher;
.float pushltime;

void(float keepvelocity) player_copy_body {
	local entity oldself;
	if (self.effects & EF_NODRAW)
		return;
	oldself = self;
	self = spawn();
	self.enemy = oldself;
	self.lip = oldself.lip;
	self.colormap = oldself.colormap;
	self.iscreature = oldself.iscreature;
	self.angles = oldself.angles;
	self.avelocity = oldself.avelocity;
	self.classname = "body";
	self.damageforcescale = oldself.damageforcescale;
	self.effects = oldself.effects;
	self.event_damage = oldself.event_damage;
	self.animstate_startframe = oldself.animstate_startframe;
	self.animstate_numframes = oldself.animstate_numframes;
	self.animstate_framerate = oldself.animstate_framerate;
	self.animstate_starttime = oldself.animstate_starttime;
	self.animstate_endtime = oldself.animstate_endtime;
	self.animstate_override = oldself.animstate_override;
	self.animstate_looping = oldself.animstate_looping;
	self.frame = oldself.frame;
	self.dead_frame = oldself.dead_frame;
	self.pain_finished = oldself.pain_finished;
	self.health = oldself.health;
	self.armorvalue = oldself.armorvalue;
	self.armortype = oldself.armortype;
	self.model = oldself.model;
	self.modelindex = oldself.modelindex;
	self.modelindex_lod0 = oldself.modelindex_lod0;
	self.modelindex_lod0_from_nexuiz = oldself.modelindex_lod0_from_nexuiz;
	self.modelindex_lod1 = oldself.modelindex_lod1;
	self.modelindex_lod2 = oldself.modelindex_lod2;
	self.skinindex = oldself.skinindex;
	self.species = oldself.species;
	self.movetype = oldself.movetype;
	self.nextthink = oldself.nextthink;
	self.solid = oldself.solid;
	self.takedamage = oldself.takedamage;
	self.think = oldself.think;
	self.customizeentityforclient = oldself.customizeentityforclient;
	self.scale = oldself.scale;
	self.deadflag = oldself.deadflag;
	if (keepvelocity == 1)
		self.velocity = oldself.velocity;
	self.oldvelocity = self.velocity;
	self.fade_time = oldself.fade_time;
	self.fade_rate = oldself.fade_rate;
	//self.weapon = oldself.weapon;
	setorigin(self, oldself.origin);
	setsize(self, oldself.mins, oldself.maxs);
	self.reset = SUB_Remove;

	self = oldself;
}

void(void) player_respawn {
	player_copy_body(1);
	self.effects |= EF_NODRAW; // prevent another CopyBody
	PutClientInServer();
}


float() player_getspecies {
	local float glob, i, j, fh, len, s, sk;
	local string fn, l;

	s = -1;

	glob = search_begin("models/player/*.txt", TRUE, TRUE);
	if(glob < 0)
		return s;
	for(j = 0; j <= 1; ++j)
	{
		for(i = 0; i < search_getsize(glob); ++i)
		{
			fn = search_getfilename(glob, i);
			fh = fopen(fn, FILE_READ);
			if(fh < 0)
				continue;
			fgets(fh); fgets(fh);
			sk = stof(fgets(fh));
			if(sk == (j ? 0 : self.skinindex)) // 2nd pass skips the skin test
			if(fgets(fh) == self.model)
			{
				l = fgets(fh);
				len = tokenize_console(l);
				if (len != 2)
					goto nospecies;
				if (argv(0) != "species")
					goto nospecies;
				switch(argv(1))
				{
					case "human":       s = SPECIES_HUMAN;       break;
					case "alien":       s = SPECIES_ALIEN;       break;
					case "robot_shiny": s = SPECIES_ROBOT_SHINY; break;
					case "robot_rusty": s = SPECIES_ROBOT_RUSTY; break;
					case "robot_solid": s = SPECIES_ROBOT_SOLID; break;
					case "animal":      s = SPECIES_ANIMAL;      break;
					case "reserved":    s = SPECIES_RESERVED;    break;
				}
			}
:nospecies
			fclose(fh);
		}
		if (s >= 0)
			break;
	}
	search_end(glob);

	if (s < 0)
		s = SPECIES_HUMAN;

	return s;
}

void(float finished, string samp) play_countdown {
	if(clienttype(self) == CLIENTTYPE_REAL)
		if(floor(finished - time - frametime) != floor(finished - time))
			if(finished - time < 6)
				sound (self, CHAN_AUTO, samp, VOL_BASE, ATTN_NORM);
}

void() player_effects {
	if((self.items & IT_USING_JETPACK) && !self.deadflag)
	{
		if not(self.modelflags & MF_ROCKET) {
			sound(self, CHAN_TRIGGER, "misc/jetpack_fly.wav", VOL_BASE, g_jetpack_attenuation);
			self.modelflags |= MF_ROCKET;
		}
	}
	else
	{
		if (self.modelflags & MF_ROCKET) {
			stopsound(self, CHAN_TRIGGER);
			self.modelflags &~= MF_ROCKET;
		}
	}

	self.effects &~= (EF_RED | EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT | EF_FLAME);

	if(!self.modelindex || self.deadflag) // don't apply the flags if the player is gibbed
		return;

	self.alpha = default_player_alpha;
	fire_apply_effect(self);

	if (GameHookChain_PlayerEffectsHandle())
		return;

	if (g_fullbrightplayers)
		self.effects = self.effects | EF_FULLBRIGHT;

	if (time >= game_starttime)
	if (time < self.spawnshieldtime)
		self.effects = self.effects | (EF_ADDITIVE | EF_FULLBRIGHT);
}

void() player_setupanimsformodel {
	local string animfilename;
	local float animfile;
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
	self.anim_melee = stov(cvar_string("sv_player_melee_anim"));
	self.anim_melee2 = stov(cvar_string("sv_player_melee_anim2"));
	anim_parseerror = FALSE;
	animfilename = strcat(self.model, ".animinfo");
	animfile = fopen(animfilename, FILE_READ);
	if (animfile >= 0)
	{
		self.anim_die1         = anim_parseline(animfile);
		self.anim_die2         = anim_parseline(animfile);
		self.anim_draw         = anim_parseline(animfile);
		self.anim_duck         = anim_parseline(animfile);
		self.anim_duckwalk     = anim_parseline(animfile);
		self.anim_duckjump     = anim_parseline(animfile);
		self.anim_duckidle     = anim_parseline(animfile);
		self.anim_idle         = anim_parseline(animfile);
		self.anim_jump         = anim_parseline(animfile);
		self.anim_pain1        = anim_parseline(animfile);
		self.anim_pain2        = anim_parseline(animfile);
		self.anim_shoot        = anim_parseline(animfile);
		self.anim_taunt        = anim_parseline(animfile);
		self.anim_run          = anim_parseline(animfile);
		self.anim_runbackwards = anim_parseline(animfile);
		self.anim_strafeleft   = anim_parseline(animfile);
		self.anim_straferight  = anim_parseline(animfile);
		self.anim_forwardright = anim_parseline(animfile);
		self.anim_forwardleft  = anim_parseline(animfile);
		self.anim_backright    = anim_parseline(animfile);
		self.anim_backleft     = anim_parseline(animfile);
		fclose(animfile);

		// derived anims
		self.anim_dead1 = '0 1 1' + '1 0 0' * (self.anim_die1_x + self.anim_die1_y - 1);
		self.anim_dead2 = '0 1 1' + '1 0 0' * (self.anim_die2_x + self.anim_die2_y - 1);

		if (anim_parseerror)
			print("Parse error in ", animfilename, ", some player animations are broken\n");
	}
	else
		dprint("File ", animfilename, " not found, assuming legacy .zym model animation timings\n");
	// reset animstate now
	anim_set(self, self.anim_idle, TRUE, FALSE, TRUE);
}

void(void) player_anim {
	anim_update(self);
	if (self.weaponentity)
		anim_update(self.weaponentity);

	if (self.deadflag != DEAD_NO && self.deadflag != DEAD_FREEZE)
	{
		if (time > self.animstate_endtime)
		{
			if (self.maxs_z > 5)
			{
				self.maxs_z = 5;
				setsize(self, self.mins, self.maxs);
			}
			self.frame = self.dead_frame;
		}
		return;
	}

	if (!self.animstate_override)
	{
		if (!(self.flags & FL_ONGROUND))
		{
			if (self.crouch)
				anim_set(self, self.anim_duckjump, FALSE, TRUE, self.restart_jump);
			else
				anim_set(self, self.anim_jump, FALSE, TRUE, self.restart_jump);
			self.restart_jump = FALSE;
		}
		else if (self.crouch)
		{
			if (self.movement_x * self.movement_x + self.movement_y * self.movement_y > 20)
				anim_set(self, self.anim_duckwalk, TRUE, FALSE, FALSE);
			else
				anim_set(self, self.anim_duckidle, TRUE, FALSE, FALSE);
		}
		else if ((self.movement_x * self.movement_x + self.movement_y * self.movement_y) > 20)
		{
			if (self.movement_x > 0 && self.movement_y == 0)
				anim_set(self, self.anim_run, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y == 0)
				anim_set(self, self.anim_runbackwards, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y > 0)
				anim_set(self, self.anim_straferight, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y < 0)
				anim_set(self, self.anim_strafeleft, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y > 0)
				anim_set(self, self.anim_forwardright, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y < 0)
				anim_set(self, self.anim_forwardleft, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y > 0)
				anim_set(self, self.anim_backright, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y < 0)
				anim_set(self, self.anim_backleft, TRUE, FALSE, FALSE);
			else
				anim_set(self, self.anim_run, TRUE, FALSE, FALSE);
		}
		else
			anim_set(self, self.anim_idle, TRUE, FALSE, FALSE);
	}

	if (self.weaponentity)
	if (!self.weaponentity.animstate_override)
		anim_set(self.weaponentity, self.weaponentity.anim_idle, TRUE, FALSE, FALSE);
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_corpse_damage {
	violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);

	// damage resistance (ignore most of the damage from a bullet or similar)
	_damage = max(_damage - 5, 1);

	if (_damage > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (_damage > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM);

	if (_damage > 50)
		violence_gib_splash_at(hitloc, force * -0.1, 3, 1, self, attacker);
	if (_damage > 100)
		violence_gib_splash_at(hitloc, force * -0.2, 3, 1, self, attacker);

	self.health = self.health - _damage;
	self.dmg_take = self.dmg_take + _damage;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;
	if (self.health <= -75 && self.modelindex != 0)
	{
		// don't use any animations as a gib
		self.frame = 0;
		self.dead_frame = 0;
		// view just above the floor
		self.view_ofs = '0 0 4';

		violence_gib_splash(self, 1, 1, attacker);
		self.modelindex = 0; // restore later
		self.solid = SOLID_NOT; // restore later
	}
}

void(float killed) player_clear {
	float j;
	if (killed)
		Portal_ClearAllLater(self);
	else
		Portal_ClearAll(self);

	// reset fields the weapons may use just in case
	for (j = WEP_FIRST; j <= WEP_LAST; ++j)
	{
		weapon_action(j, WR_RESETPLAYER);
		weapon_action(j, WR_CLEAR);
		ATTACK_FINISHED_FOR(self, j) = 0;
	}
	GameHookChain_PlayerClear(killed);
	//Clear waypoints
	WaypointSprite_PlayerDead();
}

float checkrules_firstblood;
void(entity attacker, entity inflictor, entity targ, float deathtype) player_obituary {
	string	s, a;
	float p, w;
	s = targ.netname;
	a = attacker.netname;
	w_fragprefix = "";
	if (targ == attacker)
	{
		if not(clienttype(attacker) == CLIENTTYPE_REAL)
			Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_suicide"), "");
		if (deathtype == DEATH_TEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", ColoredTeamName(targ.team)));
		} else if (deathtype == DEATH_AUTOTEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(targ.team)));
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
		if(WEP_VALID(w))
		{
			w_deathtypestring = "couldn't resist the urge to self-destruct";
			w_deathtype = deathtype;
			weapon_action(w, WR_SUICIDEMESSAGE);
			bprint("^1", s, "^1 ", w_deathtypestring, "\n");
		}
		else if (deathtype == DEATH_KILL)
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

		if(deathtype != DEATH_TEAMCHANGE)
		{
			scores_give_frag(attacker, targ, -1);
		}
		if (targ.killcount > 2)
			bprint ("^1",s,"^1 ended it all after a ",ftos(targ.killcount)," kill spree\n");
	}
	else if (attacker.classname == "player")
	{
		if not(clienttype(attacker) == CLIENTTYPE_REAL)
		{
			if (bot_talk)
			if (random() <= bot_talk)
			{
				if (teamplay && attacker.team == targ.team)
					Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_teamkill"), strcat(targ.netname, "^7: "));
				else
					Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_frag"), strcat(targ.netname, "^7: "));
			}
			if (bot_taunt)
			if (random() <= bot_taunt)
			{
				local entity oldself;
				oldself = self;
				self = attacker;
				player_voice_message("taunt", "");
				self = oldself;
			}
		}
		if not(clienttype(targ) == CLIENTTYPE_REAL)
		if (bot_talk)
		if (random() <= bot_talk)
		{
			if (teamplay && attacker.team == targ.team)
			{
				Bot_Say(targ, FALSE, world, cvar_string("bot_messages_teamkilled"), strcat(attacker.netname, "^7: "));
			}
			else
			{
				if (random() < 0.5)
					Bot_Say(targ, FALSE, world, cvar_string("bot_messages_fragged"), "");
				else
					Bot_Say(targ, FALSE, world, cvar_string("bot_messages_fragged_priv"), strcat(attacker.netname, "^7: "));
			}
		}
		if(teamplay && attacker.team == targ.team && !targ.saboteur)
		{
			centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s, ", a team mate!"));
			bprint ("^1", a, "^1 mows down a team mate\n");
			scores_give_frag(attacker, targ, -1);
			if (targ.killcount > 2) {
				bprint ("^1",s,"'s ^1",ftos(targ.killcount)," kill spree was ended by a team mate!\n");
			}
			if (attacker.killcount > 2) {
				bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," kill spree by killing a team mate\n");
			}
			attacker.killcount = 0;
		}
		else
		{
			string blood_message, victim_message;
			if (!checkrules_firstblood)
			{
				checkrules_firstblood = TRUE;
				bprint("^1",a, "^1 drew first blood", "\n");
				blood_message = "^1First blood\n";
				victim_message = "^1First victim\n";  // or First casualty
				if (sv_announcer_extra_firstblood != "")
					announce(attacker, sv_announcer_extra_firstblood);
			}


			w = DEATH_WEAPONOF(deathtype);
			if(WEP_VALID(w))
			{
				w_deathtypestring = "was blasted by";
				w_deathtype = deathtype;
				weapon_action(w, WR_KILLMESSAGE);
				p = strstrofs(w_deathtypestring, "#", 0);
				if(p < 0)
					bprint("^1", s, "^1 ", w_deathtypestring, " ", a, "\n");
				else
					bprint("^1", s, "^1 ", substring(w_deathtypestring, 0, p), a, "^1", substring(w_deathtypestring, p+1, strlen(w_deathtypestring) - (p+1)), "\n");
			}
			else if (deathtype == DEATH_DROWN)
				bprint ("^1",s, "^1 was drowned by ", a, "\n");
			else if (deathtype == DEATH_SLIME)
				bprint ("^1",s, "^1 was slimed by ", a, "\n");
			else if (deathtype == DEATH_LAVA)
				bprint ("^1",s, "^1 was cooked by ", a, "\n");
			else if (deathtype == DEATH_FALL) {
				bprint ("^1",s, "^1 was grounded by ", a, "\n");
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag);
					announce(attacker, sv_announcer_extra_pushfrag);
				}
			} else if (deathtype == DEATH_SWAMP)
				bprint ("^1",s, "^1 was conserved by ", a, "\n");
			else if (deathtype == DEATH_HURTTRIGGER) {
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag);
					announce(attacker, sv_announcer_extra_pushfrag);
				}
				if (inflictor.message2 != "") {
					p = strstrofs(inflictor.message2, "#", 0);
					if(p < 0)
						bprint("^1", s, "^1 ", inflictor.message2, " ", a, "\n");
					else
						bprint("^1", s, "^1 ", substring(inflictor.message2, 0, p), a, "^1", substring(inflictor.message2, p+1, strlen(inflictor.message2) - (p+1)), "\n");
				}
			}
			else if(deathtype == DEATH_TURRET)
				bprint ("^1",s, "^1 was pushed into the line of fire by ^1", a, "\n");
			else if (deathtype == DEATH_FIRE)
				bprint ("^1",s, "^1 was burnt to death by ^1", a, "\n");
			else
				bprint ("^1",s, "^1 was ", w_fragprefix, "^1fragged by ", a, "\n");

			scores_give_frag(attacker, targ, 1);

			if (targ.killcount > 2) {
				bprint ("^1",s,"'s ^1", ftos(targ.killcount), " kill spree was ended by ", a, "\n");
			}

			attacker.killcount = attacker.killcount + 1;

			if (attacker.killcount > 2) {
				bprint ("^1",a,"^1 has ",ftos(attacker.killcount)," frags in a row\n");
			}
			float fragtime = time;

			if (attacker.killcount == 3)
			{
				bprint (a,"^7 made a ^1TRIPLE FRAG\n");
				announce(attacker, "announcer/male/03kills.wav");
			}
			else if (attacker.killcount == 5)
			{
				bprint (a,"^7 unleashes ^1RAGE\n");
				announce(attacker, "announcer/male/05kills.wav");
			}
			else if (attacker.killcount == 10)
			{
				bprint (a,"^7 starts the ^1MASSACRE!\n");
				announce(attacker, "announcer/male/10kills.wav");
			}
			else if (attacker.killcount == 15)
			{
				bprint (a,"^7 executes ^1MAYHEM!\n");
				announce(attacker, "announcer/male/15kills.wav");
			}
			else if (attacker.killcount == 20)
			{
				bprint (a,"^7 is a ^1BERSERKER!\n");
				announce(attacker, "announcer/male/20kills.wav");
			}
			else if (attacker.killcount == 25)
			{
				bprint (a,"^7 inflicts ^1CARNAGE!\n");
				announce(attacker, "announcer/male/25kills.wav");
			}
			else if (attacker.killcount == 30)
			{
				bprint (a,"^7 unleashes ^1ARMAGEDDON!\n");
				announce(attacker, "announcer/male/30kills.wav");
			}
			else if (time - attacker.lastfrag < sv_announcer_extra_doublekill_interval && attacker.lastfrag && sv_announcer_extra_doublekill != "")
			{
					if (announce(attacker, sv_announcer_extra_doublekill))
						fragtime = 0;
			}
			if (DEATH_ISWEAPON(deathtype, WEP_MELEE) && sv_announcer_extra_meleefrag != "")
			{
					announce(targ, sv_announcer_extra_meleefrag);
					announce(attacker, sv_announcer_extra_meleefrag);
			}
			centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ", w_fragprefix, "^4fragged ^7", s));
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ", w_fragprefix, "^1fragged by ^7", a));
			attacker.taunt_soundtime = time + 1;
			attacker.lastfrag = fragtime;
		}
	}
	else if (attacker.classname == "monster")
	{
		centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were fragged by ^7", attacker.netname));
		bprint ("^1",s, "^1 was killed by ", attacker.netname, "\n");
	}
	else
	{
		if not(clienttype(targ) == CLIENTTYPE_REAL)
		if (bot_talk)
		if (random() <= bot_talk)
			Bot_Say(targ, FALSE, world, cvar_string("bot_messages_suicide"), "");
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
		else if(deathtype == DEATH_TURRET)
			bprint ("^1",s, "^1 was mowed down by a turret \n");
		else if(deathtype == DEATH_FIRE)
			bprint ("^1",s, "^1 burnt to death\n");
		else
			bprint ("^1",s, "^1 died\n");
		scores_give_frag(targ, targ, -1);
		if(scores_player_add(targ, SP_SCORE, 0) == -5) {
			announce(targ, "announcer/male/botlike.wav");
		}

		if (targ.killcount > 2)
			bprint ("^1",s,"^1 died with a ",ftos(targ.killcount)," kill spree\n");
	}
	targ.death_origin = targ.origin;
	if(targ != attacker)
		targ.killer_origin = attacker.origin;
	// FIXME: this should go in PutClientInServer
	if (targ.killcount)
		targ.killcount = 0;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_damage {
	local float take, save, waves, sdelay, dh, da;
	GameHookChain_PlayerDamageMod = 1;
	if (GameHookChain_PlayerDamageHandle(inflictor, attacker, _damage, deathtype, hitloc, force))
		return;

	dh = max(self.health, 0);
	da = max(self.armorvalue, 0);

	_damage = _damage * GameHookChain_PlayerDamageMod;

	if(DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
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
		if(f > 0)
		{
			hitloc = ear1;
			force = force * -1;
		}
		else
		{
			hitloc = ear2;
			// force is already good
		}
	}
	else
		violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);

	save = bound(0, _damage * GameHookChain_ArmorBlockPercentMod() * g_balance_armor_blockpercent, self.armorvalue);
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

	if (time > self.spawnshieldtime)
	{
		self.armorvalue = self.armorvalue - save;
		self.health = self.health - take;
		// pause regeneration for 5 seconds
		self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_health_regen);

		if (time > self.pain_finished)		//Don't switch pain sequences like crazy
		{
			self.pain_finished = time + 0.5;	//Supajoe

			if(self.classname != "body") // pain anim is BORKED on our ZYMs, FIXME remove this once we have good models
			{
				if (random() > 0.5)
					anim_set(self, self.anim_pain1, FALSE, TRUE, TRUE);
				else
					anim_set(self, self.anim_pain2, FALSE, TRUE, TRUE);
			}

			if(!DEATH_ISWEAPON(deathtype, WEP_LASER) || attacker != self || self.health < 2 * g_balance_laser_primary_damage * g_balance_selfdamagepercent + 1)
			// exclude pain sounds for laserjumps as long as you aren't REALLY low on health and would die of the next two
			{
				string pain_sound;
				if(self.health > 75) // TODO make a "gentle" version?
					pain_sound = self.playersound_pain100;
				else if(self.health > 50)
					pain_sound = self.playersound_pain75;
				else if(self.health > 25)
					pain_sound = self.playersound_pain50;
				else if(self.health > 1)
					pain_sound = self.playersound_pain25;

				sound(self, CHAN_PAIN, randomsound_bystr(pain_sound), VOL_BASE, ATTN_NORM);
			}

			// throw off bot aim temporarily
			local float shake;
			shake = _damage * 5 / (bound(0,skill,100) + 1);
			self.v_angle_x = self.v_angle_x + (random() * 2 - 1) * shake;
			self.v_angle_y = self.v_angle_y + (random() * 2 - 1) * shake;
		}
	}
	self.dmg_save = self.dmg_save + save;//max(save - 10, 0);
	self.dmg_take = self.dmg_take + take;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;

	if(attacker == self)
	{
		// don't reset pushltime for self damage as it may be an attempt to
		// escape a lava pit or similar
		//self.pushltime = 0;
	}
	else if(attacker.classname == "player")
	{
		self.pusher = attacker;
		self.pushltime = time + g_maxpushtime;
	}
	else if(time < self.pushltime)
	{
		attacker = self.pusher;
		self.pushltime = max(self.pushltime, time + 0.6);
	}
	else
		self.pushltime = 0;

	if (self.health < 1)
	if not(GameHook_DeathHandle(attacker, inflictor, deathtype))
	{
		float defer_ClientKill_Now_TeamChange;
		defer_ClientKill_Now_TeamChange = FALSE;

		if(deathtype == DEATH_DROWN)
			sound(self, CHAN_PAIN, randomsound_bystr(self.playersound_drown), VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_PAIN, randomsound_bystr(self.playersound_death), VOL_BASE, ATTN_NORM);

		// get rid of kill indicator
		if(self.killindicator)
		{
			remove(self.killindicator);
			self.killindicator = world;
			if(self.killindicator_teamchange)
				defer_ClientKill_Now_TeamChange = TRUE;

			if(self.classname == "body")
			if(deathtype == DEATH_KILL)
			{
				// for the lemmings fans, a small harmless explosion
				pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
			}
		}

        dropentities(self);

		// become fully visible
		self.alpha = 1;
		// clear selected player display
		if not(GameHookChain_ThrowWeaponOnDeathHandle())
			weapon_throw(randomvec() * 125 + '0 0 200', (self.mins + self.maxs) * 0.5, FALSE);

		// print an obituary message
		player_obituary(attacker, inflictor, self, deathtype);
		player_clear(TRUE);
		// make the corpse upright (not tilted)
		self.angles_x = 0;
		self.angles_z = 0;
		// don't spin
		self.avelocity = '0 0 0';
		// view from the floor
		self.view_ofs = '0 0 -8';
		// toss the corpse
		self.movetype = MOVETYPE_TOSS;
		// shootable corpse
		self.solid = SOLID_CORPSE;
		// don't stick to the floor
		self.flags &~= FL_ONGROUND;
		// dying animation
		self.deadflag = DEAD_DYING;
		// when to allow respawn
		sdelay = 0;
		waves = 0;
		if(g_respawn_mapsettings)
		{
			sdelay = g_respawn_mapsettings_delay;
			waves = g_respawn_mapsettings_waves;
		}
		if(!sdelay)
			sdelay = g_respawn_delay;

		if(!waves)
			waves = g_respawn_waves;

		if(waves)
			self.death_time = ceil((time + sdelay) / waves) * waves;
		else
			self.death_time = time + sdelay;
		if((sdelay + waves >= 5.0) && (self.death_time - time > 1.75))
			self.respawn_countdown = 10; // first number to count down from is 10
		else
			self.respawn_countdown = -1; // do not count down
		if (random() < 0.5)
		{
			anim_set(self, self.anim_die1, FALSE, TRUE, TRUE);
			self.dead_frame = self.anim_dead1_x;
		}
		else
		{
			anim_set(self, self.anim_die2, FALSE, TRUE, TRUE);
			self.dead_frame = self.anim_dead2_x;
		}
		// set damage function to corpse damage
		self.event_damage = player_corpse_damage;
		// call the corpse damage function just in case it wants to gib
		self.event_damage(inflictor, attacker, 0, deathtype, hitloc, force);
		// set up to fade out later
		SUB_SetFade (self, time + 12 + random () * 4, 1);

		if(clienttype(self) == CLIENTTYPE_REAL)
		{
			self.fixangle = TRUE;
			//msg_entity = self;
			//WriteByte (MSG_ONE, SVC_SETANGLE);
			//WriteAngle (MSG_ONE, self.v_angle_x);
			//WriteAngle (MSG_ONE, self.v_angle_y);
			//WriteAngle (MSG_ONE, 80);
		}

		if(defer_ClientKill_Now_TeamChange)
			ClientKill_Now_TeamChange();
	}
}

string allvoicesamples;
float player_voice_message_sample_not_found;
float player_voice_message_sample_fixed;
.string player_voice_message_sample_field(string type)
{
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch(type)
	{
#define _VOICEMSG(m) case #m: return playersound_##m;
		ALLVOICEMSGS
#undef _VOICEMSG
	}
	player_voice_message_sample_not_found = 1;
	return playersound_taunt;
}

.string GetPlayerSoundSampleField(string type)
{
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch(type)
	{
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
	if(fh < 0)
		return;
	while((s = fgets(fh)))
	{
		if(tokenize_console(s) != 3)
		{
			dprint("Invalid sound info line: ", s, "\n");
			continue;
		}
		precache_randomsound(argv(1), stof(argv(2)));
	}
	fclose(fh);

	if not(allvoicesamples)
	{
#define _VOICEMSG(m) allvoicesamples = strcat(allvoicesamples, " ", #m);
		ALLVOICEMSGS
#undef _VOICEMSG
		allvoicesamples = strzone(substring(allvoicesamples, 1, strlen(allvoicesamples) - 1));
	}
}

void player_clear_sounds()
{
#define _VOICEMSG(m) if(self.playersound_##m) { strunzone(self.playersound_##m); self.playersound_##m = string_null; }
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

void(string f, float first) player_load_sounds {
	float fh;
	string s;
	var .string field;
	fh = fopen(f, FILE_READ);
	if(fh < 0)
		return;
	while((s = fgets(fh)))
	{
		if(tokenize_console(s) != 3)
			continue;
		field = GetPlayerSoundSampleField(argv(0));
		if(player_voice_message_sample_not_found)
			field = player_voice_message_sample_field(argv(0));
		if(player_voice_message_sample_not_found)
			continue;
		if(player_voice_message_sample_fixed)
			if not(first)
				continue;
		if(self.field)
			strunzone(self.field);
		self.field = strzone(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
}

.float modelindex_for_playersound;
void() player_update_sounds {
	if(self.modelindex == self.modelindex_for_playersound)
		return;
	self.modelindex_for_playersound = self.modelindex;
	player_clear_sounds();
	player_load_sounds("sound/player/default.sounds", 1);
	player_load_sounds(strcat(self.model, ".sounds"), 0);
}

void player_voice_message(string type, string msg)
{
	var .string sample;
	float ownteam;
	sample = player_voice_message_sample_field(type);

	if(player_voice_message_sample_not_found)
	{
		sprint(self, strcat("Invalid voice. Use one of: ", allvoicesamples, "\n"));
		return;
	}

	ownteam = (type != "taunt" && type != "teamshot");
	float flood;
	float flood_spv;
	var .float flood_field;

	flood = 0;
	if (ownteam)
	{
		flood_spv = g_voice_flood_spv_team;
		flood_field = floodcontrol_voiceteam;
	}
	else
	{
		flood_spv = g_voice_flood_spv;
		flood_field = floodcontrol_voice;
	}

	if(time >= self.flood_field)
		self.flood_field = max(time, self.flood_field) + flood_spv;
	else
		flood = 1;

	if (timeoutStatus == 2) //when game is paused, no flood protection
		self.flood_field = flood = 0;

	if (msg != "")
		chat_say(self, ownteam, world, msg, 0);

	if (flood)
		return;

	string s = randomsound_bystr(self.sample);
	if (type == "taunt") {
		if(self.classname == "player")
			if(self.deadflag == DEAD_NO)
				anim_set(self, self.anim_taunt, FALSE, TRUE, TRUE);
		if(!sv_taunt)
			return;

		FOR_EACH_REALCLIENT(msg_entity)
		{
			if (msg_entity.cvar_cl_voice_directional >= 1)
				soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
			else
				soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
		}
	} else if (type == "teamshoot") {
		if(self.pusher)
			if(self.pusher.team == self.team)
			{
				msg_entity = self.pusher;
				if(clienttype(msg_entity) == CLIENTTYPE_REAL)
				{
					if(msg_entity.cvar_cl_voice_directional == 1)
						soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
					else
						soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
				}
				msg_entity = self;
				if(clienttype(msg_entity) == CLIENTTYPE_REAL)
					soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASE, ATTN_NONE);
			}
	} else {
		FOR_EACH_REALCLIENT(msg_entity)
			if(!teamplay || msg_entity.team == self.team)
			{
				if(msg_entity.cvar_cl_voice_directional == 1)
					soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
				else
					soundto(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
			}
	}
}

float(entity plr, entity viewer) player_calculate_alpha {
	plr = Akimbo_Owner(plr);
	float dalpha = max(0.01, default_player_alpha);
	if(plr.classname == "observer") {
		if(plr == viewer) {
			return dalpha;
		}

		return -1;
	} else if(plr.classname == "spectator") {
		return -1;
	}

	if(plr.deadflag) {
		return dalpha;
	}
	if(viewer.classname == "spectator") {
		viewer = viewer.enemy;
	}

	float sa = GameHookChain_PlayerAlphaMod(plr, viewer, dalpha);

	if(plr == viewer && sa < 0.01) {
		sa = 0.01;
	} else if(sa <= 0) {
		sa = -1;
	}

	return sa;
}

void(entity e, string modelname) player_setup_lod {
	string s;
	if(sv_loddistance1)
	{
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
	} else {
		precache_model(modelname);
		setmodel(e, modelname); // players have high precision
		self.modelindex_lod0 = self.modelindex;
	}
	s = whichpack(self.model);
	self.modelindex_lod0_from_nexuiz = ((s == "") || (substring(s, 0, 4) == "data"));
	player_setupanimsformodel();
	player_update_sounds();
}

string PLAYER_FALLBACKMODEL = "models/player/marine.zym";
string(string plyermodel) player_check_model {
	if(strlen(plyermodel) < 4)
		return PLAYER_FALLBACKMODEL;
	if( substring(plyermodel,0,14) != "models/player/")
		return PLAYER_FALLBACKMODEL;
	else if(sv_servermodelsonly)
	{
		if(substring(plyermodel,-4,4) != ".zym")
		if(substring(plyermodel,-4,4) != ".dpm")
		if(substring(plyermodel,-4,4) != ".md3")
		if(substring(plyermodel,-4,4) != ".psk")
			return PLAYER_FALLBACKMODEL;
		// forbid the LOD models
		if(substring(plyermodel, -9,5) == "_lod1")
			return PLAYER_FALLBACKMODEL;
		if(substring(plyermodel, -9,5) == "_lod2")
			return PLAYER_FALLBACKMODEL;
		if(plyermodel != strtolower(plyermodel))
			return PLAYER_FALLBACKMODEL;
		if(!fexists(plyermodel))
			return PLAYER_FALLBACKMODEL;
	}
	return plyermodel;
}

void() player_setup_model {
	string forcemodel;
	float forceskin, forcecolor, chmdl, oldskin;
	vector m1, m2;
	if(teamplay)
	{
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
	if(self.modelindex == 0 && self.deadflag == DEAD_NO)
		self.model = ""; // force the != checks to return true

	if(forcemodel != "" && forcemodel != "0")
	{
		if (forcemodel != self.model)
		{
			m1 = self.mins;
			m2 = self.maxs;
			player_setup_lod(self, forcemodel);
			setsize(self, m1, m2);
			chmdl = TRUE;
		}
		oldskin = self.skinindex;
		if (forceskin >= 0)
			self.skinindex = forceskin;
	} else {
		if (self.playermodel != self.model)
		{
			self.playermodel = player_check_model(self.playermodel);
			m1 = self.mins;
			m2 = self.maxs;
			player_setup_lod(self, self.playermodel);
			setsize(self, m1, m2);
			chmdl = TRUE;
		}
		oldskin = self.skinindex;
		self.skinindex = (teamplay ? ((self.skinindex == 6) ? 6 : mod(self.skinindex, 3)) : self.skinindex); //what bad about skins 3, 4 and 5?
	}
	if(chmdl || oldskin != self.skinindex)
		self.species = player_getspecies(); // model or skin has changed

	if (forcecolor > -2) {
		float colors = GameHookChain_PlayerColorsMod(forcecolor);
		if (self.clientcolors != colors)
			SetPlayerColors(self, colors);
	}
}

void(string s) player_precache_model {
	if (s == "" || s == "0")
		return;

	precache_model(s);
	player_precache_sounds(strcat(s, ".sounds"));
}

void(entity player) player_to_spec
{
	if (player.classname == "player" || (player.classname == "spectator" && player.team >= 0))
	if not(g_campaign)
	if not(GameHook_ForbidSpectators())
	if (sv_spectate) {
		entity oldself = self;
		self = player;
		player_clear(FALSE);
		player.classname = "observer";
		if(blockSpectators)
			sprint(player, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));

		PutClientInServer();
		scores_touch(player);
		self = oldself;
		spectator_note_update();
		if (teamplay)
			AuditTeams(FALSE);
	}
}

float(float current, float stable, float regenfactor, float regenframetime) player_calc_regen {
	if(current > stable)
		return current;
	else if(current > stable - 0.25) // when close enough, "snap"
		return stable;
	else
		return min(stable, current + (stable - current) * regenfactor * regenframetime);
}

float(float current, float stable, float rotfactor, float rotframetime) player_calc_rot {
	if(current < stable)
		return current;
	else if(current < stable + 0.25) // when close enough, "snap"
		return stable;
	else
		return max(stable, current + (stable - current) * rotfactor * rotframetime);
}

float(float current, float regenstable, float regenfactor, float regenlinear, float regenframetime, float rotstable, float rotfactor, float rotlinear, float rotframetime, float limit) player_calc_rot_regen {
	if(current > rotstable)
	{
		if(rotframetime > 0)
		{
			current = player_calc_rot(current, rotstable, rotfactor, rotframetime);
			current = max(rotstable, current - rotlinear * rotframetime);
		}
	}
	else if(current < regenstable)
	{
		if(regenframetime > 0)
		{
			current = player_calc_regen(current, regenstable, regenfactor, regenframetime);
			current = min(regenstable, current + regenlinear * regenframetime);
		}
	}

	if(current > limit)
		current = limit;

	return current;
}

void() player_respawn_countdown {
	float number;
	if(self.deadflag == DEAD_NO) // just respawned?
		return;
	else {
		number = ceil(self.death_time - time);
		if(number <= 0)
			return;

		if(number <= self.respawn_countdown) {
			self.respawn_countdown = number - 1;
			if(ceil(self.death_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
				announce(self, strcat("announcer/robotic/", ftos(number), ".wav"));
		}
	}
}


void() player_regen {
	float minh, maxh, limith, limita;
	GameHook_HealthArmorRotRegen = GameHook_HealthMaxMod = GameHook_ArmorHealthLimitMod = GameHook_RegenMod = GameHook_RotMod = 1;
	GameHookChain_HealthArmorFuelModsSet();
	if (GameHook_HealthArmorRotRegen)
	{
		limith = g_balance_health_limit * GameHook_ArmorHealthLimitMod;
		maxh = g_balance_health_rotstable * GameHook_HealthMaxMod;
		minh = g_balance_health_regenstable * GameHook_HealthMaxMod;
		self.health = player_calc_rot_regen(self.health, minh, g_balance_health_regen, g_balance_health_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished), maxh, g_balance_health_rot, g_balance_health_rotlinear, GameHook_RotMod * frametime * (time > self.pauserothealth_finished), limith);
		// if player rotted to death...  die!
		if(self.health < 1)
			self.event_damage(self, self, 1, DEATH_ROT, self.origin, '0 0 0');
		limita = g_balance_armor_limit * GameHook_ArmorHealthLimitMod;
		self.armorvalue = player_calc_rot_regen(self.armorvalue, g_balance_armor_regenstable, g_balance_armor_regen, g_balance_armor_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished), g_balance_armor_rotstable, g_balance_armor_rot, g_balance_armor_rotlinear, GameHook_RotMod * frametime * (time > self.pauserotarmor_finished), limita);

	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel = player_calc_rot_regen(self.ammo_fuel, g_balance_fuel_regenstable, g_balance_fuel_regen, g_balance_fuel_regenlinear, GameHook_RegenMod * frametime * (time > self.pauseregen_finished) * (self.items & IT_FUEL_REGEN != 0), g_balance_fuel_rotstable, g_balance_fuel_rot, g_balance_fuel_rotlinear, GameHook_RotMod * frametime * (time > self.pauserotfuel_finished), g_balance_fuel_limit);
}

.float items_added;
void() player_think {
	if(self.deadflag == DEAD_NO)
	if not(gameover)
		self.play_time += frametime;

	if(self.teleport_time)
	if(time > self.teleport_time) {
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
		fire_apply_damage(self);
		player_effects();
	}
	if (PLAYER_REALLY_DEAD(self)) {
		float button_pressed;
		if(frametime)
			player_anim();

		button_pressed = (self.BUTTON_ATCK || self.BUTTON_JUMP || self.BUTTON_ATCK2 || self.BUTTON_HOOK || self.BUTTON_USE);
		if (self.deadflag == DEAD_DYING) {
			if(g_forced_respawn)
				self.deadflag = DEAD_RESPAWNING;
			else if(!button_pressed)
				self.deadflag = DEAD_DEAD;
		} else if (self.deadflag == DEAD_DEAD) {
			if(button_pressed)
				self.deadflag = DEAD_RESPAWNABLE;
		} else if (self.deadflag == DEAD_RESPAWNABLE) {
			if(!button_pressed)
				self.deadflag = DEAD_RESPAWNING;
		} else if (self.deadflag == DEAD_RESPAWNING) {
			if(time > self.death_time) {
				self.death_time = time + 1; // only retry once a second
				player_respawn();
			}
		}
		player_respawn_countdown();
		return;
	}
	player_setup_model();
	weapon_frame();
	Akimbo_WeaponFrame();
	if(frametime) {
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
	if(self.teamkill_soundtime)
	if(time > self.teamkill_soundtime) {
		self.teamkill_soundtime = 0;
		entity oldpusher, oldself;
		oldself = self; self = self.teamkill_soundsource;
		oldpusher = self.pusher; self.pusher = oldself;
		if(self.pusher)
		if(self.pusher.team == self.team) {
			msg_entity = self.pusher;
			if(clienttype(msg_entity) == CLIENTTYPE_REAL) {
				if(msg_entity.cvar_cl_voice_directional == 1)
					soundto(MSG_ONE, self, CHAN_VOICE, randomsound_bystr(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_MIN);
				else
					soundto(MSG_ONE, self, CHAN_VOICE, randomsound_bystr(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_NONE);
			}
		}
		self.pusher = oldpusher;
		self = oldself;
	}
	if(self.taunt_soundtime)
	if(time > self.taunt_soundtime) {
		self.taunt_soundtime = 0;
		if (sv_taunt)
		if (sv_autotaunt) {
			float tauntrand = random();
			FOR_EACH_REALCLIENT(msg_entity)
				if (tauntrand < msg_entity.cvar_cl_autotaunt)
				{
					if (msg_entity.cvar_cl_voice_directional >= 1)
						soundto(MSG_ONE, self, CHAN_VOICE, randomsound_bystr(self.playersound_taunt), VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
					else
						soundto(MSG_ONE, self, CHAN_VOICE, randomsound_bystr(self.playersound_taunt), VOL_BASEVOICE, ATTN_NONE);
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
	local float imp;
	vector org;
	float i;
	float m;
	entity e, e2;

	imp = self.impulse;
	if (!imp || gameover)
		return;
	self.impulse = 0;

	if (timeoutStatus == 2) //don't allow any impulses while the game is paused
		return;

	if (imp >= 1 && imp <= 9)
	{
		// weapon switching impulses
		if(self.deadflag == DEAD_NO)
			weapon_next_on_impulse(imp);
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 10 && imp <= 20)
	{
		if(self.deadflag == DEAD_NO)
		{
			switch(imp)
			{
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
					if not(GameHookChain_ThrowWeaponHandle())
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
		}
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 200 && imp <= 229)
	{
		if(self.deadflag == DEAD_NO)
		{
			// custom order weapon cycling
			i = mod(imp, 10);
			m = (imp - (210 + i)); // <0 for prev, =0 for best, >0 for next
			weapon_cycle(self.(cvar_cl_weaponpriorities[i]), m);
		}
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 230 && imp <= 253)
	{
		if(self.deadflag == DEAD_NO) {
			if (self.gameclient == CLIENT_XONOTIC) {
				if (imp >= 234)
					imp--;
			}
			weapon_switch(imp - 230 + WEP_FIRST);
		} else
			self.impulse = imp; // retry in next frame
	}
	// deploy waypoints
	else if (imp >= 30 && imp <= 49)
	{
		entity wp;
		switch(imp)
		{
			case 30:
				wp = WaypointSprite_DeployPersonal("waypoint", self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "personal waypoint spawned at location\n");
				break;
			case 31:
				wp = WaypointSprite_DeployPersonal("waypoint", self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "personal waypoint spawned at crosshair\n");
				break;
			case 32:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployPersonal("waypoint", self.death_origin);
					if(wp)
					{
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
						WaypointSprite_Ping(wp);
					}
					sprint(self, "personal waypoint spawned at death location\n");
				}
				break;
			case 33:
				if(self.deadflag == DEAD_NO && teamplay)
				{
					wp = WaypointSprite_Attach("helpme", TRUE);
					if(wp)
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_HELPME, '1 0.5 0'); // TODO choose better color
					if(!wp)
						wp = self.waypointsprite_attachedforcarrier; // flag sprite?
					if(wp)
						WaypointSprite_Ping(wp);
					sprint(self, "HELP ME attached\n");
				}
				break;
			case 34:
				wp = WaypointSprite_DeployFixed("here", FALSE, self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "HERE spawned at location\n");
				break;
			case 35:
				wp = WaypointSprite_DeployFixed("here", FALSE, self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "HERE spawned at crosshair\n");
				break;
			case 36:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployFixed("here", FALSE, self.death_origin);
					if(wp)
					{
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
						WaypointSprite_Ping(wp);
					}
					sprint(self, "HERE spawned at death location\n");
				}
				break;
			case 37:
				wp = WaypointSprite_DeployFixed("danger", FALSE, self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "DANGER spawned at location\n");
				break;
			case 38:
				wp = WaypointSprite_DeployFixed("danger", FALSE, self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "DANGER spawned at crosshair\n");
				break;
			case 39:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployFixed("danger", FALSE, self.death_origin);
					if(wp)
					{
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
	}
	else if(imp >= 103 && imp <= 107)
	{
		if(g_waypointeditor)
		{
			switch(imp)
			{
				case 103:
					waypoint_schedulerelink(waypoint_spawn(self.origin, self.origin, 0));
					bprint(strcat("Waypoint spawned at ",vtos(self.origin),"\n"));
					break;
				case 104:
					e = navigation_findnearestwaypoint(self, FALSE);
					if (e)
					if not(e.wpflags & WAYPOINTFLAG_GENERATED)
					{
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
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						e.colormod_x = 1;
						e.effects &~= EF_NODEPTHTEST | EF_RED | EF_BLUE;
					}
					e2 = navigation_findnearestwaypoint(self, FALSE);
					navigation_markroutes(e2);
					i = 0;
					m = 0;
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						if(e.wpcost >= 10000000)
						{
							print("unreachable: ", etos(e), " ", vtos(e.origin), "\n");
							e.colormod_x = 0.1;
							e.effects |= EF_NODEPTHTEST | EF_BLUE;
							++i;
							++m;
						}
					}
					if(i)
						print(ftos(i), " waypoints cannot be reached from here in any way (marked with blue light)\n");
					navigation_markroutes_inverted(e2);
					i = 0;
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						if(e.wpcost >= 10000000)
						{
							print("cannot reach me: ", etos(e), " ", vtos(e.origin), "\n");
							e.colormod_x = 0.1;
							if not(e.effects & EF_NODEPTHTEST) // not already reported before
								++m;
							e.effects |= EF_NODEPTHTEST | EF_RED;
							++i;
						}
					}
					if(i)
						print(ftos(i), " waypoints cannot walk to here in any way (marked with red light)\n");
					if(m)
						print(ftos(m), " waypoints have been marked total\n");
					i = 0;
					for(e = findchain(classname, "info_player_deathmatch"); e; e = e.chain)
					{
						org = e.origin;
						tracebox(e.origin, PL_MIN, PL_MAX, e.origin - '0 0 512', MOVE_NOMONSTERS, world);
						setorigin(e, trace_endpos);
						if(navigation_findnearestwaypoint(e, FALSE))
						{
							setorigin(e, org);
							e.effects &~= EF_NODEPTHTEST;
							e.model = "";
						}
						else
						{
							setorigin(e, org);
							print("spawn without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
							e.effects |= EF_NODEPTHTEST;
							setmodel(e, self.model);
							e.frame = self.frame;
							e.skin = self.skin;
							setsize(e, '0 0 0', '0 0 0');
							++i;
						}
					}
					if(i)
						print(ftos(i), " spawnpoints have no nearest waypoint (marked by player model)\n");
					break;
			}
		}
	}
}


void() player_post_think {
	if (self.impulse)
		player_impulse();

	if (intermission_running)
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

float() player_customizeentityforclient {
	entity modelsource;

	self.alpha = player_calculate_alpha(self, other);
	if (GameHookChain_PlayerVisibleThroughWallFor(self, other))
		self.effects |= EF_NODEPTHTEST;
	else
		self.effects &~= EF_NODEPTHTEST;

	if(self.alpha < 0)
		return FALSE;

	if(self.modelindex == 0)
		return TRUE;

	modelsource = self;
#ifdef ALLOW_FORCEMODELS
	if(other.cvar_cl_forceplayermodelsfromnexuiz)
		if not(self.modelindex_lod0_from_nexuiz)
			modelsource = other;
	if(other.cvar_cl_forceplayermodels && sv_clforceplayermodels)
		modelsource = other;
#endif
	self.skin = modelsource.skinindex;
	float distance;
	float f;
	if(other.cvar_cl_playerdetailreduction <= 0) {
		if(other.cvar_cl_playerdetailreduction <= -2)
			self.modelindex = modelsource.modelindex_lod2;
		else if(other.cvar_cl_playerdetailreduction <= -1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	} else {
		distance = vlen(self.origin - other.origin);
		f = (distance + 100.0) * other.cvar_cl_playerdetailreduction;
		if(f > sv_loddistance2)
			self.modelindex = modelsource.modelindex_lod2;
		else if(f > sv_loddistance1)
			self.modelindex = modelsource.modelindex_lod1;
		else
			self.modelindex = modelsource.modelindex_lod0;
	}
	return TRUE;
}

void(entity spot) player_spawn {
	float currentlyPlaying, i;
	entity e, oldself;
	player_clear(FALSE);
	PhysicMarkAsTeleported(self);
	self.iscreature = TRUE;
	self.movetype = MOVETYPE_WALK;
	self.solid = SOLID_SLIDEBOX;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	if(independent_players)
		MAKE_INDEPENDENT_PLAYER(self);

	self.flags = FL_CLIENT;
	self.takedamage = DAMAGE_AIM;
	self.effects = 0;
	self.air_finished = time + 12;
	self.keys = 0;
	self.touch = push_touch;
	self.pushfactor = g_player_pushfactor;
	if not(GameHook_EquipPlayerHandle()) {
		if(inWarmupStage) {
			self.ammo_shells = warmup_start_ammo_shells;
			self.ammo_nails = warmup_start_ammo_nails;
			self.ammo_rockets = warmup_start_ammo_rockets;
			self.ammo_cells = warmup_start_ammo_cells;
			self.ammo_fuel = warmup_start_ammo_fuel;
			self.health = warmup_start_health;
			self.armorvalue = warmup_start_armorvalue;
			self.weapons = warmup_start_weapons;
		} else {
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
	self.switchweapon = weapon_best(self);
	if not(self.switchweapon)
		for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			if(player_hasweapon(self, i, TRUE, FALSE))
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
	self.think = world.think;
	self.nextthink = 0;
	self.dmg_team = 0;
	client_put_to_spot(spot);
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
		self.customizeentityforclient = player_customizeentityforclient;

	self.model = "";
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
	if(self.killcount == -666) {
		scores_clear(self);
		self.killcount = 0;
	}
	self.cnt = WEP_LASER;
	weapon_model_spawn();
	self.alpha = default_player_alpha;
	self.colormod = '1 1 1' * g_player_brightness;
	if(spawn_debug) {
		sprint(self, strcat("spawnpoint origin:  ", vtos(spot.origin), "\n"));
		remove(spot);	// usefull for checking if there are spawnpoints, that let drop through the floor
	}
	if (g_spawnsound)
		sound (self, CHAN_TRIGGER, "misc/spawn.wav", VOL_BASE, ATTN_NORM);

	oldself = self;
	self = spot;
	activator = oldself;
	trigger_use_targets();
	activator = world;
	self = oldself;
	if (sv_reset_on_join)
	if not(reset_on_join_done) {
		FOR_EACH_REALPLAYER(e)
			if(e.classname == "player")
				currentlyPlaying += 1;

		if (currentlyPlaying == sv_reset_on_join) {
			reset_on_join_done = TRUE;
			if (time > game_starttime)
				ReadyRestartForce();
		}
	}
	player_effects();
	GameHookChain_Spawn(spot);
	antilag_teleported(self);
	self.wasplayer = TRUE;
}

void(string pattern) player_precache_all_models {
    float globhandle, i, n;
    string f;

    globhandle = search_begin(pattern, TRUE, FALSE);
    if (globhandle < 0)
        return;
    n = search_getsize(globhandle);
    for (i = 0; i < n; ++i)
    {
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		if(sv_loddistance1)
			precache_model(f);
		if(substring(f, -9,5) == "_lod1")
			continue;
		if(substring(f, -9,5) == "_lod2")
			continue;
		if(!sv_loddistance1)
			precache_model(f);
		player_precache_sounds(strcat(f, ".sounds"));
    }
    search_end(globhandle);
}

float(entity plr, float wep) player_can_fire {
	if (PLAYER_DEAD(plr))
		return FALSE;

	if (time < game_starttime)
	if (!restart_active)
		return FALSE;

	if (timeoutStatus == 2) //don't allow the player to shoot while game is paused
		return FALSE;

	return GameHookChain_PlayerCanFire(plr, wep);
}

.float hasweapon_complain_spam;
float(entity cl, float wpn, float andammo, float complain) player_hasweapon {
	local float weaponbit, f;
	local entity oldself;

	if(time < cl.hasweapon_complain_spam)
		complain = 0;
	if(complain)
		cl.hasweapon_complain_spam = time + 0.2;

	if (wpn < WEP_FIRST || wpn > WEP_LAST)
	{
		if (complain)
			sprint(cl, "Invalid weapon\n");
		return FALSE;
	}
	weaponbit = weapon_bit(wpn);
	if (cl.weapons & weaponbit)
	{
		if (andammo)
		{
			if(cl.items & IT_UNLIMITED_WEAPON_AMMO)
			{
				f = 1;
			}
			else
			{
				oldself = self;
				self = cl;
				f = weapon_action(wpn, WR_CHECKAMMO1);
				f = f + weapon_action(wpn, WR_CHECKAMMO2);
				self = oldself;
			}
			if (!f)
			{
				if (complain)
				if(clienttype(cl) == CLIENTTYPE_REAL)
				{
					play2(cl, "weapons/unavailable.wav");
					sprint(cl, strcat("You don't have any ammo for the ^2", weapon_name(wpn), "\n"));
				}
				return FALSE;
			}
		}
		return TRUE;
	}
	if (complain)
	if (clienttype(cl) == CLIENTTYPE_REAL)
	{
		// DRESK - 3/16/07
		// Report Proper Weapon Status / Modified Weapon Ownership Message
		if(weaponsInMap & weaponbit)
		{
			sprint(cl, strcat("You do not have the ^2", weapon_name(wpn), "\n") );


			if(g_showweaponspawns)
			{
				entity e;
				string s;

				e = get_weaponinfo(wpn);
				s = e.model2;

				for(e = world; (e = findfloat(e, weapons, weaponbit)); )
				{
					if(e.classname == "droppedweapon")
						continue;
					if not(e.flags & FL_ITEM)
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
		}
		else
			sprint(cl, strcat("The ^2", weapon_name(wpn), "^7 is ^1NOT AVAILABLE^7 in this map\n") );

		play2(cl, "weapons/unavailable.wav");
	}
	return FALSE;
};

void() player_init {
	// Precache all player models if desired
	if (cvar("sv_precacheplayermodels")) {
		player_precache_sounds("sound/player/default.sounds");
		player_precache_all_models("models/player/*.zym");
		player_precache_all_models("models/player/*.dpm");
		player_precache_all_models("models/player/*.md3");
		player_precache_all_models("models/player/*.psk");
	}
	CACHE_CVAR(g_respawn_delay);
	CACHE_CVAR(g_respawn_mapsettings);
	CACHE_CVAR(g_respawn_mapsettings_delay);
	CACHE_CVAR(g_respawn_mapsettings_waves);
	CACHE_CVAR(g_respawn_waves);
	CACHE_CVAR(g_voice_flood_spv);
	CACHE_CVAR(g_voice_flood_spv_team);
	CACHE_CVAR(g_jetpack_attenuation);
	CACHE_CVAR(g_fullbrightplayers);
	CACHE_CVAR_STR(g_player_forcemodel);
	CACHE_CVAR_STR(g_player_forcemodel_red);
	CACHE_CVAR_STR(g_player_forcemodel_blue);
	CACHE_CVAR_STR(g_player_forcemodel_yellow);
	CACHE_CVAR_STR(g_player_forcemodel_pink);
	CACHE_CVAR_CHECK_EMPTY(g_player_forcecolor, -2);
	CACHE_CVAR_CHECK_EMPTY(g_player_forcecolor_red, -2);
	CACHE_CVAR_CHECK_EMPTY(g_player_forcecolor_blue, -2);
	CACHE_CVAR_CHECK_EMPTY(g_player_forcecolor_yellow, -2);
	CACHE_CVAR_CHECK_EMPTY(g_player_forcecolor_pink, -2);
	CACHE_CVAR(g_player_forceskin);
	CACHE_CVAR(g_player_forceskin_red);
	CACHE_CVAR(g_player_forceskin_blue);
	CACHE_CVAR(g_player_forceskin_yellow);
	CACHE_CVAR(g_player_forceskin_pink);
	CACHE_CVAR(g_balance_armor_blockpercent);
	CACHE_CVAR(g_balance_armor_regen);
	CACHE_CVAR(g_balance_armor_regenlinear);
	CACHE_CVAR(g_balance_armor_regenstable);
	CACHE_CVAR(g_balance_armor_rot);
	CACHE_CVAR(g_balance_armor_rotlinear);
	CACHE_CVAR(g_balance_armor_rotstable);
	CACHE_CVAR(g_balance_armor_limit);
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
	CACHE_CVAR(g_balance_pause_armor_rot_spawn);
	CACHE_CVAR(g_balance_pause_fuel_rot_spawn);
	CACHE_CVAR(g_balance_pause_health_regen_spawn);
	CACHE_CVAR(g_balance_pause_health_rot_spawn);
	CACHE_CVAR(g_forced_respawn);
	CACHE_CVAR(g_teamdamage_resetspeed);
	CACHE_CVAR(sv_reset_on_join);
	CACHE_CVAR(g_player_brightness);
	CACHE_CVAR(g_player_pushfactor);
	CACHE_CVAR(g_spawnshieldtime);
	CACHE_CVAR(g_spawnsound);
	CACHE_CVAR(sv_autotaunt);
	CACHE_CVAR(sv_taunt);
	if (cvar("sv_defaultcharacter")) { //compatibility with old cvars
		string s;
		if ((s = cvar_string("sv_defaultplayermodel")) != "") {
			unzone_ifneeded(g_player_forcemodel);
			g_player_forcemodel = zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_blue")) != "") {
			unzone_ifneeded(g_player_forcemodel_blue);
			g_player_forcemodel_blue = zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_red")) != "") {
			unzone_ifneeded(g_player_forcemodel_red);
			g_player_forcemodel_red = zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_yellow")) != "") {
			unzone_ifneeded(g_player_forcemodel_yellow);
			g_player_forcemodel_yellow = zone_ifneeded(s);
		}
		if ((s = cvar_string("sv_defaultplayermodel_pink")) != "") {
			unzone_ifneeded(g_player_forcemodel_pink);
			g_player_forcemodel_pink = zone_ifneeded(s);
		}
		g_player_forcecolor = ((cvar_string("sv_defaultplayercolors") == "") ? -2 : cvar("sv_defaultplayercolors"));
		g_player_forceskin = ((cvar_string("sv_defaultplayerskin") == "") ? -1 : cvar("sv_defaultplayerskin"));
	}
	if (g_player_forcemodel_blue == "" || g_player_forcemodel_blue == "0") {
		unzone_ifneeded(g_player_forcemodel_blue);
		g_player_forcemodel_blue = zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_red == "" || g_player_forcemodel_red == "0") {
		unzone_ifneeded(g_player_forcemodel_red);
		g_player_forcemodel_red = zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_yellow == "" || g_player_forcemodel_yellow == "0") {
		unzone_ifneeded(g_player_forcemodel_yellow);
		g_player_forcemodel_yellow = zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forcemodel_pink == "" || g_player_forcemodel_pink == "0") {
		unzone_ifneeded(g_player_forcemodel_pink);
		g_player_forcemodel_pink = zone_ifneeded(g_player_forcemodel);
	}
	if (g_player_forceskin_blue < 0)
		g_player_forceskin_blue = g_player_forceskin;

	if (g_player_forceskin_red < 0)
		g_player_forceskin_red = g_player_forceskin;

	if (g_player_forceskin_yellow < 0)
		g_player_forceskin_yellow = g_player_forceskin;

	if (g_player_forceskin_pink < 0)
		g_player_forceskin_pink = g_player_forceskin;

	player_precache_model(g_player_forcemodel);
	if (teamplay) {
		player_precache_model(g_player_forcemodel_red);
		player_precache_model(g_player_forcemodel_blue);
		player_precache_model(g_player_forcemodel_yellow);
		player_precache_model(g_player_forcemodel_pink);
	}
#define EXTRA_ANNOUNCER(x) do { unzone_ifneeded(sv_announcer_extra_##x); sv_announcer_extra_##x = cvar_string_zone_ifneeded("sv_announcer_extra_"#x); if (sv_announcer_extra_##x != "") { precache_sound(sv_announcer_extra_##x); print("Extra announcer sound "#x" ", sv_announcer_extra_##x, "\n");} } while (0)
	//Extra sounds
	EXTRA_ANNOUNCER(meleefrag);
	EXTRA_ANNOUNCER(pushfrag);
	CACHE_CVAR(sv_announcer_extra_doublekill_interval);
	if (sv_announcer_extra_doublekill_interval) {
		EXTRA_ANNOUNCER(doublekill);
	}
	EXTRA_ANNOUNCER(telefrag);
	EXTRA_ANNOUNCER(firstblood);
#undef EXTRA_ANNOUNCER
	CACHE_CVAR(bot_taunt);
	CACHE_CVAR(bot_talk);
}
