float g_balance_zapper_primary_ammo;
float g_balance_zapper_primary_cooloff;
float g_balance_zapper_primary_cooloff_accel;
float g_balance_zapper_primary_damage;
float g_balance_zapper_primary_damagefalloff_forcehalflife;
float g_balance_zapper_primary_damagefalloff_halflife;
float g_balance_zapper_primary_damagefalloff_maxdist;
float g_balance_zapper_primary_damagefalloff_mindist;
float g_balance_zapper_primary_force;
float g_balance_zapper_primary_heatup;
float g_balance_zapper_primary_range;
float g_balance_zapper_primary_refire;
float g_balance_zapper_secondary;
float g_balance_zapper_secondary_animtime;
float g_balance_zapper_secondary_accumulate;
float g_balance_zapper_secondary_ammo;
float g_balance_zapper_secondary_arc;
float g_balance_zapper_secondary_arc_force;
float g_balance_zapper_secondary_arc_range;
float g_balance_zapper_secondary_bounces;
float g_balance_zapper_secondary_charge_time;
float g_balance_zapper_secondary_damage;
float g_balance_zapper_secondary_damagefalloff_forcehalflife;
float g_balance_zapper_secondary_damagefalloff_halflife;
float g_balance_zapper_secondary_damagefalloff_maxdist;
float g_balance_zapper_secondary_damagefalloff_mindist;
float g_balance_zapper_secondary_force;
float g_balance_zapper_secondary_shield;
float g_balance_zapper_secondary_shield_ammo;
float g_balance_zapper_secondary_shield_heatup;
float g_balance_zapper_secondary_shield_lifetime;
float g_balance_zapper_secondary_shield_refire;
float g_balance_zapper_secondary_range;
float g_balance_zapper_secondary_refire;
var .float zapper_buttonatck1 = BUTTON_ATCK;
var .float zapper_buttonatck2 = BUTTON_ATCK2;

.entity zapper_shield;
.entity zapper_accumulator;
.entity zapper_spinner;
.entity zapper_beam;

.float zapper_range;
.float zapper_expire;
.float zapper_lastdmg;
.float zapper_arc_hit;
.float zapper_heat;
.float zapper_coolofftime;
.float zapper_accumulate;
.float zapper_shieldready; // for g_balance_zapper_shield 2

vector(float t) weapon_zapper_beam_rgb {
	switch (t) {
		case COLOR_TEAM1:          return '5.0   1.0   0.5';
		case COLOR_TEAM2: default: return '0.5   1.0   5.0';
		case COLOR_TEAM3:          return '4.0   2.5   0.5';
		case COLOR_TEAM4:          return '5.0   0.7   3.0';
	}
}

.vector glowmod;
void(void) weapon_zapper_spinner_think {
	if (self.owner.weapon != WEP_ZAPPER) {
		self.owner.zapper_spinner = world;
		remove(self);
		return;
	}
	if (self.owner.zapper_beam || self.owner.zapper_shield)
		self.cnt = approach(self.cnt, 3, 4 * frametime);
	else
		self.cnt = approach(self.cnt, -0.1, 2 * frametime);

	float intens = self.cnt / 3;
	if (intens <= 0) {
		self.glowmod = '-1 -1 -1';
		self.skin = 0;
	} else {
		self.skin = 1;
		self.glowmod = self.color * pow(intens, 2);
	}
	self.angles_z = self.angles_z + frametime * self.cnt * 360;
	self.nextthink = time;
}

float(void) weapon_zapper_spinner_customize {
	return weapon_model_customize();
}

void(void) weapon_zapper_spinner_spawn {
	if (self.zapper_spinner)
		return;

	if (self.weaponentity.cnt != self.weapon)
		return;

	entity o = Akimbo_Owner(self);
	entity s = spawn();
	s.classname = "zapper_spinner";
	if (o.scorekeeper && o.scorekeeper.clientversion == CLIENT_OLDNEXUIZ)
		s.model = "null";
	else
		s.model = "models/weapons/rtzapper_hyperhonker.iqm";

	s.owner = self;
	s.viewmodelforclient = o;
	s.colormap = self.colormap;
	s.color = weapon_zapper_beam_rgb((team_mode ? self.team : COLOR_TEAM2));
	s.think = weapon_zapper_spinner_think;
	s.nextthink = time;
	s.customizeentityforclient = weapon_zapper_spinner_customize;
	setattachment(s, self.weaponentity, "shot");
	setorigin(s, '-4 0 -0.5');
	setmodel(s, s.model);
	self.zapper_spinner = s;
}

float(entity p) weapon_zapper_attack1_check_ammo {
	return p.ammo_cells >= g_balance_zapper_primary_ammo;
}

float(entity p) weapon_zapper_attack2_check_ammo {
	if (g_balance_zapper_secondary_shield)
		return p.ammo_cells >= 1;

	return p.ammo_cells >= g_balance_zapper_secondary_ammo;
}

float(entity to, float sf) weapon_zapper_beam_send {
	sf &~= 24;
	entity _owner = self.owner;
	float o = num_for_edict(_owner);
	if (o > client_max_count) {
		o = 0;
	}
	if (!o) {
		sf |= 16;
	}
	if (self.classname == "zapper_shield_beam")
		WriteByte(MSG_ENTITY, ENT_CLIENT_ZAPPER_SHIELD);
	else {
		WriteByte(MSG_ENTITY, ENT_CLIENT_ZAPPER);
		if (Akimbo_Active(_owner)) {
			sf |= 8;
		}
	}
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		if (o)
			WriteByte(MSG_ENTITY, o);
		else
			WriteByte(MSG_ENTITY, self.team);
	}
	if (sf & 2) {
		WriteCoord(MSG_ENTITY, self.pos1_x);
		WriteCoord(MSG_ENTITY, self.pos1_y);
		WriteCoord(MSG_ENTITY, self.pos1_z);
	}
	if (sf & 4) {
		WriteCoord(MSG_ENTITY, self.pos2_x);
		WriteCoord(MSG_ENTITY, self.pos2_y);
		WriteCoord(MSG_ENTITY, self.pos2_z);
	}
	if (sf & 32) {
		entity e = self.enemy.weaponentity;
		WriteCoord(MSG_ENTITY, e.shotorg_visual_x);
		WriteCoord(MSG_ENTITY, -e.shotorg_visual_y);
		WriteCoord(MSG_ENTITY, e.shotorg_visual_z);
	}
	return TRUE;
}

float(float secondary) weapon_zapper_beam_expired {
	entity o = self.owner;
	if (self.zapper_expire)
	if (time > self.zapper_expire)
		return TRUE;

	if (self.owner.zapper_heat >= 1)
		return TRUE;

	if (self.owner.weapon != WEP_ZAPPER)
		return TRUE;

	if (!player_can_fire(o, TRUE))
		return TRUE;

	if not(o.items & IT_UNLIMITED_WEAPON_AMMO) {
		if (secondary) {
			if (o.ammo_cells < 1)
				return TRUE;
		} else {
			if (!weapon_zapper_attack1_check_ammo(o))
				return TRUE;
			if (o.zapper_shield)
				return TRUE;
		}
	}
	return FALSE;
}

vector(entity o) weapon_zapper_visual_shotorg {
	float n = gettagindex(o.exteriorweaponentity, "_");
	vector org = gettaginfo(o.exteriorweaponentity, n);
	return org + v_forward * 30 + v_up * 3;
}

void(void) weapon_zapper_beam_think {
	if (weapon_zapper_beam_expired(FALSE)) {
		if (self.enemy.zapper_beam == self)
			self.enemy.zapper_beam = world;

		remove(self);
		return;
	}
	self.nextthink = time;
	entity o = self.owner;
	float dt = time - self.zapper_lastdmg;
	float rate = weapon_rate_factor_for(o);
	float wantedTicrate = g_balance_zapper_primary_refire * rate;
	if not(frametime) //we need finish route in server frames for sending information to client
	if (dt < wantedTicrate)
		return;

	vector org = weapon_zapper_visual_shotorg(self.enemy);
	makevectors(self.owner.v_angle);
	antilag_begin(o);
	weapon_setup_shot(self.enemy, 0, "", 0);
	float fract;
	entity targ;
	vector end = weapon_shotorg + weapon_shotdir * self.zapper_range;
	trace_line(weapon_shotorg, end, FALSE, o);
	WarpZone_TraceLine(weapon_shotorg, end, FALSE, o);
	antilag_end();
	targ = trace_ent;
	end = trace_endpos;
	fract = trace_fraction;
	vector forcedir = WarpZone_TransformVelocity(WarpZone_trace_transform, weapon_shotdir);
	for ( ;dt >= wantedTicrate; dt -= wantedTicrate) {
		float _damage = g_balance_zapper_primary_damage;
		float force  = g_balance_zapper_primary_force;
		damage_record_fires(o, WEP_ZAPPER, 1);
		if (targ.takedamage) {
			float d = vlen(end - weapon_shotorg) * fract;
			float mindist = g_balance_zapper_primary_damagefalloff_mindist;
			float maxdist = g_balance_zapper_primary_damagefalloff_maxdist;
			float halflifedist = g_balance_zapper_primary_damagefalloff_halflife;
			float forcehalflifedist = g_balance_zapper_primary_damagefalloff_forcehalflife;
			_damage *= bullet_exponential_falloff(mindist, maxdist, halflifedist, d);
			force  *= bullet_exponential_falloff(mindist, maxdist, forcehalflifedist, d);
			damage_record_hits(o, targ, WEP_ZAPPER, 1, _damage);
			damage(targ, self, o, _damage, WEP_ZAPPER, end, force * forcedir);
		}
		if (fract < 1)
		if (targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
			damage_info(end, _damage, 0, 0, force * forcedir, WEP_ZAPPER, self);

		if not(self.enemy.items & IT_UNLIMITED_AMMO)
			self.enemy.ammo_cells = self.enemy.ammo_cells - g_balance_zapper_primary_ammo;

		self.zapper_lastdmg = self.zapper_lastdmg + wantedTicrate;
	}
	ATTACK_FINISHED(self.enemy) = self.zapper_lastdmg + wantedTicrate;
	if (org != self.pos1) {
		self.SendFlags |= 2;
		self.pos1 = org;
	}
	vector nowarp_end = WarpZone_UnTransformOrigin(WarpZone_trace_transform, end);
	if (nowarp_end != self.pos2) {
		self.SendFlags |= 4;
		self.pos2 = nowarp_end;
	}
	if (self.enemy.zapper_heat >= 0) {
		self.enemy.zapper_heat = bound(0, self.enemy.zapper_heat + (g_balance_zapper_primary_heatup * dt) / rate, 1);
		self.enemy.zapper_coolofftime = time + dt;
	}
	if (o.teleport_time == time)
		self.SendFlags |= 70;
}

void(void) weapon_zapper_attack1 {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (!weapon_zapper_attack1_check_ammo(self))
		return;

	dlc_sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);
	entity e = spawn();
	e.classname = "zapper_beam";
	e.think = weapon_zapper_beam_think;
	e.nextthink = time;
	e.owner = Akimbo_Owner(self);
	e.enemy = self;
	e.zapper_range = g_balance_zapper_primary_range;
	float shottime = g_balance_zapper_primary_refire * weapon_rate_factor();
	e.zapper_lastdmg = time - shottime;
	net_link_entity(e, FALSE, 0, weapon_zapper_beam_send);
	e.SendFlags = 255;
	self.zapper_beam = e;
	entity oldself = self;
	self = e;
	weapon_zapper_beam_think();
	self = oldself;
}

float weapon_zapper_attack2_effect_team;
void(vector from, vector to, vector end) weapon_zapper_attack2_effect_cb {
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_ZAPPERLIGHTNING);
	WriteByte(MSG_BROADCAST, weapon_zapper_attack2_effect_team);
	WriteCoord(MSG_BROADCAST, from_x);
	WriteCoord(MSG_BROADCAST, from_y);
	WriteCoord(MSG_BROADCAST, from_z);
	WriteCoord(MSG_BROADCAST, to_x);
	WriteCoord(MSG_BROADCAST, to_y);
	WriteCoord(MSG_BROADCAST, to_z);
}

void(float ateam, vector from, vector to) weapon_zapper_attack2_effect {
	weapon_zapper_attack2_effect_team = ateam;
	WarpZone_DrawEffectTriangle(from, from, to, weapon_zapper_attack2_effect_cb);
}

void weapon_zapper_attack2_arc(entity targ, entity attacker, float _damage) {
	float arc = g_balance_zapper_secondary_arc;

	if (arc <= 0)
		return;

	arc_damage(targ, attacker, _damage, WEP_ZAPPER | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
		g_balance_zapper_secondary_arc_range, arc,
		g_balance_zapper_secondary_arc_force, COLOR_TEAM2, zapper_arc_hit
	);
}

void(entity o, vector start, vector start_visual, vector end, float fraction, float range, float bounces, float _damage, float force) weapon_zapper_attack2_beam {
	WarpZone_TraceLine(start, end, FALSE, (fraction ? world : o));
	vector plane_normal = trace_plane_normal;
	entity targ = trace_ent;
	vector forcedir = WarpZone_TransformVelocity(WarpZone_trace_transform, normalize(end - start));
	end = trace_endpos;
	fraction = fraction + (1 - fraction) * trace_fraction;
	if (targ.takedamage) {
		float d = vlen(end - start) * fraction;
		float mindist = g_balance_zapper_secondary_damagefalloff_mindist;
		float maxdist = g_balance_zapper_secondary_damagefalloff_maxdist;
		float halflifedist = g_balance_zapper_secondary_damagefalloff_halflife;
		float forcehalflifedist = g_balance_zapper_secondary_damagefalloff_forcehalflife;
		_damage *= bullet_exponential_falloff(mindist, maxdist, halflifedist, d);
		force  *= bullet_exponential_falloff(mindist, maxdist, forcehalflifedist, d);
		if (targ.iscreature)
			weapon_zapper_attack2_arc(targ, o, _damage);

		damage_record_hits(o, targ, WEP_ZAPPER, 1, _damage);
		damage(targ, o, o, _damage, WEP_ZAPPER | HITTYPE_SECONDARY, end, force * forcedir);
	}
	weapon_zapper_attack2_effect_team = o.team;
	if (targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		damage_info(end, _damage, 0, 0, force * forcedir, WEP_ZAPPER | HITTYPE_SECONDARY, o);

	if not(targ.takedamage)
	if (plane_normal != '0 0 0')
	if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	if (fraction < 1) {
		vector reflect_dir = forcedir - 2 * (forcedir * plane_normal) * plane_normal;
		if (bounces > 0) {
			weapon_zapper_attack2_beam(o, end, end, end + reflect_dir * range * (1 - fraction), fraction, range, bounces - 1, _damage, force);
		}
	}
	WarpZone_DrawEffectTriangle(start, start_visual, WarpZone_UnTransformOrigin(WarpZone_trace_transform, end), weapon_zapper_attack2_effect_cb);
}

void(void) weapon_zapper_attack2 {
	float accum_time = g_balance_zapper_secondary_accumulate;
	float charge_time;
	if (accum_time) {
		charge_time = g_balance_zapper_secondary_charge_time;
		if (!charge_time)
			charge_time = accum_time;
	}

	float accum  = (accum_time ? (min(1, (time - self.zapper_accumulate) * weapon_rate_factor_for(self.owner) / charge_time)) : 1);
	float _damage = g_balance_zapper_secondary_damage * accum;
	float force  = g_balance_zapper_secondary_force * accum;
	float range  = g_balance_zapper_secondary_range * accum;

	makevectors(self.v_angle);
	entity ao = Akimbo_Owner(self);
	antilag_begin(ao);
	dlc_sound(ao, CHAN_WEAPON, ((random() > 0.5) ? "misc/arc1.wav": "misc/arc2.wav"), VOL_BASE, ATTN_NORM);
	weapon_setup_shot(self, 5, "", 1);

	vector end = weapon_shotorg + weapon_shotdir * range;
	entity o = Akimbo_Owner(self);
	weapon_zapper_attack2_beam(o, weapon_shotorg, weapon_shotorg_visual, end, 0, range, g_balance_zapper_secondary_bounces, _damage, force);
	antilag_end();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_zapper_secondary_ammo;
}

void(void) weapon_zapper_shield_beam_think {
	if (self.enemy.zapper_shield != self.zapper_shield) {
		remove(self);
		return;
	}
	entity o = self.owner;
	vector end;
	vector org = weapon_zapper_visual_shotorg(self.enemy);
	makevectors(self.owner.angles);
	end = org + v_forward * 7;
	trace_line(org, end, FALSE, o);
	end = trace_endpos;
	if (org != self.pos1) {
		self.SendFlags |= 2;
		self.pos1 = org;
	}
	if (end != self.pos2) {
		self.SendFlags |= 4;
		self.pos2 = end;
	}
	self.nextthink = time;
}

void(void) weapon_zapper_shield_think {
	if (weapon_zapper_beam_expired(TRUE) || !self.owner.zapper_shield) {
		if (self.owner.zapper_shield == self)
			self.owner.zapper_shield = world;

		remove(self);
		return;
	} else {
		self.alpha = approach(self.alpha, 1, frametime * 10);
		if not(self.owner.items & IT_UNLIMITED_AMMO)
			self.owner.ammo_cells = max(0, self.owner.ammo_cells - frametime * g_balance_zapper_secondary_shield_ammo);

		if (self.owner.zapper_heat >= 0) {
			self.owner.zapper_heat = bound(0, self.owner.zapper_heat + (g_balance_zapper_secondary_shield_heatup * frametime), 1);
			self.owner.zapper_coolofftime = time + frametime;
		}
		ATTACK_FINISHED(self.owner) = self.owner.zapper_shieldready = time + g_balance_zapper_secondary_shield_refire * weapon_rate_factor_for(self.owner);
	}
	self.nextthink = time;
}

void(entity p) weapon_zappber_shield_blocker_push {
	if (normalize(p.origin - self.oldorigin) * v_forward < 0.5)
		return;

	if (vlen(p.origin - self.oldorigin) <= 90) {
		float v = max(600, vlen(p.velocity));
		p.velocity = normalize(p.origin - self.oldorigin) * v;
		projectile_update(p);
	}
}

void(entity _shield) weapon_zapper_shield_blocker_setorigin {
	vector o = _shield.owner.origin + _shield.owner.view_ofs;
	vector a = _shield.owner.angles;
	_shield.oldorigin = o;
	makevectors(a);
	_shield.angles = a;
	setorigin(_shield, o - v_forward * 85);
}

void(void) weapon_zapper_shield_blocker_think {
	if (self.owner.zapper_shield != self.zapper_shield) {
		antilag_remove(self);
		remove(self);
		return;
	}
	weapon_zapper_shield_blocker_setorigin(self);
	entity e;
	FOR_EACH_PLAYER(e) if (e != self.owner)
		weapon_zappber_shield_blocker_push(e);

	for (e = findchainflags(flags, FL_PROJECTILE); e; e = e.chain)
		if (e.classname != "bullet")
			weapon_zappber_shield_blocker_push(e);

	self.nextthink = time;
}

void(void) weapon_zapper_attack3 {
	entity e = spawn();
	e.classname = "zapper_shield";
	setmodel(e, "models/vhshield.md3");
	e.think = weapon_zapper_shield_think;
	e.owner = self;
	e.nextthink = time;
	e.alpha = 0.01;
	e.skin = 0;
	if (team_mode)
		e.skin = team_index(self.team);

	if (!e.skin)
		e.skin = team_index(COLOR_TEAM2);

	// This copies the entity! e becomes a viewmodel, the copy is attached to shotorg.
	weapon_attach_to_shotorg(e, '-120 0 0');
	// needs to be done AFTER weapon_attach_to_shotorg
	//e.customizeentityforclient = W_Zapper_Shield_CustomizeEntityForClient;
	self.zapper_shield = e;
	dlc_sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);
	entity b = spawn();
	b.classname = "zapper_shield_beam";
	b.think = weapon_zapper_shield_beam_think;
	b.nextthink = time;
	b.enemy = self;
	b.owner = Akimbo_Owner(self);
	b.zapper_shield = e;
	net_link_entity(b, FALSE, 0, weapon_zapper_beam_send);
	e.zapper_beam = b;
	b = spawn();
	b.classname = "zapper_shield_blocker";
	b.owner = Akimbo_Owner(self);
	b.think = weapon_zapper_shield_blocker_think;
	b.zapper_shield = e;
	b.nextthink = time;
	b.solid = SOLID_BSP;
	b.alpha = -1;
	setmodel(b, "models/vhshield.md3");
	weapon_zapper_shield_blocker_setorigin(b);
	antilag_add(b);
	e.zapper_shield = b;
}

void(void) weapon_zapper_cooloff {
	if (self.zapper_heat < 0)
		return;

	float a = bound(0, (time - self.zapper_coolofftime) * g_balance_zapper_primary_cooloff_accel, 1);
	if (!a)
		return;

	self.zapper_heat = bound(0, self.zapper_heat - g_balance_zapper_primary_cooloff * frametime * a, 1);
}

void(void) weapon_zapper_accumulate {
	setorigin(self, self.owner.origin);
	self.nextthink = time;
	self = self.owner;
	float accumulate_end = 1;
	if (player_can_fire(self, TRUE) && self.weapon == WEP_ZAPPER) {
		if (self.zapper_accumulator.zapper_expire < time &&
			   (!self.zapper_buttonatck2
			   || self.zapper_buttonatck1
			   || time > self.zapper_accumulator.zapper_accumulate)) {
			weapon_zapper_attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_zapper_secondary_animtime, weapon_ready);
		} else
			accumulate_end = 0;
	}
	if (accumulate_end) {
		sound_stop(self, CHAN_WEAPON2);
		remove(self.zapper_accumulator);
		self.zapper_accumulator = world;
	}
}


float(float req) weapon_zapper {
	if (req == WR_AIM) {
		if (vlen(self.origin-self.enemy.origin) < g_balance_zapper_primary_range)
			self.zapper_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.zapper_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	} else if (req == WR_THINK) {
		weapon_zapper_spinner_spawn();
		weapon_zapper_cooloff();
		if (self.zapper_buttonatck1) {
			if (self.zapper_buttonatck2 && g_balance_zapper_secondary_shield == 2) {
				if (weapon_prepareattack(1, -1)) {
					if (self.zapper_heat >= 1 && g_balance_zapper_secondary_shield_heatup) {
						//W_SwitchWeapon_OutOfAmmo(self);
					} else {
						if (self.zapper_shield) {
							self.zapper_shield.zapper_expire = time + g_balance_zapper_secondary_shield_lifetime;
						} else if (time > self.zapper_shieldready) {
							weapon_zapper_attack3();
						}
						weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_primary_refire, weapon_ready);
					}
				}
		   } else if (weapon_prepareattack(0, (self.zapper_beam ? -1 : 0))) {
				if (self.zapper_heat >= 1 && g_balance_zapper_primary_heatup) {
					//W_SwitchWeapon_OutOfAmmo(self);
				} else {
					if not(self.zapper_beam) {
						weapon_zapper_attack1();
					}
					weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
				}
			}
		} else if (self.zapper_buttonatck2 && g_balance_zapper_secondary) {
			if (g_balance_zapper_secondary_shield == 1) {
				if (weapon_prepareattack(1, -1)) {
					if (self.zapper_heat >= 1 && g_balance_zapper_secondary_shield_heatup) {
						//W_SwitchWeapon_OutOfAmmo(self);
					} else {
						if (self.zapper_shield) {
							self.zapper_shield.zapper_expire = time + g_balance_zapper_secondary_shield_lifetime;
						} else {
							weapon_zapper_attack3();
						}
						weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
					}
				}
			} else if (g_balance_zapper_secondary_accumulate) {
				if (!self.zapper_accumulator && weapon_prepareattack(1, g_balance_zapper_secondary_refire)) {
					self.zapper_accumulate = time; //Accumulate start time
					self.zapper_accumulator = spawn();
					self.zapper_accumulator.zapper_accumulate = time + g_balance_zapper_secondary_accumulate; //Accumulate end time
					self.zapper_accumulator.owner = self;
					self.zapper_accumulator.think = weapon_zapper_accumulate;
					self.zapper_accumulator.nextthink = time;
					self.zapper_accumulator.zapper_expire = time + g_balance_zapper_secondary_animtime;
					sound(self, CHAN_WEAPON2, "weapons/fireball_fly2.wav", VOL_BASE, ATTN_NORM);
					weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
				}
			} else if (weapon_prepareattack(1, g_balance_zapper_secondary_refire)) {
				weapon_zapper_attack2();
				weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
			}
		}
		if (self.zapper_beam) {
			if not(self.zapper_buttonatck1) {
				remove(self.zapper_beam);
				self.zapper_beam = world;
			} else {
				entity e = self;
				self = self.zapper_beam;
				weapon_zapper_beam_think();
				self = e;
			}
		}
	} else if (req == WR_PRECACHE) {
		precache_model("models/vhshield.md3");
		precache_model("models/weapons/rtzapper_hyperhonker.iqm");
		precache_sound("weapons/fireball_fly2.wav");
		dlc_require("rm_effects_v2");
		dlc_require("pryaxe_balls");
		dlc_require("rm_arc");
		dlc_require("zapper_v2");
		if (dlc_ready("rm_arc"))
		if (dlc_ready("zapper_v2")) {
			dlc_precache_sound("weapons/zapper_fire.wav");
			dlc_precache_sound("weapons/zapper_fly.wav");
			dlc_precache_sound("misc/arc1.wav");
			dlc_precache_sound("misc/arc2.wav");
		}
	} else if (req == WR_RESETPLAYER){
		if (g_balance_zapper_primary_heatup || (g_balance_zapper_secondary_shield && g_balance_zapper_secondary_shield_heatup))
			self.zapper_heat = 0;
		else
			self.zapper_heat = -1;
	} else if (req == WR_SETUP) {
		weapon_setup(WEP_ZAPPER);
	} else if (req == WR_CLEAR) {
		if (self.zapper_spinner) {
			remove(self.zapper_spinner);
			self.zapper_spinner = world;
		}
		if (self.zapper_beam) {
			remove(self.zapper_beam);
			self.zapper_beam = world;
		}
	} else if (req == WR_CHECKAMMO1)
		return weapon_zapper_attack1_check_ammo(self);
	else if (req == WR_CHECKAMMO2)
		return weapon_zapper_attack2_check_ammo(self);
	else if (req == WR_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
		weapon_deathtypestring = "was zapped by";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_zapper_secondary_animtime);
		CACHE_CVAR(g_balance_zapper_primary_ammo);
		CACHE_CVAR(g_balance_zapper_primary_cooloff);
		CACHE_CVAR(g_balance_zapper_primary_cooloff_accel);
		CACHE_CVAR(g_balance_zapper_primary_damage);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_mindist);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_halflife);
		CACHE_CVAR(g_balance_zapper_primary_force);
		CACHE_CVAR(g_balance_zapper_primary_heatup);
		CACHE_CVAR(g_balance_zapper_primary_range);
		CACHE_CVAR(g_balance_zapper_primary_refire);
		CACHE_CVAR(g_balance_zapper_secondary);
		CACHE_CVAR(g_balance_zapper_secondary_accumulate);
		CACHE_CVAR(g_balance_zapper_secondary_ammo);
		CACHE_CVAR(g_balance_zapper_secondary_arc);
		CACHE_CVAR(g_balance_zapper_secondary_arc_force);
		CACHE_CVAR(g_balance_zapper_secondary_arc_range);
		CACHE_CVAR(g_balance_zapper_secondary_bounces);
		CACHE_CVAR(g_balance_zapper_secondary_charge_time);
		CACHE_CVAR(g_balance_zapper_secondary_damage);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_halflife);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_mindist);
		CACHE_CVAR(g_balance_zapper_secondary_force);
		CACHE_CVAR(g_balance_zapper_secondary_shield);
		CACHE_CVAR(g_balance_zapper_secondary_shield_ammo);
		CACHE_CVAR(g_balance_zapper_secondary_shield_heatup);
		CACHE_CVAR(g_balance_zapper_secondary_shield_lifetime);
		CACHE_CVAR(g_balance_zapper_secondary_shield_refire);
		CACHE_CVAR(g_balance_zapper_secondary_range);
		CACHE_CVAR(g_balance_zapper_secondary_refire);
		if (cvar("g_balance_zapper_swap_buttons")) {
			zapper_buttonatck1 = BUTTON_ATCK2;
			zapper_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}

void spawnfunc_weapon_zapper(void) {
	weapon_defaultspawnfunc(WEP_ZAPPER);
}
