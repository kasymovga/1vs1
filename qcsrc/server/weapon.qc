#define QCWEAPONANIMATION_ORIGIN(e) (sv_qcweaponanimation ?  ((weapon_offset_x + e.view_ofs_x) * v_forward - (weapon_offset_y + e.view_ofs_y) * v_right + (weapon_offset_z + e.view_ofs_z) * v_up + weapon_adjust) : e.view_ofs)

float g_balance_weaponswitchdelay;
float g_projectiles_newton_style;
float g_projectiles_newton_style_2_maxfactor;
float g_projectiles_newton_style_2_minfactor;
float g_weaponratefactor;
float g_weapon_throw_mode;
vector sv_qcanimation_melee_morph1angles;
vector sv_qcanimation_melee_morph2angles;
vector sv_qcanimation_melee_morph1origin;
vector sv_qcanimation_melee_morph2origin;
vector sv_qcanimation_melee2_morph1angles;
vector sv_qcanimation_melee2_morph2angles;
vector sv_qcanimation_melee2_morph1origin;
vector sv_qcanimation_melee2_morph2origin;
vector sv_qcanimation_melee_exterior;
float sv_qcweaponanimation;
float g_shootfromcenter;
float g_shootfromeye;
float g_norecoil;

vector weapon_offset = '0 -10 0';
vector weapon_adjust = '10 0 -15';

.vector weapon_morph0origin;
.vector weapon_morph0angles;
.float  weapon_morph0time;
.vector weapon_morph1origin;
.vector weapon_morph1angles;
.float  weapon_morph1time;
.vector weapon_morph2origin;
.vector weapon_morph2angles;
.float  weapon_morph2time;
.vector weapon_morph3origin;
.vector weapon_morph3angles;
.float  weapon_morph3time;
.vector weapon_morph4origin;
.vector weapon_morph4angles;
.float  weapon_morph4time;

float(entity e, string s) weapon_gettagindex {
	float t = gettagindex(e, s);
	if not(t)
		t = gettagindex(e, strcat("tag_", s));

	return t;
}

void(entity e1, entity e2, string s) weapon_setattachment {
	setattachment(e1, e2, s);
	if not(e1.tag_index)
		setattachment(e1, e2, strcat("tag_", s));
}

void(void) weapon_reload {
	if not(gamehook_ReloadAllowed())
		return;

	if (self.switchweapon == self.weapon)
	if (self.weaponentity.state == WS_READY) {
		weapon_action(self.weapon, WR_RELOAD);
		if (weapon_melee_possible())
			weapon_melee_attack_check();
	}
	akimbo_reload(self);
}

void(entity pl) weapon_show_list {
	if (clienttype(pl) == CLIENTTYPE_REAL) {
		msg_entity = pl;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_WEAPONLIST);
	}
}

void(entity e, float w) weapon_switch_force {
	weapon_show_list(self);
	e.cnt = e.switchweapon;
	e.switchweapon = w;
}

// switch between weapons
void(float imp) weapon_switch {
	if (self.switchweapon != imp) {
		if (player_hasweapon(self, imp, TRUE, TRUE))
			weapon_switch_force(self, imp);
		else
			weapon_show_list(self);
	}
};

.float weaponcomplainindex;
float(entity pl, string weaponorder, float dir, float imp, float complain) weaypon_cycle_get {
	float n, i, weaponwant, first_valid, prev_valid, switchtonext, switchtolast, c;
	float wbit;
	n = tokenize_console(weaponorder);
	switchtonext = switchtolast = 0;
	first_valid = prev_valid = 0;
	if (dir == 0)
		switchtonext = 1;

	c = 0;
	for (i = 0; i < n; ++i) {
		weaponwant = stof(argv(i));
		if (imp >= 0)
			if ((weapon_info(weaponwant)).impulse != imp)
				continue;

		wbit = weapon_bit(weaponwant);
		if not(wbit & weapon_spawned_list)
		if not(pl.weapons & wbit)
			continue;

		++c;
		if (player_hasweapon(pl, weaponwant, TRUE, FALSE)) {
			if (switchtonext)
				return weaponwant;

			if (!first_valid)
				first_valid = weaponwant;

			if (weaponwant == pl.switchweapon) {
				if (dir >= 0)
					switchtonext = 1;
				else if (prev_valid)
					return prev_valid;
				else
					switchtolast = 1;
			}
			prev_valid = weaponwant;
		}
	}
	if (first_valid) {
		if (switchtolast)
			return prev_valid;
		else
			return first_valid;
	}
	// complain (but only for one weapon on the button that has been pressed)
	if (complain) {
		weapon_show_list(pl);
		self.weaponcomplainindex += 1;
		if (c)
			c = math_mod(self.weaponcomplainindex, c) + 1;

		for (i = 0; i < n; ++i) {
			weaponwant = stof(argv(i));
			if (imp >= 0) {
				if ((weapon_info(weaponwant)).impulse != imp)
					continue;
			}
			wbit = weapon_bit(weaponwant);
			if (c > 0)
			if not(wbit & weapon_spawned_list)
			if not(pl.weapons & wbit)
				continue;

			--c;
			if (c <= 0) {
				player_hasweapon(pl, weaponwant, TRUE, TRUE);
				break;
			}
		}
	}
	return 0;
}

void(string weaponorder, float dir) weapon_cycle {
	float w;
	w = weaypon_cycle_get(self, weaponorder, dir, -1, 1);
	if (w > 0)
		weapon_switch(w);
}

void(float imp) weapon_next_on_impulse {
	float w;
	w = weaypon_cycle_get(self, self.cvar_cl_weaponpriority, +1, imp, 1);
	if (w > 0)
		weapon_switch(w);
}

// next weapon
void(float list) weapon_next {
	if (list == 0)
		weapon_cycle(weaponpriority_hudselector_0, -1);
	else if (list == 1)
		weapon_cycle(weaponpriority_hudselector_1, -1);
	else if (list == 2)
		weapon_cycle(self.cvar_cl_weaponpriority, -1);
}

// prev weapon
void(float list) weapon_previous {
	if (list == 0)
		weapon_cycle(weaponpriority_hudselector_0, +1);
	else if (list == 1)
		weapon_cycle(weaponpriority_hudselector_1, +1);
	else if ( list == 2)
		weapon_cycle(self.cvar_cl_weaponpriority, +1);
}

string weapon_fix_order_allow_incomplete(string order) {
	return weapon_fix_order(order, 0);
}

string weapon_fix_order_force_complete(string order) {
	if (order == "")
		order = cvar_string("cl_weaponpriority");

	return weapon_fix_order(order, 1);
}

float(entity e) weapon_best {
	return weaypon_cycle_get(e, e.cvar_cl_weaponpriority, 0, -1, 0);
}

// generic weapons table
// TODO should they be macros instead?
float(float wpn, float wrequest) weapon_action {
	return (weapon_info(wpn)).weapon_func(wrequest);
}

string(float weaponid) weapon_name {
	return (weapon_info(weaponid)).message;
}

float(float wpn) weapon_bit {
	return (weapon_info(wpn)).weapons;
}

float(float wpn) weapon_ammo_item_code {
	return (weapon_info(wpn)).items;
}

void(void) weapon_thrown_think {
	self.solid = SOLID_TRIGGER;
	self.owner = world;
	entity_fade_setup(self, time + 20, 1);
}

// returns amount of ammo used as string, or -1 for failure, or 0 for no ammo count
string(entity own, float wpn, float doreduce, vector org, vector velo) weapon_throw_new {
	entity oldself, wep;
	float wa, thisammo, i;
	string s;
	var .float ammofield;
	wep = spawn();
	setorigin(wep, org);
	wep.classname = "droppedweapon";
	wep.velocity = velo;
	wep.owner = wep.enemy = own;
	wep.flags |= FL_TOSSED;
	wep.colormap = own.colormap;
	wa = weapon_ammo_item_code(wpn);
	if (wa == IT_SUPERWEAPON || wa == 0) {
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if (item_start_failed)
			return NULL;

		wep.think = weapon_thrown_think;
		wep.nextthink = time + 0.5;
		return "";
	} else {
		s = "";
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if (item_start_failed)
			return NULL;

		if (doreduce || g_weapon_throw_mode) {
			ammofield = item_counter_field(wa);
			thisammo = min(own.ammofield, wep.ammofield);
			if (thisammo <= 0)
				thisammo = own.ammofield;

			wep.ammofield = thisammo;
			own.ammofield -= thisammo;
			s = strcat(s, " and ", ftos(thisammo), " ", item_counter_field_name(wa));
			s = substring(s, 5, -1);
		}
		wep.think = weapon_thrown_think;
		wep.nextthink = time + 0.5;
		return s;
	}
}

float(float w) weapon_throwable {
	float wb, wa;
	wb = weapon_bit(w);
	if (!wb)
		return 0;

	wa = weapon_ammo_item_code(w);
	if (player_start_weapons & wb) {
		if (wa == IT_SUPERWEAPON && (player_start_items & IT_UNLIMITED_SUPERWEAPONS))
			return 0;

		if (wa != IT_SUPERWEAPON && (player_start_items & IT_UNLIMITED_WEAPON_AMMO))
			return 0;

		// start weapons that take no ammo can't be dropped (this prevents dropping the laser, as long as it continues to use no ammo)
		if (wa == 0)
			return 0;
	}
	return 1;
}

// toss current weapon
void(vector velo, vector delta, float doreduce) weapon_throw {
	float w, wb;
	string a;
	w = self.weapon;
	if (w == 0)
		return; // just in case

	if not(gamehook_chain_ThrowWeaponAllowed(doreduce))
		return;

	if (g_pickup_nodrop)
		return;

	if (doreduce && g_weapon_stay == 1) //prevent ammo multiplication
		return;

	wb = weapon_bit(w);
	float akimbo_throw = akimbo_weapon_throw(wb);
	if not(akimbo_throw) {
		if not(g_pickup_items)
			return;

		if not(g_pickup_weapons)
			return;

		if (!weapon_throwable(w))
			return;
	}
	if not(self.weapons & wb)
		return;

	if not(akimbo_throw) {
		self.weapons &= ~wb;
		weapon_switch_force(self, weapon_best(self));
	}
	a = weapon_throw_new(self, w, doreduce, self.origin + delta, velo);
	if not(a)
		return;

	if (self.health >= 1) {
		if (a == "")
			sprint(self, strcat("You dropped the ^2", weapon_name(w), "\n"));
		else
			sprint(self, strcat("You dropped the ^2", weapon_name(w), " with ", a, "\n"));
	}
}

// Bringed back weapon frame
void(void) weapon_frame {
	vector fo, ri, up;
	self.ammoclip = 0;
	makevectors(self.v_angle);
	if (gamehook_chain_weapon_frame_handle())
		return;

	if (!self.weaponentity || self.health < 1)
		return; // Dead player can't use weapons and injure impulse commands

	float _switchweapon = gamehook_chain_weapon_frame_switch_mod(self.switchweapon);
	if (!_switchweapon) {
		self.items &= ~IT_AMMO;
		self.weaponname = "";
	}
	fo = v_forward; // save them in case the weapon think functions change it
	ri = v_right;
	up = v_up;
	// Change weapon
	if (self.weapon != _switchweapon) {
		if (!g_balance_weaponswitchdelay) {
			float aw = akimbo_active(self);
			if (aw > 1)
			if not(akimbo_weapon_have(self, _switchweapon, aw))
				return;
			weapon_action(self.weapon, WR_CLEAR);
			weapon_action(_switchweapon, WR_SETUP);
			weapon_thinkf(WFRAME_IDLE, 0, weapon_ready);
		} else if (self.weaponentity.state == WS_CLEAR) {
			player_anim_set(self, anim_draw, FALSE, TRUE, TRUE);
			self.weaponentity.state = WS_RAISE;
			weapon_action(self.weapon, WR_CLEAR);
			weapon_action(_switchweapon, WR_SETUP);
			// VorteX: add player model weapon select frame here
			// setcustomframe(PlayerWeaponRaise);
			weapon_thinkf(WFRAME_IDLE, g_balance_weaponswitchdelay, weapon_ready);
		} else if (self.weaponentity.state == WS_READY) {
			weapon_action(self.weapon, WR_CLEAR);
			// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
			sound (self, CHAN_WEAPON2, "weapons/weapon_switch.wav", VOL_BASE, ATTN_NORM);
			self.weaponentity.state = WS_DROP;
			// set up weapon switch think in the future, and start drop anim
			weapon_thinkf(WFRAME_DONTCHANGE, g_balance_weaponswitchdelay, weapon_clear);
		}
	}
	float wb;
	wb = weapon_bit(self.weapon);
	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	float c;
	c = 0;
	while (c < 5) {
		c = c + 1;
		if (wb && ((self.weapons & wb) == 0)) {
			weapon_switch_force(self, weapon_best(self));
			wb = 0;
		}
		if (wb) {
			v_forward = fo;
			v_right = ri;
			v_up = up;
			weapon_action(self.weapon, WR_THINK);
			if (self.spawnshieldtime > time)
			if (self.weaponentity.state == WS_INUSE) {
				self.spawnshieldtime = time; //weapon was used, disable spawnshield
			}
		}
		if (time + frametime * 0.5 >= self.weapon_nextthink) {
			if (self.weapon_think) {
				v_forward = fo;
				v_right = ri;
				v_up = up;
				self.weapon_think();
			}
		}
	}
}

void(float wpn) weapon_precache {
	entity e = weapon_info(wpn);
	item_precache(e.model, e.lodmodel1, "weapons/weaponpickup.wav");
	precache_model(strcat("models/weapons/v_", e.mdl, ".md3"));
	precache_model(strcat("models/weapons/h_", e.mdl, ".dpm"));
	e.weapon_func(WR_PRECACHE);
}

float internalteam;
void(float wpn) weapon_defaultspawnfunc {
	entity e;
	float t;
	var .float ammofield;
	string s;
	entity oldself;
	float i, j;
	var void() item_spawnfunc;
	if (self.classname != "droppedweapon" && self.classname != "replacedweapon") {
		e = weapon_info(wpn);
		s = cvar_string(strcat("g_weaponreplace_", e.netname));
		if (s == "0") {
			remove(self);
			item_start_failed = TRUE;
			return;
		}
		t = tokenize_console(s);
		if (t >= 2) {
			self.team = --internalteam;
			oldself = self;
			for (i = 1; i < t; ++i) {
				s = argv(i);
				e = weapon_info_by_name(s);
				if (e) {
					self = spawn();
					copyentity(oldself, self);
					self.classname = "replacedweapon";
					weapon_defaultspawnfunc(e.weapon);
					break;
				} else {
					item_spawnfunc = item_spawnfunc_for(s);
					if (item_spawnfunc) {
						self = spawn();
						item_spawnfunc();
					} else
						print("The weapon replace list for ", oldself.classname, " contains an unknown weapon ", s, ". Skipped.\n");
				}
			}
			self = oldself;
		}
		if (t >= 1) {
			s = argv(0);
			wpn = 0;
			e = weapon_info_by_name(s);
			if (e) {
				wpn = e.weapon;
			} else {
				item_spawnfunc = item_spawnfunc_for(s);
				if (item_spawnfunc) {
					item_spawnfunc();
					return;
				}
				print("The weapon replace list for ", self.classname, " contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		if (wpn == 0) {
			remove(self);
			item_start_failed = TRUE;
			return;
		}
	}
	if not(g_pickup_weapons) {
		remove(self);
		return;
	}
	if (gamehook_chain_WeaponSpawnHandle(wpn))
		return;

	// set the respawntime in advance (so replaced weapons can copy it)
	if (!self.respawntime) {
		e = weapon_info(wpn);
		if (e.items == IT_SUPERWEAPON) {
			self.respawntime = g_pickup_respawntime_powerup;
			self.respawntimejitter = g_pickup_respawntimejitter_powerup;
		} else {
			self.respawntime = g_pickup_respawntime_weapon;
			self.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}
	e = weapon_info(wpn);
	if (e.items && e.items != IT_SUPERWEAPON) {
		for (i = 0, j = 1; i < 24; ++i, j *= 2) {
			if (e.items & j) {
				ammofield = item_counter_field(j);
				if (!self.ammofield)
					self.ammofield = cvar(strcat("g_pickup_", item_counter_field_name(j)));
			}
		}
	} else {
		self.flags |= FL_NO_WEAPON_STAY;
	}
	// weapon stay isn't supported for teamed weapons
	if (self.team)
		self.flags |= FL_NO_WEAPON_STAY;

	item_start(e.model, e.lodmodel1, "weapons/weaponpickup.wav", self.respawntime, self.respawntimejitter, e.message, 0, e.weapons, FL_WEAPON, weapon_pickupevalfunc, e.bot_pickupbasevalue);
	if not(item_start_failed)
	if (self.classname != "droppedweapon") {
		weapon_precache(e.weapon);
		self.enemy = weapon_spawn_chain;
		weapon_spawn_chain = self;
	}
}

// Setup weapon for client (after this raise frame will be launched)
void(float windex) weapon_setup {
	entity e;
	e = weapon_info(windex);
	self.items &= ~IT_AMMO;
	self.items = self.items | e.items;
	// the two weapon entities will notice this has changed and update their models
	self.weapon = windex;
	self.weaponname = e.mdl;
	self.bulletcounter = 0;
}

// perform weapon to attack (weaponstate and attack_finished check is here)
float(float secondary, float attacktime) weapon_prepareattack {
	if (!gamehook_chain_WeaponPrepareAttack(secondary, attacktime)) {
		return FALSE;
	}
	if (attacktime >= 0) {
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(self) > time + frametime * 0.5)
			return FALSE;
		// don't fire while changing weapon
		if (self.weaponentity.state != WS_READY)
			return FALSE;
	}
	// do not even think about shooting if switching
	if (self.switchweapon != self.weapon)
		return FALSE;

	if not(player_can_fire(self, TRUE))
		return FALSE;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (!weapon_action(self.weapon, WR_CHECKAMMO1 + secondary)) {
		if (akimbo_active(self) < 2)
			weapon_switch_force(self, weapon_best(self));
		return FALSE;
	}
	self.weaponentity.state = WS_INUSE;
	// if the weapon hasn't been firing continuously, reset the timer
	if (attacktime >= 0) {
		if (ATTACK_FINISHED(self) < time - frametime * 1.5) {
			ATTACK_FINISHED(self) = time;
			//dprint("resetting attack finished to ", ftos(time), "\n");
		}
		ATTACK_FINISHED(self) = ATTACK_FINISHED(self) + attacktime * weapon_rate_factor();
	}
	self.bulletcounter += 1;
	//dprint("attack finished ", ftos(ATTACK_FINISHED(self)), "\n");
	return TRUE;
}

float(void) weapon_rate_factor {
	float t;
	entity oldself = self;
	self = akimbo_owner(self);
	t = (1.0 / g_weaponratefactor) * gamehook_chain_weapon_rate_factor();
	self = oldself;
	return t;
}

float(entity o) weapon_rate_factor_for {
	entity oldself = self;
	self = o;
	float f = weapon_rate_factor();
	self = oldself;
	return f;
}

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

void(void) weapon_model_dlc_reset {
	setattachment(self.weaponentity, self, "weapon");
}

void(void) weapon_model_think {
	float v_shot_idx;
	self.nextthink = time;
	if (map_intermission_running)
		self.frame = self.anim_idle_x;

	if (self.owner.weaponentity != self) {
		if (self.weaponentity)
			remove(self.weaponentity);

		remove(self);
		return;
	}
	if (PLAYER_REALLY_DEAD(self.owner)) {
		self.model = "";
		if (self.weaponentity)
			self.weaponentity.model = "";

		return;
	}
	if (self.cnt != self.owner.weapon || self.deadflag != self.owner.deadflag) {
		self.cnt = self.owner.weapon;
		self.deadflag = self.owner.deadflag;
		if (self.owner.weaponname != "") {
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

					self.weaponentity = world;
				}
				setorigin(self,'0 0 0');
				self.angles = '0 0 0';
				self.frame = 0;
				self.viewmodelforclient = world;
				float idx;
				idx = weapon_gettagindex(self, "shot");
				if (idx) {
					self.movedir = gettaginfo(self, idx);
				} else {
					print("WARNING: weapon model ", self.model, " does not support the 'shot' tag, will display shots TOTALLY wrong\n");
					self.movedir = '0 0 0';
				}
				idx = weapon_gettagindex(self, "shell");
				if (idx) {
					self.spawnorigin = gettaginfo(self, idx);
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
			if (self.weaponentity)
				remove(self.weaponentity);

			self.weaponentity = world;
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
			if (self.state == WS_READY) {
				self.angles = '0 0 0';
				makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
				setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
			}
		} else
			setorigin(self, self.view_ofs);

		// reset animstate now
		self.weapon_morph0time = 0;
		self.weapon_morph1time = 0;
		self.weapon_morph2time = 0;
		self.weapon_morph3time = 0;
		self.weapon_morph4time = 0;
		anim_set(self, self.anim_idle, TRUE, FALSE, TRUE);
	}
	self.effects = self.realowner.body.effects & (EFFECT_ADDITIVE | EFFECT_RED | EFFECT_BLUE);
	self.colormap = self.owner.colormap;
	self.alpha = player_alpha(self.owner, self.owner);
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
	float useqcanimation = (sv_qcweaponanimation || self.wframe >= WFRAME_MELEE);
	if (self.state == WS_RAISE && !map_intermission_running && g_balance_weaponswitchdelay) {
		f = (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation) {
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	} else if (self.state == WS_DROP && !map_intermission_running && g_balance_weaponswitchdelay) {
		f = 1 - (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation) {
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	} else if (self.state == WS_CLEAR) {
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

void(void) weapon_model_exterior_dlc_reset {
	float tag_found;
	if (self.owner.weaponname != "")
		setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
	else
		self.model = "";

	entity ao = akimbo_owner(self.owner);
	float akimbo_weapon = akimbo_active(self.owner);
	if (akimbo_weapon < 2) akimbo_weapon = 0;
	self.angles = '0 0 0';
	if ((tag_found = gettagindex(ao.body, "tag_weapon"))) {
		self.tag_index = tag_found;
		self.tag_entity = ao;
		if (akimbo_weapon)
			setorigin(self, '0 20 0');
	} else if (akimbo_weapon == 2 && ao.akimbo_use_left_hand != '0 0 0') {
		if (akimbo_weapon)
			setattachment(self, ao.body, "bip01 l hand");

		self.angles = ao.akimbo_use_left_hand;
	} else {
		setattachment(self, ao.body, "bip01 r hand");
		if (akimbo_weapon) {
			if (akimbo_weapon == 2)
				setorigin(self, '0 20 0');
			else
				setorigin(self, '0 10 0');
		}
	}
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
	entity we = self.owner.weaponentity;
	entity o = self.owner;
	if (we.wframe == WFRAME_MELEE || (o.weapon == WEP_MELEE && (we.frame == WFRAME_FIRE1 || we.frame == WFRAME_FIRE2))) {
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

void(float fr, float t, void() func) weapon_thinkf {
	vector a = '0 0 0';
	vector of, or, ou;
	float restartanim;
	if (fr == WFRAME_DONTCHANGE) {
		fr = self.weaponentity.wframe;
		restartanim = FALSE;
	} else if (fr == WFRAME_IDLE)
		restartanim = FALSE;
	else
		restartanim = TRUE;

	of = v_forward;
	or = v_right;
	ou = v_up;
	if (self.weaponentity) {
		self.weaponentity.wframe = fr;
		if (sv_qcweaponanimation || fr >= WFRAME_MELEE) {
			if (fr != WFRAME_IDLE) {
				self.weapon_morph0time = time;
				self.weapon_morph0angles = self.weaponentity.angles;
				self.weapon_morph0origin = self.weaponentity.origin;
				self.weapon_morph1angles = '0 0 0';
				self.weapon_morph1time = time + t;
				makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
				self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
				self.weapon_morph2angles = '0 0 0';
				self.weapon_morph2time = time + t;
				makevectors(self.weapon_morph2angles_x * '-1 0 0' + self.weapon_morph2angles_y * '0 1 0' + self.weapon_morph2angles_z * '0 0 1');
				self.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
				self.weapon_morph3angles = '0 0 0';
				self.weapon_morph3time = time + t;
				makevectors(self.weapon_morph3angles_x * '-1 0 0' + self.weapon_morph3angles_y * '0 1 0' + self.weapon_morph3angles_z * '0 0 1');
				self.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
				self.weapon_morph4angles = '0 0 0';
				self.weapon_morph4time = time + t;
				makevectors(self.weapon_morph4angles_x * '-1 0 0' + self.weapon_morph4angles_y * '0 1 0' + self.weapon_morph4angles_z * '0 0 1');
				self.weapon_morph4origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
				if (fr == WFRAME_FIRE1) {
					self.weapon_morph1angles = '5 0 0';
					self.weapon_morph1time = time + t * 0.1;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
					self.weapon_morph4time = time + t + 1; // delay idle effect
				} else if (fr == WFRAME_FIRE2) {
					self.weapon_morph1angles = '10 0 0';
					self.weapon_morph1time = time + t * 0.1;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
					self.weapon_morph4time = time + t + 1; // delay idle effect
				} else if (fr == WFRAME_RELOAD) {
					self.weapon_morph1time = time + t * 0.05;
					self.weapon_morph1angles = '-10 40 0';
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);

					self.weapon_morph2time = time + t * 0.15;
					self.weapon_morph2angles = '-10 40 5';
					makevectors(self.weapon_morph2angles_x * '-1 0 0' + self.weapon_morph2angles_y * '0 1 0' + self.weapon_morph2angles_z * '0 0 1');
					self.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);

					self.weapon_morph3time = time + t * 0.25;
					self.weapon_morph3angles = '-10 40 0';
					makevectors(self.weapon_morph3angles_x * '-1 0 0' + self.weapon_morph3angles_y * '0 1 0' + self.weapon_morph3angles_z * '0 0 1');
					self.weapon_morph3origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
				} else if (fr == WFRAME_MELEE) {
					self.weapon_morph1time = time + t * 0.25;
					self.weapon_morph1angles = sv_qcanimation_melee_morph1angles;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee_morph1origin;

					self.weapon_morph2time = time + t * 0.65;
					self.weapon_morph2angles = sv_qcanimation_melee_morph2angles;
					makevectors(self.weapon_morph2angles_x * '-1 0 0' + self.weapon_morph2angles_y * '0 1 0' + self.weapon_morph2angles_z * '0 0 1');
					self.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee_morph2origin;
				} else if (fr == WFRAME_MELEE2) {
					self.weapon_morph1time = time + t * 0.25;
					self.weapon_morph1angles = sv_qcanimation_melee2_morph1angles;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee2_morph1origin;
					self.weapon_morph2time = time + t * 0.65;
					self.weapon_morph2angles = sv_qcanimation_melee2_morph2angles;
					makevectors(self.weapon_morph2angles_x * '-1 0 0' + self.weapon_morph2angles_y * '0 1 0' + self.weapon_morph2angles_z * '0 0 1');
					self.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee2_morph2origin;
				}
			}
		} else {
			if (fr == WFRAME_IDLE)
				a = self.weaponentity.anim_idle;
			else if (fr == WFRAME_FIRE1)
				a = self.weaponentity.anim_fire1;
			else if (fr == WFRAME_FIRE2)
				a = self.weaponentity.anim_fire2;
			else if (fr == WFRAME_RELOAD)
				a = self.weaponentity.anim_reload;

			a_z *= g_weaponratefactor;
			anim_set(self.weaponentity, a, restartanim == FALSE, restartanim, restartanim);
		}
	}
	v_forward = of;
	v_right = or;
	v_up = ou;
	if (self.weapon_think == weapon_ready && func != weapon_ready && self.weaponentity.state == WS_RAISE) {
		backtrace("Tried to override initial weapon think function - should this really happen?");
	}
	t *= weapon_rate_factor();
	// VorteX: haste can be added here
	if (self.weapon_think == weapon_ready) {
		self.weapon_nextthink = time;
		//dprint("started firing at ", ftos(time), "\n");
	}
	if (self.weapon_nextthink < time - frametime * 1.5 || self.weapon_nextthink > time + frametime * 1.5) {
		self.weapon_nextthink = time;
		//dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	self.weapon_nextthink = self.weapon_nextthink + t;
	self.weapon_think = func;
	//dprint("next ", ftos(self.weapon_nextthink), "\n");
	if (restartanim)
	if (t)
	if (!self.crouch) { // shoot anim stands up, this looks bad
		if (fr == WFRAME_MELEE2)
			player_anim_set(self, anim_melee2, FALSE, TRUE, TRUE);
		else if (fr == WFRAME_MELEE || self.weapon == WEP_MELEE) {
			player_anim_set(self, anim_melee, FALSE, TRUE, TRUE);
			if (self.body)
				self.body.animstate_endtime = time + t;

			if (fr != WFRAME_MELEE) {
				self.weapon_morph0time = time;
				self.weapon_morph1time = time + t * 0.25;
				self.weapon_morph2time = time + t * 0.65;
			}
		} else
			player_anim_set(self, anim_shoot, FALSE, TRUE, TRUE);
	}
}

// Weapon subs
void(void) weapon_clear {
	if (self.weapon != -1)
		self.weapon = 0;

	if (self.weaponentity) {
		self.weaponentity.state = WS_CLEAR;
		self.weaponentity.effects = 0;
	}
}

void(void) weapon_ready {
	if (self.weaponentity)
		self.weaponentity.state = WS_READY;

	weapon_thinkf(WFRAME_IDLE, 1000000, weapon_ready);
}

// this function calculates weapon_shotorg and weapon_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put weapon_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
.float lastshot_time;
void(entity ent, vector s_forward, float recoil, string snd, float maxhits) weapon_setup_shotdir {
	vector vecs, vecs_visual, dv;
	entity ent_orig = ent;
	ent = akimbo_owner(ent);
	// Track max damage and set the stat to be sent later in g_world.qc
	if (maxhits > 0)
		damage_record_fires(ent, ent.weapon, maxhits);

	if (ent_orig.weaponentity.movedir_x > 0) {
		vecs = ent_orig.weaponentity.movedir;
		vecs_y = -vecs_y;
	} else
		vecs = '0 0 0';

	vecs_visual = ent_orig.weaponentity.shotorg_visual;
	vecs_visual_y = -vecs_visual_y;
	dv = v_right * vecs_y + v_up * vecs_z;
	weapon_shotorg = ent.origin + ent.view_ofs;
	weapon_shotorg_visual = weapon_shotorg + (v_right * vecs_visual_y + v_up * vecs_visual_z) + v_forward * 48;
	weapon_shotorg = weapon_shotorg + dv;
	// calculate the shotdir from the chosen shotorg
	if (akimbo_active(ent))
		weapon_shotdir = s_forward;
	else {
		float dphitcontentsmask_save = ent.dphitcontentsmask;
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
		warpzone_trace_line(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * WORLD_MAX_SHOT_DISTANCE, TRACE_MOVE_NOMONSTERS, ent);
		ent.dphitcontentsmask = dphitcontentsmask_save;
		weapon_shotpoint = warpzone_untransform_origin(warpzone_trace_transform, trace_endpos);
		weapon_shotdir = normalize(weapon_shotpoint - weapon_shotorg);
	}
	if (!g_norecoil)
		ent.punchangle_x = min(ent.punchangle_x, recoil * -1);

	if (ent.lastshot_time < time) {
		if (snd != "")
			sound (ent, CHAN_WEAPON, snd, VOL_BASE, ATTN_NORM);

		if (ent.items & IT_STRENGTH)
			sound (ent, CHAN_AUTO, "weapons/strength_fire.wav", VOL_BASE, ATTN_NORM);

		ent.lastshot_time = time;
	}
}

void(float r) weapon_shake {
	if not(g_norecoil)
		self.punchangle = self.punchangle + '1 0 0' * r * (random() - 0.5) + '0 1 0' * r * (random() - 0.5);
}

vector(vector pvelocity, vector mvelocity) weapon_calculate_projectile_velocity {
	vector mdirection;
	float mspeed;
	float outspeed;
	vector outvelocity = '0 0 0';
	mvelocity = mvelocity * g_weaponspeedfactor;
	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);
	if (g_projectiles_newton_style == 0) {
		// absolute velocity
		outvelocity = mvelocity;
	} else if (g_projectiles_newton_style == 1) {
		// true Newtonian projectiles
		outvelocity = pvelocity + mvelocity;
	} else if (g_projectiles_newton_style == 2) {
		// true Newtonian projectiles with automatic aim adjustment
		// solve: |outspeed * mdirection - pvelocity| = mspeed
		// outspeed^2 - 2 * outspeed * (mdirection * pvelocity) + pvelocity^2 - mspeed^2 = 0
		// outspeed = (mdirection * pvelocity) +- sqrt((mdirection * pvelocity)^2 - pvelocity^2 + mspeed^2)
		// PLUS SIGN!
		// not defined?
		// then...
		// pvelocity^2 - (mdirection * pvelocity)^2 > mspeed^2
		// velocity without mdirection component > mspeed
		// fire at smallest possible mspeed that works?
		// |(mdirection * pvelocity) * pvelocity - pvelocity| = mspeed
		vector solution;
		solution = math_solve_quadratic(1, -2 * (mdirection * pvelocity), pvelocity * pvelocity - mspeed * mspeed);
		if (solution_z)
			outspeed = solution_y; // the larger one
		else {
			//outspeed = 0; // slowest possible shot
			outspeed = solution_x; // the real part (that is, the average!)
			//dprint("impossible shot, adjusting\n");
		}
		outspeed = bound(mspeed * g_projectiles_newton_style_2_minfactor, outspeed, mspeed * g_projectiles_newton_style_2_maxfactor);
		outvelocity = mdirection * outspeed;
	} else if (g_projectiles_newton_style == 3) {
		// pseudo-Newtonian:
		outspeed = mspeed + mdirection * pvelocity;
		outspeed = bound(mspeed * 0.7, outspeed, mspeed * 5.0);
		outvelocity = mdirection * outspeed;
	} else if (g_projectiles_newton_style == 4) {
		// tZorkian:
		outspeed = mspeed + vlen(pvelocity);
		outvelocity = mdirection * outspeed;
	} else
		error("g_projectiles_newton_style must be 0 (absolute), 1 (Newtonian), 2 (Newtonian + aimfix), 3 (pseudo Newtonian) or 4 (tZorkian)!");

	return outvelocity;
}

vector(vector vecs, float y_is_right, float allowcenter) weapon_shotorg_adjustfromclient {
	switch(self.owner.cvar_cl_gunalign & 7) {
	case 1: // right
		break;
	case 2: // left
		vecs_y = -vecs_y;
		break;
	default:
	case 3:
		if (allowcenter) { // 2: allow center handedness
			// center
			vecs_y = 0;
			vecs_z -= 4;
		} else {
			// right
		}
		break;
	case 4:
		if (allowcenter) {// 2: allow center handedness
			// center
			vecs_y = 0;
			vecs_z -= 4;
		} else {
			// left
			vecs_y = -vecs_y;
		}
		break;
	}
	return vecs;
}

vector(vector vecs, float y_is_right, float visual, float _akimbo_active) weapon_shotorg_adjust {
	if (_akimbo_active) {
		if (_akimbo_active == 2)
			vecs_y = -vecs_y;
		else if (_akimbo_active == 3)
			vecs_y = 0;

		if not(visual) {
			if (g_shootfromeye)
				vecs_z = 0;
			else if (g_shootfromcenter)
				vecs_z -= 4;
		}
		vecs_y = vecs_y * 1.2;
		return vecs;
	}
	if (g_shootfromeye) {
		if (visual) {
			vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		} else {
			vecs_y = 0;
			vecs_z = 0;
		}
	} else if (g_shootfromcenter) {
		if (visual) {
			vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		} else {
			vecs_y = 0;
			vecs_z -= 4;
		}
	} else {
		if (visual)
			vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, self.owner.cvar_cl_gunalign & 8);
	}
	return vecs;
}

void(entity missile) weapon_setup_projectile_velocity {
	if (missile.owner == world)
		error("Unowned missile");

	missile.velocity = weapon_calculate_projectile_velocity(missile.owner.velocity, missile.velocity);
	if not(missile.gravity)
	if (missile.movetype == MOVETYPE_TOSS || missile.movetype == MOVETYPE_BOUNCE)
		missile.gravity = 1;
}

void(entity flash, vector offset) weapon_attach_to_shotorg {
	entity xflash;
	flash.owner = self;
	flash.angles_z = random() * 360;
	if (sv_qcweaponanimation) {
		setorigin(flash, weapon_shotorg + weapon_shotdir * 50);
		flash.angles = vectoangles(weapon_shotdir);
		flash.angles_z = random() * 360;
	} else {
		weapon_setattachment(flash, self.weaponentity, "shot");
		setorigin(flash, offset);
		xflash = spawn();
		copyentity(flash, xflash);
		flash.viewmodelforclient = akimbo_owner(self);
		if (self.weaponentity.oldorigin_x > 0) {
			setattachment(xflash, self.exteriorweaponentity, "");
			setorigin(xflash, self.weaponentity.oldorigin + offset);
		} else {
			weapon_setattachment(xflash, self.exteriorweaponentity, "shot");
		}
	}
}

void(entity e, float wep, string name) weapon_give {
	entity oldself;
	if (!wep)
		return;

	e.weapons = e.weapons | weapon_bit(wep);
	oldself = self;
	self = e;
	if (other.classname == "player") {
		weapon_show_list(other);
		sprint (other, "You got the ^2");
		sprint (other, name);
		sprint (other, "\n");
	}
	self = oldself;
}

void(void) weapon_init {
	float i;
	CVAR_CACHE(g_balance_weaponswitchdelay);
	CVAR_CACHE(g_projectiles_newton_style_2_minfactor);
	CVAR_CACHE(g_projectiles_newton_style_2_maxfactor);
	CVAR_CACHE(sv_qcweaponanimation);
	CVAR_CACHE(g_weaponspeedfactor);
	CVAR_CACHE(g_weaponratefactor);
	CVAR_CACHE(g_shootfromcenter);
	CVAR_CACHE(g_shootfromeye);
	CVAR_CACHE(g_projectiles_newton_style);
	CVAR_CACHE(g_norecoil);
	CVAR_CACHE(g_weapon_throw_mode);
	sv_qcanimation_melee_morph1angles = stov(cvar_string("sv_qcanimation_melee_morph1angles"));
	sv_qcanimation_melee_morph2angles = stov(cvar_string("sv_qcanimation_melee_morph2angles"));
	sv_qcanimation_melee_morph1origin = stov(cvar_string("sv_qcanimation_melee_morph1origin"));
	sv_qcanimation_melee_morph2origin = stov(cvar_string("sv_qcanimation_melee_morph2origin"));
	sv_qcanimation_melee2_morph1angles = stov(cvar_string("sv_qcanimation_melee2_morph1angles"));
	sv_qcanimation_melee2_morph2angles = stov(cvar_string("sv_qcanimation_melee2_morph2angles"));
	sv_qcanimation_melee2_morph1origin = stov(cvar_string("sv_qcanimation_melee2_morph1origin"));
	sv_qcanimation_melee2_morph2origin = stov(cvar_string("sv_qcanimation_melee2_morph2origin"));
	sv_qcanimation_melee_exterior = stov(cvar_string("sv_qcanimation_melee_exterior"));
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		(weapon_info(i)).weapon_func(WR_CVAR_CACHE);
	}
	weapon_melee_init();
	bullet_init();
	projectile_register_auto(PROJECTILE_BULLET, '0 0 0', MOVETYPE_TOSS);
	projectile_register_auto(PROJECTILE_BULLET_GLOWING, '0 0 0', MOVETYPE_TOSS);
	projectile_register_auto(PROJECTILE_BULLET_BIG, '0 0 0', MOVETYPE_FLY);
}

entity(string s) weapon_info_by_name {
	float i;
	entity e;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
		e = weapon_info(i);
		if (e.netname == s)
			return e;
	}
	return NULL;
}
