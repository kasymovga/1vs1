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
float g_balance_zapper_secondary_recoil;
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

.vector glowmod; //THIS PROPERTY CAUSE CSQC CRASH ON OLD NEXUIZ CLIENTS
void(void) weapon_zapper_spinner_think {
	if (self.owner.weapon != WEAPON_ZAPPER) {
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
	if (other.scorekeeper && other.scorekeeper.clientversion < CLIENT_VERSION_NEXUIZ)
		return FALSE;

	return weapon_model_customize();
}

void(void) weapon_zapper_spinner_spawn {
	if (self.zapper_spinner)
		return;

	if (self.weaponentity.cnt != self.weapon)
		return;

	entity o = akimbo_owner(self);
	entity s = spawn();
	s.classname = "zapper_spinner";
	s.owner = self;
	s.viewmodelforclient = o;
	s.colormap = self.colormap;
	s.color = weapon_zapper_beam_rgb((team_mode ? self.team : COLOR_TEAM2));
	s.think = weapon_zapper_spinner_think;
	s.nextthink = time;
	s.customizeentityforclient = weapon_zapper_spinner_customize;
	setattachment(s, self.weaponentity, "shot");
	setorigin(s, '-4 0 -0.5');
	setmodel(s, "models/weapons/rtzapper_hyperhonker.iqm");
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
	sf &= ~24;
	entity _owner = self.owner;
	float o = num_for_edict(_owner);
	if (o > client_max_count) {
		o = 0;
	}
	if (!o) {
		sf |= 16;
	}
	if (self.classname == "zapper_shield_beam")
		net_write_byte(MSG_ENTITY, NET_CSQC_ZAPPER_SHIELD);
	else {
		net_write_byte(MSG_ENTITY, NET_CSQC_ZAPPER);
		if (akimbo_active(_owner)) {
			sf |= 8;
		}
	}
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		if (o)
			net_write_byte(MSG_ENTITY, o);
		else
			net_write_byte(MSG_ENTITY, self.team);
	}
	if (sf & 2) {
		net_write_coord(MSG_ENTITY, self.pos1_x);
		net_write_coord(MSG_ENTITY, self.pos1_y);
		net_write_coord(MSG_ENTITY, self.pos1_z);
	}
	if (sf & 4) {
		net_write_coord(MSG_ENTITY, self.pos2_x);
		net_write_coord(MSG_ENTITY, self.pos2_y);
		net_write_coord(MSG_ENTITY, self.pos2_z);
	}
	if (sf & 32) {
		entity e = self.enemy.weaponentity;
		net_write_coord(MSG_ENTITY, e.shotorg_visual_x);
		net_write_coord(MSG_ENTITY, -e.shotorg_visual_y);
		net_write_coord(MSG_ENTITY, e.shotorg_visual_z);
	}
	return TRUE;
}

float(float secondary) weapon_zapper_beam_expired {
	entity o = self.owner;
	if (self.zapper_expire)
	if (time > self.zapper_expire)
		return TRUE;

	if (!secondary && o.zapper_shield)
		return TRUE;

	if (self.owner.zapper_heat >= 1)
		return TRUE;

	if (self.owner.weapon != WEAPON_ZAPPER)
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
	if (frametime) {
		if (map_finished) {
			remove(self);
			return;
		}
	} else { //we need finish route in server frames for sending information to client
		if (dt < wantedTicrate)
			return;
	}
	vector org = weapon_zapper_visual_shotorg(self.enemy);
	makevectors(self.owner.v_angle);
	antilag_begin(o);
	weapon_setup_shot(self.enemy, 0, "", 0);
	float fract;
	entity targ;
	vector end = weapon_shotorg + weapon_shotdir * self.zapper_range;
	trace_line(weapon_shotorg, end, FALSE, o);
	warpzone_trace_line(weapon_shotorg, end, FALSE, o);
	antilag_end();
	targ = trace_ent;
	end = trace_endpos;
	fract = trace_fraction;
	vector forcedir = warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir);
	for ( ;dt >= wantedTicrate; dt -= wantedTicrate) {
		float _damage = g_balance_zapper_primary_damage;
		float force  = g_balance_zapper_primary_force;
		weapon_score_fires(o, WEAPON_ZAPPER, 1);
		if (targ.takedamage) {
			float d = vlen(end - weapon_shotorg) * fract;
			float mindist = g_balance_zapper_primary_damagefalloff_mindist;
			float maxdist = g_balance_zapper_primary_damagefalloff_maxdist;
			float halflifedist = g_balance_zapper_primary_damagefalloff_halflife;
			float forcehalflifedist = g_balance_zapper_primary_damagefalloff_forcehalflife;
			_damage *= bullet_exponential_falloff(mindist, maxdist, halflifedist, d);
			force  *= bullet_exponential_falloff(mindist, maxdist, forcehalflifedist, d);
			weapon_score_hits(o, targ, WEAPON_ZAPPER, 1, _damage);
			damage(targ, self, o, _damage, WEAPON_ZAPPER, end, force * forcedir);
		}
		if not(self.enemy.items & IT_UNLIMITED_AMMO)
			self.enemy.ammo_cells = self.enemy.ammo_cells - g_balance_zapper_primary_ammo;

		self.zapper_lastdmg = self.zapper_lastdmg + wantedTicrate;
	}
	WEAPON_ATTACK_FINISHED(self.enemy) = self.zapper_lastdmg + wantedTicrate;
	if (org != self.pos1) {
		self.SendFlags |= 2;
		self.pos1 = org;
	}
	vector nowarp_end = warpzone_untransform_origin(warpzone_trace_transform, end);
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

	sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);
	entity e = spawn();
	e.classname = "zapper_beam";
	e.think = weapon_zapper_beam_think;
	e.nextthink = time;
	e.owner = akimbo_owner(self);
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
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_ZAPPERLIGHTNING);
	net_write_byte(MSG_BROADCAST, weapon_zapper_attack2_effect_team);
	net_write_coord(MSG_BROADCAST, from_x);
	net_write_coord(MSG_BROADCAST, from_y);
	net_write_coord(MSG_BROADCAST, from_z);
	net_write_coord(MSG_BROADCAST, to_x);
	net_write_coord(MSG_BROADCAST, to_y);
	net_write_coord(MSG_BROADCAST, to_z);
}

void(float ateam, vector from, vector to) weapon_zapper_attack2_effect {
	weapon_zapper_attack2_effect_team = ateam;
	warpzone_draw_effect_triangle(from, from, to, weapon_zapper_attack2_effect_cb);
}

void weapon_zapper_attack2_arc(entity targ, entity attacker, float _damage) {
	if (g_balance_zapper_secondary_arc <= 0)
		return;

	arc_damage(targ, attacker, _damage, WEAPON_ZAPPER | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
		g_balance_zapper_secondary_arc_range, g_balance_zapper_secondary_arc,
		g_balance_zapper_secondary_arc_force, COLOR_TEAM2, zapper_arc_hit
	);
}

void(entity o, vector start, vector start_visual, vector end, float fraction, float range, float bounces, float _damage, float force) weapon_zapper_attack2_beam {
	warpzone_trace_line(start, end, FALSE, (fraction ? world : o));
	vector plane_normal = trace_plane_normal;
	entity targ = trace_ent;
	vector forcedir = warpzone_transform_velocity(warpzone_trace_transform, normalize(end - start));
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

		weapon_score_hits(o, targ, WEAPON_ZAPPER, 1, _damage);
		damage(targ, o, o, _damage, WEAPON_ZAPPER | HITTYPE_SECONDARY, end, force * forcedir);
	}
	weapon_zapper_attack2_effect_team = o.team;
	if not(targ.takedamage)
	if (plane_normal != '0 0 0')
	if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	if (fraction < 1) {
		vector reflect_dir = forcedir - 2 * (forcedir * plane_normal) * plane_normal;
		if (bounces > 0) {
			weapon_zapper_attack2_beam(o, end, end, end + reflect_dir * range * (1 - fraction), fraction, range, bounces - 1, _damage, force);
		}
	}
	warpzone_draw_effect_triangle(start, start_visual, warpzone_untransform_origin(warpzone_trace_transform, end), weapon_zapper_attack2_effect_cb);
}

void(void) weapon_zapper_attack2 {
	float accum_time = g_balance_zapper_secondary_accumulate;
	float charge_time = 0;
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
	entity ao = akimbo_owner(self);
	antilag_begin(ao);
	sound(ao, CHAN_WEAPON, ((random() > 0.5) ? "misc/arc1.wav": "misc/arc2.wav"), VOL_BASE, ATTN_NORM);
	weapon_setup_shot(self, g_balance_zapper_secondary_recoil, "", 1);
	vector end = weapon_shotorg + weapon_shotdir * range;
	entity o = akimbo_owner(self);
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
		WEAPON_ATTACK_FINISHED(self.owner) = self.owner.zapper_shieldready = time + g_balance_zapper_secondary_shield_refire * weapon_rate_factor_for(self.owner);
	}
	self.nextthink = time;
}

void(entity p) weapon_zappber_shield_blocker_push {
	vector oo = self.owner.oldorigin;
	if (normalize(p.origin - oo) * v_forward < 0.3)
		return;

	if (vlen(p.origin - oo) <= 90) {
		float v = max(600, vlen(p.velocity));
		p.velocity = normalize(p.origin - oo) * v;
		p.lastpushtime = time;
		projectile_update(p);
	};
}

void(entity _shield) weapon_zapper_shield_blocker_setorigin {
	vector o = _shield.owner.origin + _shield.owner.mins_z * '0 0 1' + '0 0 45';
	vector a = _shield.owner.angles;
	_shield.oldorigin = o;
	makevectors(a);
	_shield.angles = a;
	setorigin(_shield, o - v_forward * 85);
	setorigin(_shield.enemy, o + v_forward * 40);
}

void(void) weapon_zapper_shield_blocker_think {
	if (self.owner.zapper_shield != self.zapper_shield) {
		antilag_remove(self);
		remove(self.enemy); //trigger
		remove(self);
		return;
	}
	weapon_zapper_shield_blocker_setorigin(self);
	self.nextthink = time;
}

void(void) weapon_zabber_shield_blocker_trigger_touch {
	makevectors(self.owner.angles);
	if (other.flags & FL_PROJECTILE) {
		if (other.classname != "bullet")
			weapon_zappber_shield_blocker_push(other);
	} else if (other.classname == "player") {
		if (other != self.owner.owner)
			weapon_zappber_shield_blocker_push(other);
	}
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
	sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);
	entity b = spawn();
	b.classname = "zapper_shield_beam";
	b.think = weapon_zapper_shield_beam_think;
	b.nextthink = time;
	b.enemy = self;
	b.owner = akimbo_owner(self);
	b.zapper_shield = e;
	net_link_entity(b, FALSE, 0, weapon_zapper_beam_send);
	e.zapper_beam = b;
	b = spawn();
	b.classname = "zapper_shield_blocker";
	b.owner = akimbo_owner(self);
	b.think = weapon_zapper_shield_blocker_think;
	b.zapper_shield = e;
	b.nextthink = time;
	b.solid = SOLID_BSP;
	b.armorvalue = 1; //for stopping bullets
	b.alpha = -1;
	setmodel(b, "models/vhshield.md3");
	antilag_add(b);
	e.zapper_shield = b;
	entity t = spawn();
	t.touch = weapon_zabber_shield_blocker_trigger_touch;
	t.solid = SOLID_TRIGGER;
	t.owner = b;
	setsize(t, '-70 -70 -70', '70 70 70');
	b.enemy = t;
	weapon_zapper_shield_blocker_setorigin(b);
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
	if (player_can_fire(self, TRUE) && self.weapon == WEAPON_ZAPPER) {
		if (self.zapper_accumulator.zapper_expire < time &&
			   (!self.zapper_buttonatck2
			   || self.zapper_buttonatck1
			   || time > self.zapper_accumulator.zapper_accumulate)) {
			weapon_zapper_attack2();
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_zapper_secondary_animtime, weapon_ready);
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
	if (req == WEAPON_REQUEST_AIM) {
		if (vlen(self.origin-self.enemy.origin) < g_balance_zapper_primary_range)
			self.zapper_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.zapper_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	} else if (req == WEAPON_REQUEST_THINK) {
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
						weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_zapper_primary_refire, weapon_ready);
					}
				}
		   } else if (weapon_prepareattack(0, (self.zapper_beam ? -1 : 0))) {
				if (self.zapper_heat >= 1 && g_balance_zapper_primary_heatup) {
					//W_SwitchWeapon_OutOfAmmo(self);
				} else {
					if not(self.zapper_beam) {
						weapon_zapper_attack1();
					}
					weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
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
						weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
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
					weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
				}
			} else if (weapon_prepareattack(1, g_balance_zapper_secondary_refire)) {
				weapon_zapper_attack2();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_zapper_secondary_animtime, weapon_ready);
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
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_model("models/vhshield.md3");
		precache_model("models/weapons/rtzapper_hyperhonker.iqm");
		precache_sound("weapons/fireball_fly2.wav");
		dlc_require("rm_effects_v2");
		dlc_require("pryaxe_balls");
		dlc_require("rm_arc");
		dlc_require("zapper_v2");
		dlc_precache_sound("weapons/zapper_fire.wav");
		dlc_precache_sound("weapons/zapper_fly.wav");
		dlc_precache_sound("misc/arc1.wav");
		dlc_precache_sound("misc/arc2.wav");
	} else if (req == WEAPON_REQUEST_RESETPLAYER){
		if (g_balance_zapper_primary_heatup || (g_balance_zapper_secondary_shield && g_balance_zapper_secondary_shield_heatup))
			self.zapper_heat = 0;
		else
			self.zapper_heat = -1;
	} else if (req == WEAPON_REQUEST_SETUP) {
		//weapon_setup(WEAPON_ZAPPER);
	} else if (req == WEAPON_REQUEST_CLEAR) {
		if (self.zapper_spinner) {
			remove(self.zapper_spinner);
			self.zapper_spinner = world;
		}
		if (self.zapper_beam) {
			remove(self.zapper_beam);
			self.zapper_beam = world;
		}
	} else if (req == WEAPON_REQUEST_CHECKAMMO1)
		return weapon_zapper_attack1_check_ammo(self);
	else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return weapon_zapper_attack2_check_ammo(self);
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WEAPON_REQUEST_KILLMESSAGE)
		weapon_deathtypestring = "was zapped by";
	else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_zapper_secondary_animtime);
		CVAR_CACHE(g_balance_zapper_primary_ammo);
		CVAR_CACHE(g_balance_zapper_primary_cooloff);
		CVAR_CACHE(g_balance_zapper_primary_cooloff_accel);
		CVAR_CACHE(g_balance_zapper_primary_damage);
		CVAR_CACHE(g_balance_zapper_primary_damagefalloff_forcehalflife);
		CVAR_CACHE(g_balance_zapper_primary_damagefalloff_mindist);
		CVAR_CACHE(g_balance_zapper_primary_damagefalloff_maxdist);
		CVAR_CACHE(g_balance_zapper_primary_damagefalloff_halflife);
		CVAR_CACHE(g_balance_zapper_primary_force);
		CVAR_CACHE(g_balance_zapper_primary_heatup);
		CVAR_CACHE(g_balance_zapper_primary_range);
		CVAR_CACHE(g_balance_zapper_primary_refire);
		CVAR_CACHE(g_balance_zapper_secondary);
		CVAR_CACHE(g_balance_zapper_secondary_accumulate);
		CVAR_CACHE(g_balance_zapper_secondary_ammo);
		CVAR_CACHE(g_balance_zapper_secondary_arc);
		CVAR_CACHE(g_balance_zapper_secondary_arc_force);
		CVAR_CACHE(g_balance_zapper_secondary_arc_range);
		CVAR_CACHE(g_balance_zapper_secondary_bounces);
		CVAR_CACHE(g_balance_zapper_secondary_charge_time);
		CVAR_CACHE(g_balance_zapper_secondary_damage);
		CVAR_CACHE(g_balance_zapper_secondary_damagefalloff_forcehalflife);
		CVAR_CACHE(g_balance_zapper_secondary_damagefalloff_halflife);
		CVAR_CACHE(g_balance_zapper_secondary_damagefalloff_maxdist);
		CVAR_CACHE(g_balance_zapper_secondary_damagefalloff_mindist);
		CVAR_CACHE(g_balance_zapper_secondary_force);
		CVAR_CACHE(g_balance_zapper_secondary_shield);
		CVAR_CACHE(g_balance_zapper_secondary_shield_ammo);
		CVAR_CACHE(g_balance_zapper_secondary_shield_heatup);
		CVAR_CACHE(g_balance_zapper_secondary_shield_lifetime);
		CVAR_CACHE(g_balance_zapper_secondary_shield_refire);
		CVAR_CACHE(g_balance_zapper_secondary_range);
		CVAR_CACHE(g_balance_zapper_secondary_recoil);
		CVAR_CACHE(g_balance_zapper_secondary_refire);
		if (cvar("g_balance_zapper_swap_buttons")) {
			zapper_buttonatck1 = BUTTON_ATCK2;
			zapper_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}

void spawnfunc_weapon_zapper(void) {
	weapon_defaultspawnfunc(WEAPON_ZAPPER);
}
