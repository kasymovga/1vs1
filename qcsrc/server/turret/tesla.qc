.float toasted;
entity(entity from, float range, float _damage) turret_tesla_toast {
	entity e;
	entity etarget = NULL;
	float d,dd;
	float r;
	dd = range + 1;
	e = findradius(from.origin,range);
	while (e) {
		if ((e.toasted != 1) && (e != from)) {
			r = turret_validate_target(self,e,self.target_validate_flags);
			if (r > 0) {
				trace_line(from.origin,0.5 * (e.absmin + e.absmax),TRACE_MOVE_WORLDONLY,from);
				if (trace_fraction == 1.0) {
					d = vlen(e.origin - from.origin);
					if (d < dd) {
						dd = d;
						etarget = e;
					}
				}
			}
		}
		e = e.chain;
	}
	if (etarget) {
		te_smallflash(etarget.origin);
		effect_lightningarc(from.origin,etarget.origin);
		damage(etarget,self,self,_damage, WEAPON_ZAPPER, etarget.origin,'0 0 0');
		etarget.toasted = 1;
	}
	return etarget;
}

float(void) turret_tesla_firecheck {
	if not(turret_stdproc_firecheck())
		return 0;

	self.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
			 TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	self.enemy = turret_select_target();
	if (self.enemy)
		return 1;

	return 0;
}

void(void) turret_tesla_fire {
	entity e, t;
	float d, r, i;
	//w_deathtypestring = "discoverd how a tesla coil works";
	d = self.shot_dmg;
	r = self.target_range;
	e = spawn();
	setorigin(e,self.tur_shotorg);
	self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
			 TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	t = turret_tesla_toast(e,r,d);
	remove(e);
	if (t == world) return;
	self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
			 TFL_TARGETSELECT_TEAMCHECK;
	self.attack_finished_single = time + self.shot_refire;
	for (i = 0; i < 10; ++i) {
		d *= 0.5;
		r *= 0.85;
		t = turret_tesla_toast(t,r,d);
		if (t == world) break;
	}
	e = findchainfloat(toasted, 1);
	while (e) {
		e.toasted = 0;
		e = e.chain;
	}
}

void(void) turret_tesla_postthink {
	if not(self.tur_active) {
		self.tur_head.avelocity = '0 0 0';
		return;
	}
	if (self.ammo < self.shot_dmg) {
		self.tur_head.avelocity = '0 9 0' * (self.ammo / self.shot_dmg);
	} else {
		self.tur_head.avelocity = '0 90 0' * (self.ammo / self.shot_dmg);
		if (self.attack_finished_single > time)
			return;

		float f;
		f = (self.ammo / self.ammo_max);
		f = f*f;
		if (f > random())
			if (random() < 0.1)
				effect_lightningarc(self.tur_shotorg,self.tur_shotorg + (randomvec() * 350));
	}
}

/*QUAKED turret_tesla (0 .5 .8) ?
*/
void(void) spawnfunc_turret_tesla {
	precache_model ("models/turrets/tesla_head.md3");
	precache_model ("models/turrets/tesla_base.md3");
	if (self.netname == "")
		self.netname = "Tesla Coil";

	self.turrcaps_flags = TFL_TURRCAPS_HITSCAN | TFL_TURRCAPS_PLAYERKILL | TFL_TURRCAPS_MISSILEKILL;
	self.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	self.firecheck_flags     = TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_OWM_AMMO;
	self.shoot_flags         = TFL_SHOOT_CUSTOM;
	self.ammo_flags          = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
	self.aim_flags           = TFL_AIM_NO;
	self.track_flags         = TFL_TRACK_NO;
	if (turret_stdproc_init("tesla_std", "models/turrets/tesla_base.md3", "models/turrets/tesla_head.md3") == 0) {
		remove(self);
		return;
	}
	setsize(self,'-48 -48 0','48 48 96');
	self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	self.turret_firefunc = turret_tesla_fire;
	self.turret_postthink = turret_tesla_postthink;
	self.turret_firecheckfunc = turret_tesla_firecheck;
}

