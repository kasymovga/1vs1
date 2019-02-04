// autotaunt system
.float cvar_cl_autotaunt;
.float cvar_cl_voice_directional;
.float cvar_cl_voice_directional_taunt_attenuation;

float g_chat_flood_burst;
float g_chat_flood_burst_team;
float g_chat_flood_burst_tell;
float g_chat_flood_lmax;
float g_chat_flood_lmax_team;
float g_chat_flood_lmax_tell;
float g_chat_flood_notify_flooder;
float g_chat_flood_damage_flooder;
float g_chat_flood_spl;
float g_chat_flood_spl_team;
float g_chat_flood_spl_tell;
string g_chat_forbidden_words;
float g_chat_forbidden_words_set_retard;
float g_chat_nospectators;
float g_chat_teamcolors;
float g_respawn_delay;
float g_respawn_mapsettings;
float g_respawn_mapsettings_delay;
float g_respawn_mapsettings_waves;
float g_respawn_waves;
float g_voice_flood_spv;
float g_voice_flood_spv_team;
float g_jetpack_attenuation;
float g_fullbrightplayers;

vector healtharmor_maxdamage(float h, float a, float armorblock)
{
	// NOTE: we'll always choose the SMALLER value...
	float healthdamage, armordamage, armorideal;
	vector v;
	healthdamage = (h - 1) / (1 - armorblock); // damage we can take if we could use more health
	armordamage = a + (h - 1); // damage we can take if we could use more armor
	armorideal = healthdamage * armorblock;
	v_y = armorideal;
	if(armordamage < healthdamage)
	{
		v_x = armordamage;
		v_z = 1;
	}
	else
	{
		v_x = healthdamage;
		v_z = 0;
	}
	return v;
}

// changes by LordHavoc on 03/29/04 and 03/30/04 at Vermeulen's request
// merged player_run and player_stand to player_anim
// added death animations to player_anim
// can now spawn thrown weapons from anywhere, not just from players
// thrown weapons now fade out after 20 seconds
// created PlayerGib function
// PlayerDie no longer uses hitloc or damage
// PlayerDie now supports dying animations as well as gibbing
// cleaned up PlayerDie a lot
// added CopyBody

.entity pusher;
.float pushltime;

void CopyBody(float keepvelocity)
{
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
	self.prevorigin = oldself.origin;
	self.reset = SUB_Remove;

	self = oldself;
}

float player_getspecies()
{
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

void play_countdown(float finished, string samp)
{
	if(clienttype(self) == CLIENTTYPE_REAL)
		if(floor(finished - time - frametime) != floor(finished - time))
			if(finished - time < 6)
				sound (self, CHAN_AUTO, samp, VOL_BASE, ATTN_NORM);
}

void player_effects()
{
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
	Fire_ApplyEffect(self);

	if (GameHookChain_PlayerEffectsHandle())
		return;

	if (g_fullbrightplayers)
		self.effects = self.effects | EF_FULLBRIGHT;

	if (time >= game_starttime)
	if (time < self.spawnshieldtime)
		self.effects = self.effects | (EF_ADDITIVE | EF_FULLBRIGHT);
}

void player_setupanimsformodel()
{
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
	animparseerror = FALSE;
	animfilename = strcat(self.model, ".animinfo");
	animfile = fopen(animfilename, FILE_READ);
	if (animfile >= 0)
	{
		self.anim_die1         = animparseline(animfile);
		self.anim_die2         = animparseline(animfile);
		self.anim_draw         = animparseline(animfile);
		self.anim_duck         = animparseline(animfile);
		self.anim_duckwalk     = animparseline(animfile);
		self.anim_duckjump     = animparseline(animfile);
		self.anim_duckidle     = animparseline(animfile);
		self.anim_idle         = animparseline(animfile);
		self.anim_jump         = animparseline(animfile);
		self.anim_pain1        = animparseline(animfile);
		self.anim_pain2        = animparseline(animfile);
		self.anim_shoot        = animparseline(animfile);
		self.anim_taunt        = animparseline(animfile);
		self.anim_run          = animparseline(animfile);
		self.anim_runbackwards = animparseline(animfile);
		self.anim_strafeleft   = animparseline(animfile);
		self.anim_straferight  = animparseline(animfile);
		self.anim_forwardright = animparseline(animfile);
		self.anim_forwardleft  = animparseline(animfile);
		self.anim_backright    = animparseline(animfile);
		self.anim_backleft     = animparseline(animfile);
		fclose(animfile);

		// derived anims
		self.anim_dead1 = '0 1 1' + '1 0 0' * (self.anim_die1_x + self.anim_die1_y - 1);
		self.anim_dead2 = '0 1 1' + '1 0 0' * (self.anim_die2_x + self.anim_die2_y - 1);

		if (animparseerror)
			print("Parse error in ", animfilename, ", some player animations are broken\n");
	}
	else
		dprint("File ", animfilename, " not found, assuming legacy .zym model animation timings\n");
	// reset animstate now
	setanim(self, self.anim_idle, TRUE, FALSE, TRUE);
};

void player_anim (void)
{
	updateanim(self);
	if (self.weaponentity)
		updateanim(self.weaponentity);

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
				setanim(self, self.anim_duckjump, FALSE, TRUE, self.restart_jump);
			else
				setanim(self, self.anim_jump, FALSE, TRUE, self.restart_jump);
			self.restart_jump = FALSE;
		}
		else if (self.crouch)
		{
			if (self.movement_x * self.movement_x + self.movement_y * self.movement_y > 20)
				setanim(self, self.anim_duckwalk, TRUE, FALSE, FALSE);
			else
				setanim(self, self.anim_duckidle, TRUE, FALSE, FALSE);
		}
		else if ((self.movement_x * self.movement_x + self.movement_y * self.movement_y) > 20)
		{
			if (self.movement_x > 0 && self.movement_y == 0)
				setanim(self, self.anim_run, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y == 0)
				setanim(self, self.anim_runbackwards, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y > 0)
				setanim(self, self.anim_straferight, TRUE, FALSE, FALSE);
			else if (self.movement_x == 0 && self.movement_y < 0)
				setanim(self, self.anim_strafeleft, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y > 0)
				setanim(self, self.anim_forwardright, TRUE, FALSE, FALSE);
			else if (self.movement_x > 0 && self.movement_y < 0)
				setanim(self, self.anim_forwardleft, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y > 0)
				setanim(self, self.anim_backright, TRUE, FALSE, FALSE);
			else if (self.movement_x < 0 && self.movement_y < 0)
				setanim(self, self.anim_backleft, TRUE, FALSE, FALSE);
			else
				setanim(self, self.anim_run, TRUE, FALSE, FALSE);
		}
		else
			setanim(self, self.anim_idle, TRUE, FALSE, FALSE);
	}

	if (self.weaponentity)
	if (!self.weaponentity.animstate_override)
		setanim(self.weaponentity, self.weaponentity.anim_idle, TRUE, FALSE, FALSE);
}

void SpawnThrownWeapon (vector org, float w)
{
	if(g_pinata)
	{
		float j;
		for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			if(self.weapons & W_WeaponBit(j))
				if(W_IsWeaponThrowable(j) || g_pinata_drop_all)
					W_ThrowNewWeapon(self, j, FALSE, self.origin, randomvec() * 175 + '0 0 325');
		}
	}
	else
		W_ThrowWeapon(randomvec() * 125 + '0 0 200', org - self.origin, FALSE);
}

void DropBackPack(vector org)
{
	entity ammopack, oldself;
	ammopack = spawn();
	ammopack.ammo_cells = self.ammo_cells;
	ammopack.ammo_rockets = self.ammo_rockets;
	ammopack.ammo_shells = self.ammo_shells;
	ammopack.ammo_nails = self.ammo_nails;
	ammopack.ammo_fuel = self.ammo_fuel;
	ammopack.classname = "droppedbackpack";
	ammopack.colormap = self.colormap;
	setorigin(ammopack, org);
	oldself = self;
	self = ammopack;
	StartItem (sv_model_backpack, "misc/itempickup.wav", 0, 0, "ammopack", IT_AMMO, W_WeaponBit(oldself.weapon), FL_WEAPON | FL_NO_WEAPON_STAY, commodity_pickupevalfunc, 3000);
	self = oldself;
}

void PlayerCorpseDamage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

	// damage resistance (ignore most of the damage from a bullet or similar)
	damage = max(damage - 5, 1);

	if (damage > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (damage > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM);

	if (damage > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
	if (damage > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);

	self.health = self.health - damage;
	self.dmg_take = self.dmg_take + damage;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;
	if (self.health <= -75 && self.modelindex != 0)
	{
		// don't use any animations as a gib
		self.frame = 0;
		self.dead_frame = 0;
		// view just above the floor
		self.view_ofs = '0 0 4';

		Violence_GibSplash(self, 1, 1, attacker);
		self.modelindex = 0; // restore later
		self.solid = SOLID_NOT; // restore later
	}
}


void PlayerClear(float killed)
{
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
	RemoveGrapplingHook(self); // Wazat's Grappling Hook

	GameHookChain_PlayerClear(killed);
	//Clear waypoints
	WaypointSprite_PlayerDead();
}

void PlayerDamage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	local float take, save, waves, sdelay, dh, da;
	GameHookChain_PlayerDamageMod = 1;
	if (GameHookChain_PlayerDamageHandle(inflictor, attacker, damage, deathtype, hitloc, force))
		return;

	dh = max(self.health, 0);
	da = max(self.armorvalue, 0);

	damage = damage * GameHookChain_PlayerDamageMod;

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
		Violence_GibSplash_At(ear1, force * -1, 2, bound(0, damage, 25) / 2 * (0.5 - 0.5 * f), self, attacker);
		Violence_GibSplash_At(ear2, force,      2, bound(0, damage, 25) / 2 * (0.5 + 0.5 * f), self, attacker);
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
		Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

	save = bound(0, damage * GameHookChain_ArmorBlockPercentMod() * g_balance_armor_blockpercent, self.armorvalue);
	take = bound(0, damage - save, damage);
	if (save > 10)
		sound (self, CHAN_PROJECTILE, "misc/armorimpact.wav", VOL_BASE, ATTN_NORM);
	else if (take > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (take > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM); // FIXME possibly remove them?

	if (take > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
	if (take > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);

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
					setanim(self, self.anim_pain1, FALSE, TRUE, TRUE);
				else
					setanim(self, self.anim_pain2, FALSE, TRUE, TRUE);
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
			shake = damage * 5 / (bound(0,skill,100) + 1);
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
		if (g_pickup_drop_backpack)
			DropBackPack (self.origin + (self.mins + self.maxs) * 0.5);
		else
			// throw a weapon
			SpawnThrownWeapon (self.origin + (self.mins + self.maxs) * 0.5, self.switchweapon);
		// print an obituary message
		Obituary (attacker, inflictor, self, deathtype);
		PlayerClear(TRUE);
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
			sdelay = cvar(strcat("g_", GetGametype(), "_respawn_delay"));
		if(!sdelay)
			sdelay = g_respawn_delay;
		if(!waves)
			waves = cvar(strcat("g_", GetGametype(), "_respawn_waves"));
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
			setanim(self, self.anim_die1, FALSE, TRUE, TRUE);
			self.dead_frame = self.anim_dead1_x;
		}
		else
		{
			setanim(self, self.anim_die2, FALSE, TRUE, TRUE);
			self.dead_frame = self.anim_dead2_x;
		}
		// set damage function to corpse damage
		self.event_damage = PlayerCorpseDamage;
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

float UpdateSelectedPlayer_countvalue(float v)
{
	return max(0, (v - 1.0) / 0.5);
}

float dist_point_line(vector p, vector l0, vector ldir)
{
	ldir = normalize(ldir);

	// remove the component in line direction
	p = p - (p * ldir) * ldir;

	// vlen of the remaining vector
	return vlen(p);
}

// returns: -2 if no hit, otherwise cos of the angle
// uses the global v_angle
float UpdateSelectedPlayer_canSee(entity p, float mincosangle, float maxdist)
{
	vector so, d;
	float c;

	if(p == self)
		return -2;

	if(p.deadflag)
		return -2;

	so = self.origin + self.view_ofs;
	d = p.origin - so;

	// misaimed?
	if(dist_point_line(d, '0 0 0', v_forward) > maxdist)
		return -2;

	// now find the cos of the angle...
	c = normalize(d) * v_forward;

	if(c <= mincosangle)
		return -2;

	// not visible in any way? forget it
	if(!checkpvs(so, p))
		return -2;

	traceline(so, p.origin, MOVE_NOMONSTERS, self);
	if(trace_fraction < 1)
		return -2;

	return c;
}

.float muted; // to be used by prvm_edictset server playernumber muted 1
.float retard_last_say;
void Say(entity source, float teamsay, entity privatesay, string msgin, float floodcontrol)
{
	string msgstr, colorstr, cmsgstr, namestr, fullmsgstr, sourcemsgstr, fullcmsgstr, sourcecmsgstr, privatemsgprefix;
	float flood, privatemsgprefixlen;
	entity head;
	if (g_chat_forbidden_words != "") {
		string s1, s2 = g_chat_forbidden_words;
		for (; s2 != ""; s2 = cdr(s2)) {
			s1 = car(s2);
			if (s1 == "") continue;
			if (strstrofs(strtolower(strdecolorize(msgin)), s1, 0) >= 0) {
				if (g_chat_forbidden_words_set_retard)
					source.retard = 1;
				else
					source.muted = 1;

				break;
			}
		}
	}

	if(source.retard > 0) {
		if (source.retard_last_say)
		if (time - source.retard_last_say < 60)
			return;

		source.retard_last_say = time;

		float n = tokenizebyseparator(cvar_string("sv_retard_say"), "|");
		if (n <= 0)
			return;

		n = floor(random(n));
		msgin = argv(n);
	}

	if(!teamsay && !privatesay)
		if(substring(msgin, 0, 1) == " ")
			msgin = substring(msgin, 1, strlen(msgin) - 1); // work around DP say bug (say_team does not have this!)

	msgin = formatmessage(source, msgin);

	if(msgin == "")
		return;

	if(source.classname != "player" && source.team <= 0)
		colorstr = "^0"; // black for spectators
	else if(teamplay)
		colorstr = Team_ColorCode(source.team);
	else
		teamsay = FALSE;

	if(intermission_running)
		teamsay = FALSE;

	msgin = trigger_magicear_processmessage_forallears(source, teamsay, privatesay, msgin);
	if(msgin == "")
		return;

	if(g_chat_teamcolors)
		namestr = playername(source);
	else
		namestr = source.netname;

	namestr = strcat(namestr, "^0#", ftos(num_for_edict(source)));

	if(privatesay)
	{
		msgstr = strcat("\{1}\{13}* ^3", namestr, "^3 tells you: ^7");
		privatemsgprefixlen = strlen(msgstr);
		msgstr = strcat(msgstr, msgin);
		cmsgstr = strcat(colorstr, "^3", namestr, "^3 tells you:\n^7", msgin);
		if(g_chat_teamcolors)
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", playername(privatesay), ": ^7");
		else
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", privatesay.netname, ": ^7");
	}
	else if(teamsay)
	{
		msgstr = strcat("\{1}\{13}", colorstr, "(^3", namestr, colorstr, ") ^7", msgin);
		cmsgstr = strcat(colorstr, "(^3", namestr, colorstr, ")\n^7", msgin);
	}
	else
	{
		msgstr = strcat("\{1}", namestr, "^7: ", msgin);
		cmsgstr = "";
	}

	msgstr = strcat(strreplace("\n", " ", msgstr), "\n"); // newlines only are good for centerprint
	fullmsgstr = msgstr;
	fullcmsgstr = cmsgstr;

	// FLOOD CONTROL
	flood = 0;
	var .float flood_field;

	if(floodcontrol)
	{
		float flood_spl;
		float flood_burst;
		float flood_lmax;
		float lines;
		if(privatesay)
		{
			flood_spl = g_chat_flood_spl_tell;
			flood_burst = g_chat_flood_burst_tell;
			flood_lmax = g_chat_flood_lmax_tell;
			flood_field = floodcontrol_chattell;
		}
		else if(teamsay)
		{
			flood_spl = g_chat_flood_spl_team;
			flood_burst = g_chat_flood_burst_team;
			flood_lmax = g_chat_flood_lmax_team;
			flood_field = floodcontrol_chatteam;
		}
		else
		{
			flood_spl = g_chat_flood_spl;
			flood_burst = g_chat_flood_burst;
			flood_lmax = g_chat_flood_lmax;
			flood_field = floodcontrol_chat;
		}
		flood_burst = max(0, flood_burst - 1);
		// to match explanation in default.cfg, a value of 3 must allow three-line bursts and not four!

		// do flood control for the default line size
		getWrappedLine_remaining = msgstr;
		msgstr = "";
		lines = 0;
		while(getWrappedLine_remaining && (!flood_lmax || lines <= flood_lmax))
		{
			msgstr = strcat(msgstr, " ", getWrappedLine(82.4289758859709, strlennocol)); // perl averagewidth.pl < gfx/vera-sans.width
			++lines;
		}
		msgstr = substring(msgstr, 1, strlen(msgstr) - 1);

		if(getWrappedLine_remaining != "")
		{
			msgstr = strcat(msgstr, "\n");
			flood = 2;
		}

		if(time >= source.flood_field)
		{
			source.flood_field = max(time - flood_burst * flood_spl, source.flood_field) + lines * flood_spl;
		}
		else
		{
			flood = 1;
			msgstr = fullmsgstr;
		}

		if (timeoutStatus == 2) //when game is paused, no flood protection
			source.flood_field = flood = 0;
	}

	if(flood == 2)
	{
		if(g_chat_flood_notify_flooder)
		{
			sourcemsgstr = strcat(msgstr, "\n^3FLOOD CONTROL: ^7message too long, trimmed\n");
			sourcecmsgstr = "";
		}
		else
		{
			sourcemsgstr = fullmsgstr;
			sourcecmsgstr = fullcmsgstr;
		}
		cmsgstr = "";
	}
	else
	{
		sourcemsgstr = msgstr;
		sourcecmsgstr = cmsgstr;
	}

	if(!privatesay)
	if(source.classname != "player" && source.team <= 0)
	{
		if(teamsay || (g_chat_nospectators == 1) || (g_chat_nospectators == 2 && !inWarmupStage))
			teamsay = -1; // spectators
	}

	if(flood)
		print("NOTE: ", playername(source), "^7 is flooding.\n");
	else if (!teamsay && !privatesay && source.retard <= 0 && !source.muted)
		GameHookChain_PublicPlayerChat(source, msgin);

	// build sourcemsgstr by cutting off a prefix and replacing it by the other one
	if(privatesay)
		sourcemsgstr = strcat(privatemsgprefix, substring(sourcemsgstr, privatemsgprefixlen, -1));

	if(source.muted)
	{
		// always fake the message
		sprint(source, sourcemsgstr);
		if(cmsgstr != "" && !privatesay)
			centerprint(source, sourcecmsgstr);
	}
	else if(flood == 1)
	{
		if(g_chat_flood_notify_flooder)
			sprint(source, strcat("^3FLOOD CONTROL: ^7wait ^1", ftos(source.flood_field - time), "^3 seconds\n"));
		else
		{
			sprint(source, sourcemsgstr);
			if(cmsgstr != "" && !privatesay)
				centerprint(source, sourcecmsgstr);
		}
		if (g_chat_flood_damage_flooder)
		if not(source.deadflag)
			Damage(source, world, world, g_chat_flood_damage_flooder, DEATH_HURTTRIGGER, source.origin, '0 0 0');
	}
	else if(privatesay)
	{
		sprint(source, sourcemsgstr);
		sprint(privatesay, msgstr);
		if(cmsgstr != "")
			centerprint(privatesay, cmsgstr);
	}
	else if(teamsay > 0)
	{
		sprint(source, sourcemsgstr);
		if(sourcecmsgstr != "")
			centerprint(source, sourcecmsgstr);
		FOR_EACH_REALPLAYER(head) if(head.team == source.team)
			if(head != source)
			{
				sprint(head, msgstr);
				if(cmsgstr != "")
					centerprint(head, cmsgstr);
			}
	}
	else if(teamsay < 0)
	{
		sprint(source, sourcemsgstr);
		FOR_EACH_REALCLIENT(head) if(head.classname != "player" && head.team <= 0)
			if(head != source)
				sprint(head, msgstr);
	}
	else if(sourcemsgstr != msgstr)
	{
		sprint(source, sourcemsgstr);
		FOR_EACH_REALCLIENT(head)
			if(head != source)
				sprint(head, msgstr);
	}
	else
		bprint(msgstr);
}

void Bot_Say(entity source, float teamsay, entity privatesay, string msglist, string prefix)
{
	float n;
	if (msglist == "")
		return;
	n = floor(random() * tokenizebyseparator(msglist, "|"));
	Say(source, teamsay, privatesay, strcat(prefix, argv(n)), FALSE);
}

string allvoicesamples;
float GetPlayerSoundSampleField_notFound;
float GetPlayerSoundSampleField_fixed;
.string GetVoiceMessageSampleField(string type)
{
	GetPlayerSoundSampleField_notFound = 0;
	GetPlayerSoundSampleField_fixed = 0;
	switch(type)
	{
#define _VOICEMSG(m) case #m: return playersound_##m;
		ALLVOICEMSGS
#undef _VOICEMSG
	}
	GetPlayerSoundSampleField_notFound = 1;
	return playersound_taunt;
}

.string GetPlayerSoundSampleField(string type)
{
	GetPlayerSoundSampleField_notFound = 0;
	GetPlayerSoundSampleField_fixed = 0;
	switch(type)
	{
#define _VOICEMSG(m) case #m: return playersound_##m;
		ALLPLAYERSOUNDS
#undef _VOICEMSG
	}
	GetPlayerSoundSampleField_notFound = 1;
	return playersound_taunt;
}

void PrecachePlayerSounds(string f)
{
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

void ClearPlayerSounds()
{
#define _VOICEMSG(m) if(self.playersound_##m) { strunzone(self.playersound_##m); self.playersound_##m = string_null; }
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

void LoadPlayerSounds(string f, float first)
{
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
		if(GetPlayerSoundSampleField_notFound)
			field = GetVoiceMessageSampleField(argv(0));
		if(GetPlayerSoundSampleField_notFound)
			continue;
		if(GetPlayerSoundSampleField_fixed)
			if not(first)
				continue;
		if(self.field)
			strunzone(self.field);
		self.field = strzone(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
}

.float modelindex_for_playersound;
void UpdatePlayerSounds()
{
	if(self.modelindex == self.modelindex_for_playersound)
		return;
	self.modelindex_for_playersound = self.modelindex;
	ClearPlayerSounds();
	LoadPlayerSounds("sound/player/default.sounds", 1);
	LoadPlayerSounds(strcat(self.model, ".sounds"), 0);
}

void VoiceMessage(string type, string msg)
{
	var .string sample;
	float ownteam;
	sample = GetVoiceMessageSampleField(type);

	if(GetPlayerSoundSampleField_notFound)
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
		Say(self, ownteam, world, msg, 0);

	if (flood)
		return;

	string s = randomsound_bystr(self.sample);
	if (type == "taunt") {
		if(self.classname == "player")
			if(self.deadflag == DEAD_NO)
				setanim(self, self.anim_taunt, FALSE, TRUE, TRUE);
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

float Player_CalculateAlpha(entity plr, entity viewer) {
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

void Player_Init() {
	CACHE_CVAR(g_chat_flood_burst);
	CACHE_CVAR(g_chat_flood_burst_team);
	CACHE_CVAR(g_chat_flood_burst_tell);
	CACHE_CVAR(g_chat_flood_lmax);
	CACHE_CVAR(g_chat_flood_lmax_team);
	CACHE_CVAR(g_chat_flood_lmax_tell);
	CACHE_CVAR(g_chat_flood_notify_flooder);
	CACHE_CVAR(g_chat_flood_damage_flooder);
	CACHE_CVAR(g_chat_flood_spl);
	CACHE_CVAR(g_chat_flood_spl_team);
	CACHE_CVAR(g_chat_flood_spl_tell);
	CACHE_CVAR(g_chat_nospectators);
	CACHE_CVAR(g_chat_teamcolors);
	CACHE_CVAR(g_respawn_delay);
	CACHE_CVAR(g_respawn_mapsettings);
	CACHE_CVAR(g_respawn_mapsettings_delay);
	CACHE_CVAR(g_respawn_mapsettings_waves);
	CACHE_CVAR(g_respawn_waves);
	CACHE_CVAR(g_voice_flood_spv);
	CACHE_CVAR(g_voice_flood_spv_team);
	CACHE_CVAR(g_jetpack_attenuation);
	CACHE_CVAR(g_fullbrightplayers);
	g_chat_forbidden_words = zone_ifneeded(strtolower(cvar_string("g_chat_forbidden_words")));
	CACHE_CVAR(g_chat_forbidden_words_set_retard);
}
