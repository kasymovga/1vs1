/*
 * supported formats:
 *
 * 1. simple animated model, muzzlr flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - invisible model controlling the animation
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        weapon = attachment for v_tuba.md3
 *    v_tuba.md3 - first and third person model
 *    g_tuba.md3 - pickup model
 *
 * 2. fully animated model, muzzle flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        handle = corresponding to the origin of v_tuba.md3 (used for muzzle flashes)
 *    v_tuba.md3 - third person model
 *    g_tuba.md3 - pickup model
 *
 * 3. fully animated model, muzzle flash handling on v_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *    v_tuba.md3 - third person model
 *      tags:
 *        shot = muzzle end (for muzzle flashes)
 *    g_tuba.md3 - pickup model
 */

float(void) weapon_model_customize {
	self.viewmodelforclient = akimbo_owner(self.owner);
	if (other.classname == "spectator")
		if (other.enemy == self.viewmodelforclient)
			self.viewmodelforclient = other;

	return TRUE;
}

float(void) weapon_model_exterior_customize {
	self.alpha = player_alpha(self.owner, other);
	return (self.alpha > 0);
}

void(void) weapon_model_dlc_reset {
	setattachment(self.weaponentity, self, "weapon");
}

void(entity e) weapon_model_remove {
	if (e.weaponentity)
		remove(e.weaponentity);

	if (e.exteriorweaponentity) {
		if (e.exteriorweaponentity.exteriorweaponentity)
			remove(e.exteriorweaponentity.exteriorweaponentity);

		remove(e.exteriorweaponentity);
	}
	remove(e);
}

void(void) weapon_model_think {
	float v_shot_idx;
	self.nextthink = time;
	if (map_intermission_running)
		self.frame = self.anim_idle_x;

	if (self.owner.weaponentity != self) {
		weapon_model_remove(self);
		return;
	}
	if (PLAYER_REALLY_DEAD(self.owner)) {
		self.model = "";
		if (self.weaponentity)
			self.weaponentity.model = "";

		return;
	}
	if (self.cnt != self.owner.weapon || self.deadflag != self.owner.deadflag) {
		self.deadflag = self.owner.deadflag;
		if (self.owner.weaponname != "" && self.owner.weapon) {
			self.cnt = self.owner.weapon;
			// if there is a child entity, hide it until we're sure we use it
			if (self.weaponentity)
				self.weaponentity.model = "";

			setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
			v_shot_idx = weapon_gettagindex(self, "shot"); // used later
			self.dlc_reset = NULL;
			if (sv_qcweaponanimation) {
				self.angles = '0 0 0';
				makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
				self.movedir = weapon_offset_x * v_forward - weapon_offset_y * v_right + weapon_offset_z * v_up + weapon_adjust;
				self.movedir_x += 32;
				self.spawnorigin = self.movedir;
				// oldorigin - not calculated here
			} else {
				setmodel(self, strcat("models/weapons/h_", self.owner.weaponname, ".dpm")); // precision set below
				entity e = weapon_info(self.owner.weapon);
				self.anim_fire1  = e.anim_fire1;
				self.anim_fire2  = e.anim_fire2;
				self.anim_idle   = e.anim_idle;
				self.anim_reload = e.anim_reload;
				// if we have a "weapon" tag, let's attach the v_ model to it ("invisible hand" style model)
				// if we don't, this is a "real" animated model
				if (weapon_gettagindex(self, "weapon")) {
					if (!self.weaponentity)
						self.weaponentity = spawn();

					setmodel(self.weaponentity, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision does not matter
					self.dlc_reset = weapon_model_dlc_reset;
					self.dlc_reset();
				} else {
					if (self.weaponentity)
						remove(self.weaponentity);

					self.weaponentity = NULL;
				}
				setorigin(self,'0 0 0');
				self.angles = '0 0 0';
				self.frame = 0;
				self.viewmodelforclient = NULL;
				float idx;
				idx = weapon_gettagindex(self, "shot");
				if (idx) {
					self.movedir = gettaginfo(self, idx);
					if (sv_debug_weapon_tags) {
						if not(self.exteriorweaponentity)
							self.exteriorweaponentity = spawn();

						setmodel(self.exteriorweaponentity, "models/ebomb.mdl");
						self.exteriorweaponentity.colormod = '1 0 0';
						setattachment(self.exteriorweaponentity, self, "shot");
					}
				} else {
					print("WARNING: weapon model ", self.model, " does not support the 'shot' tag, will display shots TOTALLY wrong\n");
					self.movedir = '0 0 0';
				}
				idx = weapon_gettagindex(self, "shell");
				if (idx) {
					self.spawnorigin = gettaginfo(self, idx);
					if (sv_debug_weapon_tags) {
						if not(self.exteriorweaponentity.exteriorweaponentity)
							self.exteriorweaponentity.exteriorweaponentity = spawn();

						setmodel(self.exteriorweaponentity.exteriorweaponentity, "models/ebomb.mdl");
						self.exteriorweaponentity.exteriorweaponentity.colormod = '1 1 0';
						setattachment(self.exteriorweaponentity.exteriorweaponentity, self, "shell");
					}
				} else {
					print("WARNING: weapon model ", self.model, " does not support the 'shell' tag, will display casings wrong\n");
					self.spawnorigin = self.movedir;
				}
				if (v_shot_idx) {
					self.oldorigin = '0 0 0';
				} else {
					if (self.weaponentity)
						idx = weapon_gettagindex(self, "weapon");
					else
						idx = weapon_gettagindex(self, "handle");

					if (idx) {
						self.oldorigin = self.movedir - gettaginfo(self, idx);
					} else {
						print("WARNING: weapon model ", self.model, " does not support the 'handle' tag and neither does the v_ model support the 'shot' tag, will display muzzle flashes TOTALLY wrong\n");
						self.oldorigin = '0 0 0'; // there is no way to recover from this
					}
				}
				self.viewmodelforclient = akimbo_owner(self.owner);
			}
		} else {
			self.model = "";
			self.cnt = 0;
			if (self.weaponentity)
				remove(self.weaponentity);

			self.weaponentity = NULL;
			self.movedir = '0 0 0';
			self.spawnorigin = '0 0 0';
			self.oldorigin = '0 0 0';
			self.anim_fire1  = '0 1 0.01';
			self.anim_fire2  = '0 1 0.01';
			self.anim_idle   = '0 1 0.01';
			self.anim_reload = '0 1 0.01';
		}
		self.view_ofs = '0 0 0';
		if (self.movedir_x >= 0) {
			vector v0;
			v0 = self.movedir;
			float _akimbo_active = akimbo_active(self.owner);
			self.movedir = weapon_shotorg_adjust(v0, FALSE, FALSE, _akimbo_active);
			self.shotorg_visual = weapon_shotorg_adjust(v0, FALSE, TRUE, _akimbo_active);
			self.view_ofs = weapon_shotorg_adjust(v0, FALSE, TRUE, _akimbo_active) - v0;
		}
		self.spawnorigin += self.view_ofs; // offset the casings origin by the same amount
		// check if an instant weapon switch occurred
		if (sv_qcweaponanimation) {
			if (self.state == WEAPON_STATE_READY) {
				self.angles = '0 0 0';
				makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
				setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
			}
		} else {
			setorigin(self, self.view_ofs);
			anim_set(self, self.anim_idle, TRUE, FALSE, TRUE);
		}
		// reset animstate now
		self.weapon_morph0time = 0;
		self.weapon_morph1time = 0;
		self.weapon_morph2time = 0;
		self.weapon_morph3time = 0;
		self.weapon_morph4time = 0;
	}
	self.effects = self.realowner.body.effects & (EFFECT_ADDITIVE | EFFECT_RED | EFFECT_BLUE);
	self.colormap = self.owner.colormap;
	self.alpha = player_alpha(self.owner, akimbo_owner(self.owner));
	if (self.owner.cvar_cl_gunalpha)
		self.alpha *= self.owner.cvar_cl_gunalpha;

	if (self.weaponentity) {
		self.weaponentity.effects = self.effects;
		self.weaponentity.alpha = self.alpha;
		self.weaponentity.colormap = self.colormap;
	}
	self.angles = '0 0 0';
	float f;
	f = 0;
	float useqcanimation = (sv_qcweaponanimation || self.wframe >= WEAPON_FRAME_MELEE);
	if (self.state == WEAPON_STATE_RAISE && !map_intermission_running && g_balance_weaponswitchdelay) {
		f = (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation) {
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	} else if (self.state == WEAPON_STATE_DROP && !map_intermission_running && g_balance_weaponswitchdelay) {
		f = 1 - (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation) {
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	} else if (self.state == WEAPON_STATE_CLEAR) {
		f = 1;
		self.angles_x = -90 * f * f;
		if (useqcanimation) {
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	} else if (useqcanimation && time < self.owner.weapon_morph1time) {
		f = (time - self.owner.weapon_morph0time) / (self.owner.weapon_morph1time - self.owner.weapon_morph0time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph0angles * (1 - f) + self.owner.weapon_morph1angles * f;
		setorigin(self, self.owner.weapon_morph0origin * (1 - f) + self.owner.weapon_morph1origin * f);
	} else if (useqcanimation && time < self.owner.weapon_morph2time) {
		f = (time - self.owner.weapon_morph1time) / (self.owner.weapon_morph2time - self.owner.weapon_morph1time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph1angles * (1 - f) + self.owner.weapon_morph2angles * f;
		setorigin(self, self.owner.weapon_morph1origin * (1 - f) + self.owner.weapon_morph2origin * f);
	} else if (useqcanimation && time < self.owner.weapon_morph3time) {
		f = (time - self.owner.weapon_morph2time) / (self.owner.weapon_morph3time - self.owner.weapon_morph2time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph2angles * (1 - f) + self.owner.weapon_morph3angles * f;
		setorigin(self, self.owner.weapon_morph2origin * (1 - f) + self.owner.weapon_morph3origin * f);
	} else if (useqcanimation && time < self.owner.weapon_morph4time) {
		f = (time - self.owner.weapon_morph3time) / (self.owner.weapon_morph4time - self.owner.weapon_morph3time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph3angles * (1 - f) + self.owner.weapon_morph4angles * f;
		setorigin(self, self.owner.weapon_morph3origin * (1 - f) + self.owner.weapon_morph4origin * f);
	} else if (useqcanimation) {
		// begin a new idle morph
		self.owner.weapon_morph0time   = time;
		self.owner.weapon_morph0angles = self.angles;
		self.owner.weapon_morph0origin = self.origin;
		float r;
		float t;
		r = random();
		if (r < 0.1) {
			// turn gun to the left to look at it
			t = 2;
			self.owner.weapon_morph1time   = time + t * 0.2;
			self.owner.weapon_morph1angles = randomvec() * 3 + '-5 30 0';
			makevectors(self.owner.weapon_morph1angles_x * '-1 0 0' + self.owner.weapon_morph1angles_y * '0 1 0' + self.owner.weapon_morph1angles_z * '0 0 1');
			self.owner.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph2time   = time + t * 0.6;
			self.owner.weapon_morph2angles = randomvec() * 3 + '-5 30 0';
			makevectors(self.owner.weapon_morph2angles_x * '-1 0 0' + self.owner.weapon_morph2angles_y * '0 1 0' + self.owner.weapon_morph2angles_z * '0 0 1');
			self.owner.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph3time   = time + t;
			self.owner.weapon_morph3angles = '0 0 0';
			makevectors(self.owner.weapon_morph3angles_x * '-1 0 0' + self.owner.weapon_morph3angles_y * '0 1 0' + self.owner.weapon_morph3angles_z * '0 0 1');
			self.owner.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self);
		} else if (r < 0.2) {
			// raise the gun a bit
			t = 2;
			self.owner.weapon_morph1time   = time + t * 0.2;
			self.owner.weapon_morph1angles = randomvec() * 3 + '30 -10 0';
			makevectors(self.owner.weapon_morph1angles_x * '-1 0 0' + self.owner.weapon_morph1angles_y * '0 1 0' + self.owner.weapon_morph1angles_z * '0 0 1');
			self.owner.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph2time   = time + t * 0.5;
			self.owner.weapon_morph2angles = randomvec() * 3 + '30 -10 5';
			makevectors(self.owner.weapon_morph2angles_x * '-1 0 0' + self.owner.weapon_morph2angles_y * '0 1 0' + self.owner.weapon_morph2angles_z * '0 0 1');
			self.owner.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph3time   = time + t;
			self.owner.weapon_morph3angles = '0 0 0';
			makevectors(self.owner.weapon_morph3angles_x * '-1 0 0' + self.owner.weapon_morph3angles_y * '0 1 0' + self.owner.weapon_morph3angles_z * '0 0 1');
			self.owner.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self);
		} else if (r < 0.3) {
			// tweak it a bit
			t = 5;
			self.owner.weapon_morph1time   = time + t * 0.3;
			self.owner.weapon_morph1angles = randomvec() * 6;
			makevectors(self.owner.weapon_morph1angles_x * '-1 0 0' + self.owner.weapon_morph1angles_y * '0 1 0' + self.owner.weapon_morph1angles_z * '0 0 1');
			self.owner.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self);

			self.owner.weapon_morph2time   = time + t * 0.7;
			self.owner.weapon_morph2angles = randomvec() * 6;
			makevectors(self.owner.weapon_morph2angles_x * '-1 0 0' + self.owner.weapon_morph2angles_y * '0 1 0' + self.owner.weapon_morph2angles_z * '0 0 1');
			self.owner.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self);

			self.owner.weapon_morph3time   = time + t;
			self.owner.weapon_morph3angles = '0 0 0';
			makevectors(self.owner.weapon_morph3angles_x * '-1 0 0' + self.owner.weapon_morph3angles_y * '0 1 0' + self.owner.weapon_morph3angles_z * '0 0 1');
			self.owner.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self);
		} else {
			// hold it mostly steady
			t = random() * 6 + 4;
			self.owner.weapon_morph1time   = time + t * 0.2;
			self.owner.weapon_morph1angles = randomvec() * 1;
			makevectors(self.owner.weapon_morph1angles_x * '-1 0 0' + self.owner.weapon_morph1angles_y * '0 1 0' + self.owner.weapon_morph1angles_z * '0 0 1');
			self.owner.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph2time   = time + t * 0.5;
			self.owner.weapon_morph2angles = randomvec() * 1;
			makevectors(self.owner.weapon_morph2angles_x * '-1 0 0' + self.owner.weapon_morph2angles_y * '0 1 0' + self.owner.weapon_morph2angles_z * '0 0 1');
			self.owner.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self);
			self.owner.weapon_morph3time   = time + t * 0.7;
			self.owner.weapon_morph3angles = randomvec() * 1;
			makevectors(self.owner.weapon_morph3angles_x * '-1 0 0' + self.owner.weapon_morph3angles_y * '0 1 0' + self.owner.weapon_morph3angles_z * '0 0 1');
			self.owner.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self);
		}
		self.owner.weapon_morph4time   = time + t;
		self.owner.weapon_morph4angles = '0 0 0';
		makevectors(self.owner.weapon_morph4angles_x * '-1 0 0' + self.owner.weapon_morph4angles_y * '0 1 0' + self.owner.weapon_morph4angles_z * '0 0 1');
		self.owner.weapon_morph4origin = QCWEAPONANIMATION_ORIGIN(self);
	}
}

void(entity w, entity p, float a) weapon_model_attach_to_player {
	entity b = (p.body.weaponentity ? p.body.weaponentity : p.body);
	if (gettagindex(b, "tag_weapon")) {
		setattachment(w, b, "tag_weapon");
		if (a)
			setorigin(w, '0 20 0');
	} else if (a == 2 && p.akimbo_use_left_hand != '0 0 0') {
		if (a) {
			float t;
			if ((t = gettagindex(b, "bip01 l hand")))
				setattachment(w, b, "bip01 l hand");
			else if ((t = gettagindex(b, "hand_L")))
				setattachment(w, b, "hand_L");
		}
		w.angles = p.akimbo_use_left_hand;
	} else {
		setattachment(w, b, "bip01 r hand");
		if (a) {
			if (a == 2)
				setorigin(w, '0 20 0');
			else
				setorigin(w, '0 10 0');
		}
	}
}

void(void) weapon_model_exterior_dlc_reset {
	if (self.owner.weaponname != "")
		setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
	else
		self.model = "";

	entity ao = akimbo_owner(self.owner);
	float akimbo_weapon = akimbo_active(self.owner);
	if (akimbo_weapon < 2) akimbo_weapon = 0;
	self.angles = '0 0 0';
	weapon_model_attach_to_player(self, ao, akimbo_weapon);
	self.oldorigin = self.angles;
	// if that didn't find a tag, hide the exterior weapon model
	if (!self.tag_index)
		self.model = "";
}

void(void) weapon_model_exterior_think {
	self.nextthink = time;
	if (self.owner.exteriorweaponentity != self) {
		remove(self);
		return;
	}
	if (PLAYER_REALLY_DEAD(self.owner)) {
		self.model = "";
		return;
	}
	if (self.cnt != self.owner.weapon || self.dmg != self.owner.body.modelindex_lod0 || self.deadflag != self.owner.deadflag) {
		self.cnt = self.owner.weapon;
		self.dmg = self.owner.body.modelindex_lod0;
		self.deadflag = self.owner.deadflag;
		self.dlc_reset = weapon_model_exterior_dlc_reset;
		self.dlc_reset();
	}
	self.effects = self.realowner.body.effects & (EFFECT_ADDITIVE | EFFECT_RED | EFFECT_BLUE | EFFECT_LOWPRECISION | EFFECT_FULLBRIGHT);
	self.colormap = self.owner.colormap;
	entity wi = self.owner.weaponentity;
	entity o = self.owner;
	if (wi.wframe == WEAPON_FRAME_MELEE || (o.weapon == WEAPON_MELEE && wi.frame == WEAPON_FRAME_FIRE2)) {
		entity ao = akimbo_owner(o);
		if (ao.anim_melee == ao.anim_shoot) {
			float f;
			if (time < o.weapon_morph1time)
				f = (time - o.weapon_morph0time) / (o.weapon_morph1time - o.weapon_morph0time);
			else
				f = 1 - (time - o.weapon_morph1time) / (o.weapon_morph2time - o.weapon_morph1time);

			f = bound(0, f, 1);
			self.angles = sv_qcanimation_melee_exterior * f;
		}
	} else
		self.angles = self.oldorigin;
}

// spawning weaponentity for client
void(void) weapon_model_spawn {
	self.weaponentity = spawn();
	self.weaponentity.classname = "weaponentity";
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.realowner = akimbo_owner(self);
	setmodel(self.weaponentity, ""); // precision set when changed
	setorigin(self.weaponentity, '0 0 0');
	self.weaponentity.angles = '0 0 0';
	self.weaponentity.viewmodelforclient = akimbo_owner(self);
	self.weaponentity.flags = 0;
	self.weaponentity.think = weapon_model_think;
	self.weaponentity.customizeentityforclient = weapon_model_customize;
	self.weaponentity.nextthink = time;
	self.exteriorweaponentity = spawn();
	self.exteriorweaponentity.classname = "exteriorweaponentity";
	self.exteriorweaponentity.solid = SOLID_NOT;
	self.exteriorweaponentity.exteriorweaponentity = self.exteriorweaponentity;
	self.exteriorweaponentity.owner = self;
	self.exteriorweaponentity.realowner = akimbo_owner(self);
	setorigin(self.exteriorweaponentity, '0 0 0');
	self.exteriorweaponentity.angles = '0 0 0';
	self.exteriorweaponentity.think = weapon_model_exterior_think;
	self.exteriorweaponentity.customizeentityforclient = weapon_model_exterior_customize;
	self.exteriorweaponentity.nextthink = time;
}

