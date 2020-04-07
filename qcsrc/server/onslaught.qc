float g_ons;
void onslaught_generator_updatesprite(entity e);
void onslaught_controlpoint_updatesprite(entity e);
void onslaught_link_checkupdate();

.entity sprite;
.string target2;
.float iscaptured;
.float islinked;
.float isgenneighbor_red;
.float isgenneighbor_blue;
.float iscpneighbor_red;
.float iscpneighbor_blue;
.float isshielded;
.float lasthealth;
.float lastteam;
.float lastshielded;
.float lastcaptured;

.string model1, model2, model3;

float g_ons_gen_health;
float g_ons_cp_buildhealth;
float g_ons_cp_buildtime;
float g_ons_cp_health;
float g_ons_cp_regen;

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector vforce) onslaught_gib_damage {
	self.velocity = self.velocity + vforce;
}

.float giblifetime;
void(void) onslaught_throwgib_think {
	float d;
	self.nextthink = time + 0.05;
	d = self.giblifetime - time;
	if(d<0) {
		self.think = stdproc_remove;
		return;
	}
	if(d<1)
		self.alpha = d;

	if(d>2)
	if(random()<0.6)
		pointparticles(particleeffectnum("onslaught_generator_gib_flame"), self.origin, '0 0 0', 1);
}

void(vector v_from, vector v_to, string smodel, float f_lifetime, float b_burn) onslaught_throwgib {
	entity gib;
	gib = spawn();
	setmodel(gib, smodel);
	setorigin(gib, v_from);
	gib.solid = SOLID_NOT;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.takedamage = DAMAGE_YES;
	gib.event_damage = onslaught_gib_damage;
	gib.health = -1;
	gib.effects = EF_LOWPRECISION;
	gib.flags = FL_NOTARGET;
	gib.velocity = v_to;
	gib.giblifetime	= time + f_lifetime;
	if (b_burn) {
		gib.think = onslaught_throwgib_think;
		gib.nextthink = time + 0.05;
	} else
		entity_fade_setup(gib, gib.giblifetime, 2);
}

void(void) onslaught_updatelinks {
	entity l, links;
	float stop, t1, t2, t3, t4;
	// first check if the game has ended
	links = findchain(classname, "onslaught_link");
	// mark generators as being shielded and networked
	l = findchain(classname, "onslaught_generator");
	while (l) {
		l.islinked = l.iscaptured;
		l.isshielded = l.iscaptured;
		l = l.chain;
	}
	// mark points as shielded and not networked
	l = findchain(classname, "onslaught_controlpoint");
	while (l) {
		l.islinked = FALSE;
		l.isshielded = TRUE;
		l.isgenneighbor_red = FALSE;
		l.isgenneighbor_blue = FALSE;
		l.iscpneighbor_red = FALSE;
		l.iscpneighbor_blue = FALSE;
		l = l.chain;
	}
	// flow power outward from the generators through the network
	stop = FALSE;
	while (!stop) {
		stop = TRUE;
		l = links;
		while (l) {
			// if both points are captured by the same team, and only one of
			// them is powered, mark the other one as powered as well
			if (l.enemy.iscaptured && l.goalentity.iscaptured)
				if (l.enemy.islinked != l.goalentity.islinked)
					if (l.enemy.team == l.goalentity.team)
					{
						if (!l.goalentity.islinked)
						{
							stop = FALSE;
							l.goalentity.islinked = TRUE;
						}
						else if (!l.enemy.islinked)
						{
							stop = FALSE;
							l.enemy.islinked = TRUE;
						}
					}
			l = l.chain;
		}
	}
	// now that we know which points are powered we can mark their neighbors
	// as unshielded if team differs
	l = links;
	while (l) {
		if (l.goalentity.islinked) {
			if (l.goalentity.team != l.enemy.team)
				l.enemy.isshielded = FALSE;

			if(l.goalentity.classname == "onslaught_generator") {
				if(l.goalentity.team == COLOR_TEAM1)
					l.enemy.isgenneighbor_red = TRUE;
				else if(l.goalentity.team == COLOR_TEAM2)
					l.enemy.isgenneighbor_blue = TRUE;
			} else {
				if(l.goalentity.team == COLOR_TEAM1)
					l.enemy.iscpneighbor_red = TRUE;
				else if(l.goalentity.team == COLOR_TEAM2)
					l.enemy.iscpneighbor_blue = TRUE;
			}
		}
		if (l.enemy.islinked) {
			if (l.goalentity.team != l.enemy.team)
				l.goalentity.isshielded = FALSE;

			if(l.enemy.classname == "onslaught_generator") {
				if(l.enemy.team == COLOR_TEAM1)
					l.goalentity.isgenneighbor_red = TRUE;
				else if(l.enemy.team == COLOR_TEAM2)
					l.goalentity.isgenneighbor_blue = TRUE;
			} else {
				if(l.enemy.team == COLOR_TEAM1)
					l.goalentity.iscpneighbor_red = TRUE;
				else if(l.enemy.team == COLOR_TEAM2)
					l.goalentity.iscpneighbor_blue = TRUE;
			}
		}
		l = l.chain;
	}
	// now update the takedamage and alpha variables on generator shields
	l = findchain(classname, "onslaught_generator");
	while (l) {
		if (l.isshielded) {
			l.enemy.alpha = 1;
			l.takedamage = DAMAGE_NO;
			l.bot_attack = FALSE;
		} else {
			l.enemy.alpha = -1;
			l.takedamage = DAMAGE_AIM;
			l.bot_attack = TRUE;
		}
		l = l.chain;
	}
	// now update the takedamage and alpha variables on control point icons
	l = findchain(classname, "onslaught_controlpoint");
	while (l) {
		if (l.isshielded) {
			l.enemy.alpha = 1;
			if (l.goalentity) {
				l.goalentity.takedamage = DAMAGE_NO;
				l.goalentity.bot_attack = FALSE;
			}
		} else {
			l.enemy.alpha = -1;
			if (l.goalentity)
			{
				l.goalentity.takedamage = DAMAGE_AIM;
				l.goalentity.bot_attack = TRUE;
			}
		}
		onslaught_controlpoint_updatesprite(l);
		l = l.chain;
	}
	// count generators owned by each team
	t1 = t2 = t3 = t4 = 0;
	l = findchain(classname, "onslaught_generator");
	while (l) {
		if (l.iscaptured) {
			if (l.team == COLOR_TEAM1) t1 = 1;
			if (l.team == COLOR_TEAM2) t2 = 1;
			if (l.team == COLOR_TEAM3) t3 = 1;
			if (l.team == COLOR_TEAM4) t4 = 1;
		}
		onslaught_generator_updatesprite(l);
		l = l.chain;
	}
}

float(entity cp, float t) onslaught_controlpoint_can_be_linked {
	if(t == COLOR_TEAM1) {
		if(cp.isgenneighbor_red)
			return 2;
		if(cp.iscpneighbor_red)
			return 1;
	} else if(t == COLOR_TEAM2) {
		if(cp.isgenneighbor_blue)
			return 2;
		if(cp.iscpneighbor_blue)
			return 1;
	}
	return 0;
}

float(entity cp, float t) onslaught_controlpoint_attackable {
	// -2: SAME TEAM, attackable by enemy!
	// -1: SAME TEAM!
	// 0: off limits
	// 1: attack it
	// 2: touch it
	// 3: attack it (HIGH PRIO)
	// 4: touch it (HIGH PRIO)
	float a;
	if(cp.isshielded) {
		return 0;
	} else if(cp.goalentity) {
		// if there's already an icon built, nothing happens
		if(cp.team == t) {
			a = onslaught_controlpoint_can_be_linked(cp, COLOR_TEAM1 + COLOR_TEAM2 - t);
			if(a) // attackable by enemy?
				return -2; // EMERGENCY!

			return -1;
		}
		// we know it can be linked, so no need to check
		// but...
		a = onslaught_controlpoint_can_be_linked(cp, t);
		if(a == 2) // near our generator?
			return 3; // EMERGENCY!

		return 1;
	} else {
		// free point
		if(onslaught_controlpoint_can_be_linked(cp, t)) {
			a = onslaught_controlpoint_can_be_linked(cp, COLOR_TEAM1 + COLOR_TEAM2 - t);
			if(a == 2)
				return 4; // GET THIS ONE NOW!
			else
				return 2; // TOUCH ME
		}
	}
	return 0;
}

void(vector org) onslaught_generator_ring_spawn {
	effect_model_spawn("models/onslaught/shockwavetransring.md3", 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, -16, 0.1, 1.25, 0.25);
}

void(void) onslaught_generator_ray_think {
	self.nextthink = time + 0.05;
	if(self.count > 10) {
		self.think = stdproc_remove;
		return;
	}
	if(self.count > 5)
		self.alpha -= 0.1;
	else
		self.alpha += 0.1;

	self.scale += 0.2;
	self.count +=1;
}

void(vector org) onslaught_generator_ray_spawn {
	entity e;
	e = spawn();
	setmodel(e, "models/onslaught/ons_ray.md3");
	setorigin(e, org);
	e.angles = randomvec() * 360;
	e.alpha = 0;
	e.scale = random() * 5 + 8;
	e.think = onslaught_generator_ray_think;
	e.nextthink = time + 0.05;
}

void(vector org) onslaught_generator_shockwave_spawn {
	effect_shockwave_spawn("models/onslaught/shockwave.md3", org, -64, 0.75, 0.5);
}

void(void) onslaught_generator_damage_think {
	if(self.owner.health < 0) {
		self.think = stdproc_remove;
		return;
	}
	self.nextthink = time+0.1;
	// damaged fx (less probable the more damaged is the generator)
	if(random() < 0.9 - self.owner.health / self.owner.max_health) {
		if(random() < 0.01) {
			pointparticles(particleeffectnum("electro_ballexplode"), self.origin + random_pos('-50 -50 -20', '50 50 50'), '0 0 0', 1);
			sound(self, CHAN_TRIGGER, "onslaught/electricity_explode.wav", VOL_BASE, ATTN_NORM);
		} else
			pointparticles(particleeffectnum("torch_small"), self.origin + random_pos('-60 -60 -20', '60 60 60'), '0 0 0', 1);
	}
}

void(entity gd_owner) onslaught_generator_damage_spawn {
	entity e;
	e = spawn();
	e.owner = gd_owner;
	e.health = self.owner.health;
	setorigin(e, gd_owner.origin);
	e.think = onslaught_generator_damage_think;
	e.nextthink = time+1;
}

void(void) onslaught_generator_deaththink {
	vector org;
	float i;
	if not (self.count)
		self.count = 40;

	// White shockwave
	if(self.count==40||self.count==20) {
		onslaught_generator_ring_spawn(self.origin);
		sound(self, CHAN_TRIGGER, "onslaught/shockwave.wav", VOL_BASE, ATTN_NORM);
	}
	// Throw some gibs
	if(random() < 0.3) {
		i = random();
		if(i < 0.3)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 11 + '0 0 20', "models/onslaught/gen_gib1.md3", 6, TRUE);
		else if(i > 0.7)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 12 + '0 0 20', "models/onslaught/gen_gib2.md3", 6, TRUE);
		else
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 13 + '0 0 20', "models/onslaught/gen_gib3.md3", 6, TRUE);
	}
	// Spawn fire balls
	for(i=0;i < 10;++i) {
		org = self.origin + random_pos('-30 -30 -30' * i + '0 0 -20', '30 30 30' * i + '0 0 20');
		pointparticles(particleeffectnum("onslaught_generator_gib_explode"), org, '0 0 0', 1);
	}
	// Short explosion sound + small explosion
	if(random() < 0.25) {
		te_explosion(self.origin);
		sound(self, CHAN_TRIGGER, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
	}
	// Particles
	org = self.origin + random_pos(self.mins + '8 8 8', self.maxs + '-8 -8 -8');
	pointparticles(particleeffectnum("onslaught_generator_smallexplosion"), org, '0 0 0', 1);
	// rays
	if(random() > 0.25 ) {
		onslaught_generator_ray_spawn(self.origin);
	}
	// Final explosion
	if(self.count==1) {
		org = self.origin;
		te_explosion(org);
		onslaught_generator_shockwave_spawn(org);
		pointparticles(particleeffectnum("onslaught_generator_finalexplosion"), org, '0 0 0', 1);
		sound(self, CHAN_TRIGGER, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	} else
		self.nextthink = time + 0.05;

	self.count = self.count - 1;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) onslaught_generator_damage {
	float i;
	if (_damage <= 0)
		return;
	if(warmup_active)
		return;
	if (attacker != self) {
		if (self.isshielded) {
			// this is protected by a shield, so ignore the damage
			if (time > self.pain_finished)
				if (attacker.classname == "player")
				{
					sound_play2(attacker, "onslaught/damageblockedbyshield.wav");
					self.pain_finished = time + 1;
				}
			return;
		}
		if (time > self.pain_finished) {
			self.pain_finished = time + 10;
			bprint(team_colored_name(self.team), " generator under attack!\n");
			sound_play2team(self.team, "onslaught/generator_underattack.wav");
		}
	}
	self.health = self.health - _damage;
	WaypointSprite_UpdateHealth(self.sprite, self.health);
	// choose an animation frame based on health
	self.frame = 10 * bound(0, (1 - self.health / self.max_health), 1);
	// see if the generator is still functional, or dying
	if (self.health > 0) {
#ifdef ONSLAUGHT_SPAM
		float h, lh;
		lh = ceil(self.lasthealth / 100) * 100;
		h = ceil(self.health / 100) * 100;
		if(lh != h)
			bprint(team_colored_name(self.team), " generator has less than ", ftos(h), " health remaining\n");
#endif
		self.lasthealth = self.health;
	} else if not(warmup_active) {
		if (attacker == self)
			bprint(team_colored_name(self.team), " generator spontaneously exploded due to overtime!\n");
		else {
			string t;
			t = team_colored_name(attacker.team);
			bprint(team_colored_name(self.team), " generator destroyed by ", t, "!\n");
		}
		self.iscaptured = FALSE;
		self.islinked = FALSE;
		self.isshielded = FALSE;
		self.takedamage = DAMAGE_NO; // can't be hurt anymore
		self.event_damage = stdproc_nothing; // won't do anything if hurt
		self.count = 0;	// reset counter
		self.think = onslaught_generator_deaththink; // explosion sequence
		self.nextthink = time; // start exploding immediately
		self.think(); // do the first explosion now
		WaypointSprite_UpdateMaxHealth(self.sprite, 0);
		onslaught_updatelinks();
	}
	if(self.health <= 0)
		setmodel(self, "models/onslaught/generator_dead.md3");
	else if(self.health < self.max_health * 0.10)
		setmodel(self, "models/onslaught/generator_dmg9.md3");
	else if(self.health < self.max_health * 0.20)
		setmodel(self, "models/onslaught/generator_dmg8.md3");
	else if(self.health < self.max_health * 0.30)
		setmodel(self, "models/onslaught/generator_dmg7.md3");
	else if(self.health < self.max_health * 0.40)
		setmodel(self, "models/onslaught/generator_dmg6.md3");
	else if(self.health < self.max_health * 0.50)
		setmodel(self, "models/onslaught/generator_dmg5.md3");
	else if(self.health < self.max_health * 0.60)
		setmodel(self, "models/onslaught/generator_dmg4.md3");
	else if(self.health < self.max_health * 0.70)
		setmodel(self, "models/onslaught/generator_dmg3.md3");
	else if(self.health < self.max_health * 0.80)
		setmodel(self, "models/onslaught/generator_dmg2.md3");
	else if(self.health < self.max_health * 0.90)
		setmodel(self, "models/onslaught/generator_dmg1.md3");

	// Throw some flaming gibs on damage, more damage = more chance for gib
	if(random() < _damage/220) {
		sound(self, CHAN_TRIGGER, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
		i = random();
		if(i < 0.3)
			onslaught_throwgib(hitloc + '0 0 20', force * -1, "models/onslaught/gen_gib1.md3", 5, TRUE);
		else if(i > 0.7)
			onslaught_throwgib(hitloc + '0 0 20', force * -1, "models/onslaught/gen_gib2.md3", 5, TRUE);
		else
			onslaught_throwgib(hitloc + '0 0 20', force * -1, "models/onslaught/gen_gib3.md3", 5, TRUE);
	} else {
		// particles on every hit
		pointparticles(particleeffectnum("sparks"), hitloc, force * -1, 1);
		//sound on every hit
		if (random() < 0.5)
			sound(self, CHAN_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);
	}
	//throw some gibs on damage
	if(random() < _damage/200+0.2)
		if(random() < 0.5)
			onslaught_throwgib(hitloc + '0 0 20', randomvec()*360, "models/onslaught/gen_gib1.md3", 5, FALSE);
}

string(entity e, float t) onslaught_generator_waypointsprite_for_team {
	if(t == e.team)
	{
		if(e.team == COLOR_TEAM1)
			return "ons-gen-red";
		else if(e.team == COLOR_TEAM2)
			return "ons-gen-blue";
	}
	if(e.isshielded)
		return "ons-gen-shielded";

	if(e.team == COLOR_TEAM1)
		return "ons-gen-red";

	else if(e.team == COLOR_TEAM2)
		return "ons-gen-blue";

	return "";
}

void(entity e) onslaught_generator_updatesprite {
	string s1, s2, s3;
	s1 = onslaught_generator_waypointsprite_for_team(e, COLOR_TEAM1);
	s2 = onslaught_generator_waypointsprite_for_team(e, COLOR_TEAM2);
	s3 = onslaught_generator_waypointsprite_for_team(e, -1);
	WaypointSprite_UpdateSprites(e.sprite, s1, s2, s3);
	if(e.lastteam != e.team + 2 || e.lastshielded != e.isshielded) {
		e.lastteam = e.team + 2;
		e.lastshielded = e.isshielded;
		if(e.lastshielded)
		{
			if(e.team == COLOR_TEAM1 || e.team == COLOR_TEAM2)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, 0.5 * colormap_palette_color(e.team - 1, FALSE));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, '0.5 0.5 0.5');
		}
		else
		{
			if(e.team == COLOR_TEAM1 || e.team == COLOR_TEAM2)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, colormap_palette_color(e.team - 1, FALSE));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, '0.75 0.75 0.75');
		}
		WaypointSprite_Ping(e.sprite);
	}
}

string(entity e, float t) onslaught_controlpoint_waypointsprite_for_team {
	float a;
	if(t != -1) {
		a = onslaught_controlpoint_attackable(e, t);
		if(a == 3 || a == 4) { // ATTACK/TOUCH THIS ONE NOW
			if(e.team == COLOR_TEAM1)
				return "ons-cp-atck-red";
			else if(e.team == COLOR_TEAM2)
				return "ons-cp-atck-blue";
			else
				return "ons-cp-atck-neut";
		} else if(a == -2) { // DEFEND THIS ONE NOW
			if(e.team == COLOR_TEAM1)
				return "ons-cp-dfnd-red";
			else if(e.team == COLOR_TEAM2)
				return "ons-cp-dfnd-blue";
		} else if(e.team == t || a == -1 || a == 1) { // own point, or fire at it
			if(e.team == COLOR_TEAM1)
				return "ons-cp-red";
			else if(e.team == COLOR_TEAM2)
				return "ons-cp-blue";
		} else if(a == 2) // touch it
			return "ons-cp-neut";
	} else {
		if(e.team == COLOR_TEAM1)
			return "ons-cp-red";
		else if(e.team == COLOR_TEAM2)
			return "ons-cp-blue";
		else
			return "ons-cp-neut";
	}
	return "";
}

void(entity e) onslaught_controlpoint_updatesprite {
	string s1, s2, s3;
	s1 = onslaught_controlpoint_waypointsprite_for_team(e, COLOR_TEAM1);
	s2 = onslaught_controlpoint_waypointsprite_for_team(e, COLOR_TEAM2);
	s3 = onslaught_controlpoint_waypointsprite_for_team(e, -1);
	WaypointSprite_UpdateSprites(e.sprite, s1, s2, s3);

	float sh;
	sh = !(onslaught_controlpoint_can_be_linked(e, COLOR_TEAM1) || onslaught_controlpoint_can_be_linked(e, COLOR_TEAM2));

	if(e.lastteam != e.team + 2 || e.lastshielded != sh || e.iscaptured != e.lastcaptured) {
		if(e.iscaptured) { // don't mess up build bars!
			if(sh) {
				WaypointSprite_UpdateMaxHealth(e.sprite, 0);
			} else {
				WaypointSprite_UpdateMaxHealth(e.sprite, e.goalentity.max_health);
				WaypointSprite_UpdateHealth(e.sprite, e.goalentity.health);
			}
		}
		if(e.lastshielded) {
			if(e.team == COLOR_TEAM1 || e.team == COLOR_TEAM2)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, 0.5 * colormap_palette_color(e.team - 1, FALSE));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, '0.5 0.5 0.5');
		} else {
			if(e.team == COLOR_TEAM1 || e.team == COLOR_TEAM2)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, colormap_palette_color(e.team - 1, FALSE));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, '0.75 0.75 0.75');
		}
		WaypointSprite_Ping(e.sprite);
		e.lastteam = e.team + 2;
		e.lastshielded = sh;
		e.lastcaptured = e.iscaptured;
	}
}

void onslaught_generator_reset()
{
	self.team = self.team_saved;
	self.lasthealth = self.max_health = self.health = g_ons_gen_health;
	self.takedamage = DAMAGE_AIM;
	self.bot_attack = TRUE;
	self.iscaptured = TRUE;
	self.islinked = TRUE;
	self.isshielded = TRUE;
	self.enemy.solid = SOLID_NOT;
	self.think = onslaught_updatelinks;
	self.nextthink = time + 0.2;
	setmodel(self, "models/onslaught/generator.md3");
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
}

/*QUAKED spawnfunc_onslaught_generator (0 .5 .8) (-32 -32 -24) (32 32 64)
  Base generator.

  spawnfunc_onslaught_link entities can target this.

keys:
"team" - team that owns this generator (5 = red, 14 = blue, etc), MUST BE SET.
"targetname" - name that spawnfunc_onslaught_link entities will use to target this.
 */
void(void) spawnfunc_onslaught_generator {
	if (!g_ons) {
		remove(self);
		return;
	}
	entity e;
	if (!self.team)
		entity_abort("team must be set");

	team_teams_set_allowed(self.team);
	self.team_saved = self.team;
	self.colormap = 1024 + (self.team - 1) * 17;
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	self.lasthealth = self.max_health = self.health = g_ons_gen_health;
	setmodel(self, "models/onslaught/generator.md3");
	setsize(self, '-52 -52 -14', '52 52 75');
	setorigin(self, self.origin);
	self.takedamage = DAMAGE_AIM;
	self.bot_attack = TRUE;
	self.event_damage = onslaught_generator_damage;
	self.iscaptured = TRUE;
	self.islinked = TRUE;
	self.isshielded = TRUE;
	// helper entity that create fx when generator is damaged
	onslaught_generator_damage_spawn(self);
	// spawn shield model which indicates whether this can be damaged
	self.enemy = e = spawn();
	e.classname = "onslaught_generator_shield";
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	e.effects = EF_ADDITIVE;
	setmodel(e, "models/onslaught/generator_shield.md3");
	setorigin(e, self.origin);
	e.colormap = self.colormap;
	e.team = self.team;
	self.think = onslaught_updatelinks;
	self.nextthink = time + 0.2;
	entity_initialize(self, onslaught_updatelinks, INITPRIO_LAST);
	WaypointSprite_SpawnFixed(string_null, e.origin + '0 0 1' * e.maxs_z, self, sprite);
	WaypointSprite_UpdateRule(self.sprite, COLOR_TEAM2, SPRITERULE_TEAMPLAY);
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
	waypoint_spawnforitem(self);
	onslaught_updatelinks();
	self.reset = onslaught_generator_reset;
}

.float waslinked;

float ons_notification_time_team1;
float ons_notification_time_team2;

void onslaught_controlpoint_icon_damage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	entity oself;
	float nag;
	if (_damage <= 0)
		return;

	if (self.owner.isshielded) {
		// this is protected by a shield, so ignore the damage
		if (time > self.pain_finished)
			if (attacker.classname == "player") {
				sound_play2(attacker, "onslaught/damageblockedbyshield.wav");
				self.pain_finished = time + 1;
			}
		return;
	}
	if (attacker.classname == "player") {
		if(self.team == COLOR_TEAM1) {
			if(time - ons_notification_time_team1 > 10) {
				nag = TRUE;
				ons_notification_time_team1 = time;
			}
		} else if(self.team == COLOR_TEAM2) {
			if(time - ons_notification_time_team2 > 10) {
				nag = TRUE;
				ons_notification_time_team2 = time;
			}
		} else
			nag = TRUE;

		if(nag)
			sound_play2team(self.team, "onslaught/controlpoint_underattack.wav");
	}
	self.health = self.health - _damage;
	if(self.owner.iscaptured)
		WaypointSprite_UpdateHealth(self.owner.sprite, self.health);
	else
		WaypointSprite_UpdateBuildFinished(self.owner.sprite, time + (self.max_health - self.health) / (self.count / sys_ticrate));

	self.pain_finished = time + 1;
	self.punchangle = (2 * randomvec() - '1 1 1') * 45;
	// colormod flash when shot
	self.colormod = '2 2 2';
	// particles on every hit
	pointparticles(particleeffectnum("sparks"), hitloc, force*-1, 1);
	//sound on every hit
	if (random() < 0.5)
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE+0.3, ATTN_NORM);
	else
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE+0.3, ATTN_NORM);

	if (self.health < 0) {
		sound(self, CHAN_TRIGGER, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
		string t;
		t = team_colored_name(attacker.team);
		bprint(team_colored_name(self.team), " ", self.message, " control point destroyed by ", t, "\n");
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 25, "models/onslaught/controlpoint_icon_gib1.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 45, "models/onslaught/controlpoint_icon_gib2.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 45, "models/onslaught/controlpoint_icon_gib2.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 75, "models/onslaught/controlpoint_icon_gib4.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 75, "models/onslaught/controlpoint_icon_gib4.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 75, "models/onslaught/controlpoint_icon_gib4.md3", 3, FALSE);
		onslaught_throwgib(self.origin, (2 * randomvec() - '1 1 1') * 75, "models/onslaught/controlpoint_icon_gib4.md3", 3, FALSE);
		self.owner.goalentity = world;
		self.owner.islinked = FALSE;
		self.owner.iscaptured = FALSE;
		self.owner.team = 0;
		self.owner.colormap = 1024;
		WaypointSprite_UpdateMaxHealth(self.owner.sprite, 0);
		onslaught_updatelinks();
		// Use targets now (somebody make sure this is in the right place..)
		oself = self;
		self = self.owner;
		activator = self;
		trigger_use_targets ();
		self = oself;
		self.owner.waslinked = self.owner.islinked;
		if(self.owner.model != "models/onslaught/controlpoint_pad.md3")
			setmodel(self.owner, "models/onslaught/controlpoint_pad.md3");

		remove(self);
	}
}

void(void) onslaught_controlpoint_icon_think {
	entity oself;
	self.nextthink = time + sys_ticrate;
	if (time > self.pain_finished + 5) {
		if(self.health < self.max_health) {
			self.health = self.health + self.count;
			if (self.health >= self.max_health)
				self.health = self.max_health;

			WaypointSprite_UpdateHealth(self.owner.sprite, self.health);
		}
	}
	if (self.health < self.max_health * 0.25)
		setmodel(self, "models/onslaught/controlpoint_icon_dmg3.md3");
	else if (self.health < self.max_health * 0.50)
		setmodel(self, "models/onslaught/controlpoint_icon_dmg2.md3");
	else if (self.health < self.max_health * 0.75)
		setmodel(self, "models/onslaught/controlpoint_icon_dmg1.md3");
	else if (self.health < self.max_health * 0.90)
		setmodel(self, "models/onslaught/controlpoint_icon.md3");

	// colormod flash when shot
	self.colormod = '1 1 1' * (2 - bound(0, (self.pain_finished - time) / 10, 1));
	if(self.owner.islinked != self.owner.waslinked) {
		// unteam the spawnpoint if needed
		float t;
		t = self.owner.team;
		if(!self.owner.islinked)
			self.owner.team = 0;

		oself = self;
		self = self.owner;
		activator = self;
		trigger_use_targets ();
		self = oself;
		self.owner.team = t;
		self.owner.waslinked = self.owner.islinked;
	}
	if (self.punchangle_x > 2)
		self.punchangle_x = self.punchangle_x - 2;
	else if (self.punchangle_x < -2)
		self.punchangle_x = self.punchangle_x + 2;
	else
		self.punchangle_x = 0;

	if (self.punchangle_y > 2)
		self.punchangle_y = self.punchangle_y - 2;
	else if (self.punchangle_y < -2)
		self.punchangle_y = self.punchangle_y + 2;
	else
		self.punchangle_y = 0;

	if (self.punchangle_z > 2)
		self.punchangle_z = self.punchangle_z - 2;
	else if (self.punchangle_z < -2)
		self.punchangle_z = self.punchangle_z + 2;
	else
		self.punchangle_z = 0;

	self.angles_x = self.punchangle_x;
	self.angles_y = self.punchangle_y + self.mangle_y;
	self.angles_z = self.punchangle_z;
	self.mangle_y = self.mangle_y + 1.5;
	// damaged fx
	if(random() < 0.6 - self.health / self.max_health) {
		pointparticles(particleeffectnum("electricity_sparks"), self.origin + random_pos('-10 -10 -20', '10 10 20'), '0 0 0', 1);
		if(random() > 0.8)
			sound(self, CHAN_PAIN, "onslaught/ons_spark1.wav", VOL_BASE, ATTN_NORM);
		else if (random() > 0.5)
			sound(self, CHAN_PAIN, "onslaught/ons_spark2.wav", VOL_BASE, ATTN_NORM);
	}
}

void(void) onslaught_controlpoint_icon_buildthink {
	entity oself;
	float a;
	self.nextthink = time + sys_ticrate;
	// only do this if there is power
	a = onslaught_controlpoint_can_be_linked(self.owner, self.owner.team);
	if(!a)
		return;

	self.health = self.health + self.count;
	if (self.health >= self.max_health) {
		self.health = self.max_health;
		self.count = g_ons_cp_regen * sys_ticrate; // slow repair rate from now on
		self.think = onslaught_controlpoint_icon_think;
		sound(self, CHAN_TRIGGER, "onslaught/controlpoint_built.wav", VOL_BASE, ATTN_NORM);
		bprint(team_colored_name(self.team), " captured ", self.owner.message, " control point\n");
		self.owner.iscaptured = TRUE;
		WaypointSprite_UpdateMaxHealth(self.owner.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.owner.sprite, self.health);
		onslaught_updatelinks();
		// Use targets now (somebody make sure this is in the right place..)
		oself = self;
		self = self.owner;
		activator = self;
		trigger_use_targets ();
		self = oself;
		if (self.target != "")
			team_spawn_players(self.team);
	}
	self.alpha = self.health / self.max_health;
	// colormod flash when shot
	self.colormod = '1 1 1' * (2 - bound(0, (self.pain_finished - time) / 10, 1));
	if(self.owner.model != "models/onslaught/controlpoint_pad2.md3")
		setmodel(self.owner, "models/onslaught/controlpoint_pad2.md3");

	if(random() < 0.9 - self.health / self.max_health)
		pointparticles(particleeffectnum("rage"), self.origin + 10 * randomvec(), '0 0 -1', 1);
}

void onslaught_controlpoint_touch() {
	entity e;
	float a;
	if (other.classname != "player")
		return;

	a = onslaught_controlpoint_attackable(self, other.team);
	if(a != 2 && a != 4)
		return;

	// we've verified that this player has a legitimate claim to this point,
	// so start building the captured point icon (which only captures this
	// point if it successfully builds without being destroyed first)
	self.goalentity = e = spawn();
	e.classname = "onslaught_controlpoint_icon";
	e.owner = self;
	e.max_health = g_ons_cp_health;
	e.health = g_ons_cp_buildhealth;
	e.solid = SOLID_BBOX;
	e.movetype = MOVETYPE_NONE;
	e.scale = 1.2;
	setmodel(e, "models/onslaught/controlpoint_icon.md3");
	setsize(e, '-32 -32 -32', '32 32 32');
	setorigin(e, self.origin + '0 0 32');
	e.takedamage = DAMAGE_AIM;
	e.bot_attack = TRUE;
	e.event_damage = onslaught_controlpoint_icon_damage;
	e.team = other.team;
	e.colormap = 1024 + (e.team - 1) * 17;
	e.think = onslaught_controlpoint_icon_buildthink;
	e.nextthink = time + sys_ticrate;
	e.count = (e.max_health - e.health) * sys_ticrate / g_ons_cp_buildtime; // how long it takes to build
	sound(e, CHAN_TRIGGER, "onslaught/controlpoint_build.wav", VOL_BASE, ATTN_NORM);
	self.team = e.team;
	self.colormap = e.colormap;
	WaypointSprite_UpdateBuildFinished(self.sprite, time + (e.max_health - e.health) / (e.count / sys_ticrate));
	onslaught_updatelinks();
}

void(void) onslaught_controlpoint_reset {
	if(self.goalentity && self.goalentity != world)
		remove(self.goalentity);

	self.goalentity = world;
	self.team = 0;
	self.colormap = 1024;
	self.iscaptured = FALSE;
	self.islinked = FALSE;
	self.isshielded = TRUE;
	self.enemy.solid = SOLID_NOT;
	self.enemy.colormap = self.colormap;
	self.think = self.enemy.think = stdproc_nothing;
	self.nextthink = 0; // don't like stdproc_nothing :P
	setmodel(self, "models/onslaught/controlpoint_pad.md3");
	WaypointSprite_UpdateMaxHealth(self.sprite, 0);
	onslaught_updatelinks();
	activator = self;
	trigger_use_targets(); // to reset the structures, playerspawns etc.
}

/*QUAKED spawnfunc_onslaught_controlpoint (0 .5 .8) (-32 -32 0) (32 32 128)
  Control point. Be sure to give this enough clearance so that the shootable part has room to exist

  This should link to an spawnfunc_onslaught_controlpoint entity or spawnfunc_onslaught_generator entity.

keys:
"targetname" - name that spawnfunc_onslaught_link entities will use to target this.
"target" - target any entities that are tied to this control point, such as vehicles and buildable structure entities.
"message" - name of this control point (should reflect the location in the map, such as "center bridge", "north tower", etc)
 */
void(void) spawnfunc_onslaught_controlpoint {
	entity e;
	if (!g_ons) {
		remove(self);
		return;
	}
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, "models/onslaught/controlpoint_pad.md3");
	setorigin(self, self.origin);
	self.touch = onslaught_controlpoint_touch;
	self.team = 0;
	self.colormap = 1024;
	self.iscaptured = FALSE;
	self.islinked = FALSE;
	self.isshielded = TRUE;
	// spawn shield model which indicates whether this can be damaged
	self.enemy = e = spawn();
	e.classname = "onslaught_controlpoint_shield";
	e.scale = 0.7;
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	e.effects = EF_ADDITIVE;
	setmodel(e, "models/onslaught/controlpoint_shield.md3");
	setorigin(e, self.origin);
	e.colormap = self.colormap;
	waypoint_spawnforitem(self);
	WaypointSprite_SpawnFixed(string_null, e.origin + '0 0 1' * e.maxs_z, self, sprite);
	WaypointSprite_UpdateRule(self.sprite, COLOR_TEAM2, SPRITERULE_TEAMPLAY);
	onslaught_updatelinks();
	self.reset = onslaught_controlpoint_reset;
}

float(entity to, float sendflags) onslaught_link_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_RADARLINK);
	WriteByte(MSG_ENTITY, sendflags);
	if(sendflags & 1) {
		WriteCoord(MSG_ENTITY, self.goalentity.origin_x);
		WriteCoord(MSG_ENTITY, self.goalentity.origin_y);
		WriteCoord(MSG_ENTITY, self.goalentity.origin_z);
	}
	if(sendflags & 2) {
		WriteCoord(MSG_ENTITY, self.enemy.origin_x);
		WriteCoord(MSG_ENTITY, self.enemy.origin_y);
		WriteCoord(MSG_ENTITY, self.enemy.origin_z);
	}
	if(sendflags & 4) {
		WriteByte(MSG_ENTITY, self.clientcolors); // which is goalentity's color + enemy's color * 16
	}
	return TRUE;
}

void(void) onslaught_link_checkupdate {
	// TODO check if the two sides have moved (currently they won't move anyway)
	float redpower, bluepower;
	redpower = bluepower = 0;
	if(self.goalentity.islinked) {
		if(self.goalentity.team == COLOR_TEAM1)
			redpower = 1;
		else if(self.goalentity.team == COLOR_TEAM2)
			bluepower = 1;
	}
	if(self.enemy.islinked) {
		if(self.enemy.team == COLOR_TEAM1)
			redpower = 2;
		else if(self.enemy.team == COLOR_TEAM2)
			bluepower = 2;
	}
	float cc;
	if(redpower == 1 && bluepower == 2)
		cc = (COLOR_TEAM1 - 1) * 0x01 + (COLOR_TEAM2 - 1) * 0x10;
	else if(redpower == 2 && bluepower == 1)
		cc = (COLOR_TEAM1 - 1) * 0x10 + (COLOR_TEAM2 - 1) * 0x01;
	else if(redpower)
		cc = (COLOR_TEAM1 - 1) * 0x11;
	else if(bluepower)
		cc = (COLOR_TEAM2 - 1) * 0x11;
	else
		cc = 0;

	//print(etos(self), " rp=", ftos(redpower), " bp=", ftos(bluepower), " ");
	//print("cc=", ftos(cc), "\n");
	if(cc != self.clientcolors) {
		self.clientcolors = cc;
		self.SendFlags |= 4;
	}
	self.nextthink = time;
}

void(void) onslaught_link_delayed {
	self.goalentity = find(world, targetname, self.target);
	self.enemy = find(world, targetname, self.target2);
	if (!self.goalentity)
		entity_abort("can not find target\n");

	if (!self.enemy)
		entity_abort("can not find target2\n");

	self.SendFlags |= 3;
	self.think = onslaught_link_checkupdate;
	self.nextthink = time;
}

/*QUAKED spawnfunc_onslaught_link (0 .5 .8) (-16 -16 -16) (16 16 16)
  Link between control points.

  This entity targets two different spawnfunc_onslaught_controlpoint or spawnfunc_onslaught_generator entities, and suppresses shielding on both if they are owned by different teams.

keys:
"target" - first control point.
"target2" - second control point.
 */
void(void) spawnfunc_onslaught_link {
	if (!g_ons) {
		remove(self);
		return;
	}
	if (self.target == "" || self.target2 == "")
		entity_abort("target and target2 must be set\n");

	entity_initialize(self, onslaught_link_delayed, INITPRIO_FINDTARGET);
	net_link_entity(self, FALSE, 0, onslaught_link_send);
}

.vector ons_spawn_area;
void(float x, float y) onslaught_LocationRequest_Callback {
	if (self.deadflag)
		self.deadflag = DEAD_RESPAWNING;

	self.ons_spawn_area_x = x;
	self.ons_spawn_area_y = y;
	self.ons_spawn_area_z = 1;
}

entity() onslaught_SelectSpawnPoint {
	entity e, selected;
	if not(self.ons_spawn_area_z)
		return spawn_select(FALSE);

	vector v;
	float fmin, f;
	e = world;
	selected = world;
	fmin = -1;
	while ((e = find(e, classname, "info_player_deathmatch"))) {
		if (e.team != self.team)
			continue;

		v_x = e.origin_x;
		v_y = e.origin_y;
		f = vlen(v - self.ons_spawn_area);
		if (f < fmin || fmin < 0) {
			fmin = f;
			selected = e;
		}
	}
	return selected;
}

float(entity attacker, entity inflictor, float deathtype) onslaught_DeathHandle {
	self.ons_spawn_area = '0 0 0';
	if(clienttype(self) == CLIENTTYPE_REAL)
		LocationRequest_Create(self, "Select your spawn area", onslaught_LocationRequest_Callback);

	return FALSE;
}

var void(entity spot) onslaught_Spawn_NextLink;
void(entity spot) onslaught_Spawn {
	LocationRequest_Remove(self);
	onslaught_Spawn_NextLink(spot);
}

var void(float killed) onslaught_PlayerClear_NextLink;
void(float killed) onslaught_PlayerClear {
	if not(killed)
		LocationRequest_Remove(self);

	onslaught_PlayerClear_NextLink(killed);
}

// Onslaught winning condition:
// game terminates if only one team has a working generator (or none)
float(void) onslaught_WinningCondition {
	entity head;
	float t1, t2, t3, t4;
	if(warmup_active)
		return FALSE;

	// first check if the game has ended
	t1 = t2 = t3 = t4 = 0;
	head = find(world, classname, "onslaught_generator");
	while (head) {
		if (head.health > 0) {
			if (head.team == COLOR_TEAM1) t1 = 1;
			if (head.team == COLOR_TEAM2) t2 = 1;
			if (head.team == COLOR_TEAM3) t3 = 1;
			if (head.team == COLOR_TEAM4) t4 = 1;
		}
		head = find(head, classname, "onslaught_generator");
	}
	if (t1 + t2 + t3 + t4 < 2) {
		// game over, only one team remains (or none)
		world_winners_clear();
		if (t1) world_winners_set(team, COLOR_TEAM1);
		if (t2) world_winners_set(team, COLOR_TEAM2);
		if (t3) world_winners_set(team, COLOR_TEAM3);
		if (t4) world_winners_set(team, COLOR_TEAM4);
		return TRUE;
	}
	// Two or more teams remain
	return FALSE;
}

void(void) onslaught_init {
	g_ons = 1;
	GameHook_DeathHandle = onslaught_DeathHandle;
	onslaught_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = onslaught_Spawn;
	GameHook_SelectSpawnPoint = onslaught_SelectSpawnPoint;
	onslaught_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = onslaught_PlayerClear;
	gamehook_winning_condition = onslaught_WinningCondition;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_BotChooseRole = havocbot_chooserole_ons;
	precache_model("models/onslaught/generator.md3");
	precache_model("models/onslaught/generator_shield.md3");
	precache_model("models/onslaught/generator_dmg1.md3");
	precache_model("models/onslaught/generator_dmg2.md3");
	precache_model("models/onslaught/generator_dmg3.md3");
	precache_model("models/onslaught/generator_dmg4.md3");
	precache_model("models/onslaught/generator_dmg5.md3");
	precache_model("models/onslaught/generator_dmg6.md3");
	precache_model("models/onslaught/generator_dmg7.md3");
	precache_model("models/onslaught/generator_dmg8.md3");
	precache_model("models/onslaught/generator_dmg9.md3");
	precache_model("models/onslaught/generator_dead.md3");
	precache_model("models/onslaught/shockwave.md3");
	precache_model("models/onslaught/shockwavetransring.md3");
	precache_model("models/onslaught/gen_gib1.md3");
	precache_model("models/onslaught/gen_gib2.md3");
	precache_model("models/onslaught/gen_gib3.md3");
	precache_model("models/onslaught/ons_ray.md3");
	precache_sound("onslaught/generator_decay.wav");
	precache_sound("weapons/grenade_impact.wav");
	precache_sound("weapons/rocket_impact.wav");
	precache_sound("onslaught/generator_underattack.wav");
	precache_sound("onslaught/shockwave.wav");
	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	precache_sound("onslaught/electricity_explode.wav");
	precache_model("models/onslaught/controlpoint_pad.md3");
	precache_model("models/onslaught/controlpoint_pad2.md3");
	precache_model("models/onslaught/controlpoint_shield.md3");
	precache_model("models/onslaught/controlpoint_icon.md3");
	precache_model("models/onslaught/controlpoint_icon_dmg1.md3");
	precache_model("models/onslaught/controlpoint_icon_dmg2.md3");
	precache_model("models/onslaught/controlpoint_icon_dmg3.md3");
	precache_model("models/onslaught/controlpoint_icon_gib1.md3");
	precache_model("models/onslaught/controlpoint_icon_gib2.md3");
	precache_model("models/onslaught/controlpoint_icon_gib4.md3");
	precache_sound("onslaught/controlpoint_build.wav");
	precache_sound("onslaught/controlpoint_built.wav");
	precache_sound("weapons/grenade_impact.wav");
	precache_sound("onslaught/damageblockedbyshield.wav");
	precache_sound("onslaught/controlpoint_underattack.wav");
	precache_sound("onslaught/ons_spark1.wav");
	precache_sound("onslaught/ons_spark2.wav");
	CACHE_CVAR(g_ons_gen_health);
	CACHE_CVAR(g_ons_cp_buildhealth);
	CACHE_CVAR(g_ons_cp_buildtime);
	CACHE_CVAR(g_ons_cp_health);
	CACHE_CVAR(g_ons_cp_regen);
}
