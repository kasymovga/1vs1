#define QCWEAPONANIMATION_ORIGIN(e) (sv_qcweaponanimation ?  ((weapon_offset_x + e.view_ofs_x) * v_forward - (weapon_offset_y + e.view_ofs_y) * v_right + (weapon_offset_z + e.view_ofs_z) * v_up + weapon_adjust) : e.view_ofs)

float g_balance_weaponswitchdelay;
float g_showweaponspawns;
float g_projectiles_newton_style_2_maxfactor;
float g_projectiles_newton_style_2_minfactor;
float g_weaponratefactor;
vector sv_qcanimation_melee_morph1angles;
vector sv_qcanimation_melee_morph2angles;
vector sv_qcanimation_melee_morph1origin;
vector sv_qcanimation_melee_morph2origin;
vector sv_qcanimation_melee2_morph1angles;
vector sv_qcanimation_melee2_morph2angles;
vector sv_qcanimation_melee2_morph1origin;
vector sv_qcanimation_melee2_morph2origin;
float sv_qcweaponanimation;
float g_akimbo_use_left_hand;
float g_shootfromcenter;
float g_shootfromclient;
float g_shootfromeye;

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

void weapon_reload() {
	if not(GameHook_ReloadAllowed())
		return;

	if(self.switchweapon == self.weapon)
	if(self.weaponentity.state == WS_READY)
	{
		if (W_Melee_Possible())
			W_Melee_Attack_Check();
		else
			weapon_action(self.weapon, WR_RELOAD);
	}
	entity oldself = self;
	self = Akimbo_Ghost(self);
	if (self)
	if (self != oldself)
		weapon_reload();
	self = oldself;
}

void weapon_show_list(entity pl) {
	if (clienttype(pl) == CLIENTTYPE_REAL) {
		msg_entity = pl;
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_WEAPONLIST);
	}
}

void(entity e, float w) weapon_switch_force {
	weapon_show_list(self);
	e.cnt = e.switchweapon;
	e.switchweapon = w;
}

// switch between weapons
void weapon_switch(float imp)
{
	if (self.switchweapon != imp) {
		if (player_hasweapon(self, imp, TRUE, TRUE))
			weapon_switch_force(self, imp);
		else
			weapon_show_list(self);
	}
};

.float weaponcomplainindex;
float weaypon_cycle_get(entity pl, string weaponorder, float dir, float imp, float complain)
{
	float n, i, weaponwant, first_valid, prev_valid, switchtonext, switchtolast, c;
	n = tokenize_console(weaponorder);
	switchtonext = switchtolast = 0;
	first_valid = prev_valid = 0;
	if(dir == 0)
		switchtonext = 1;

	c = 0;

	for(i = 0; i < n; ++i)
	{
		weaponwant = stof(argv(i));
		if(imp >= 0)
			if((get_weaponinfo(weaponwant)).impulse != imp)
				continue;

		++c;

		if(player_hasweapon(pl, weaponwant, TRUE, FALSE))
		{
			if(switchtonext)
				return weaponwant;
			if(!first_valid)
				first_valid = weaponwant;
			if(weaponwant == pl.switchweapon)
			{
				if(dir >= 0)
					switchtonext = 1;
				else if(prev_valid)
					return prev_valid;
				else
					switchtolast = 1;
			}
			prev_valid = weaponwant;
		} else
			weapon_show_list(pl);
	}
	if(first_valid)
	{
		if(switchtolast)
			return prev_valid;
		else
			return first_valid;
	}
	// complain (but only for one weapon on the button that has been pressed)
	if(complain)
	{
		self.weaponcomplainindex += 1;
		c = mod(self.weaponcomplainindex, c) + 1;
		for(i = 0; i < n; ++i)
		{
			weaponwant = stof(argv(i));
			if(imp >= 0)
				if((get_weaponinfo(weaponwant)).impulse != imp)
					continue;

			--c;
			if(c == 0)
			{
				player_hasweapon(pl, weaponwant, TRUE, TRUE);
				break;
			}
		}
	}
	return 0;
}

void weapon_cycle(string weaponorder, float dir)
{
	float w;
	w = weaypon_cycle_get(self, weaponorder, dir, -1, 1);
	if(w > 0)
		weapon_switch(w);
}

void weapon_next_on_impulse(float imp)
{
	float w;
	w = weaypon_cycle_get(self, self.cvar_cl_weaponpriority, +1, imp, 1);
	if(w > 0)
		weapon_switch(w);
}

// next weapon
void weapon_next(float list)
{
	if(list == 0)
		weapon_cycle(weaponpriority_hudselector_0, -1);
	else if(list == 1)
		weapon_cycle(weaponpriority_hudselector_1, -1);
	else if(list == 2)
		weapon_cycle(self.cvar_cl_weaponpriority, -1);
}

// prev weapon
void(float list) weapon_previous {
	if(list == 0)
		weapon_cycle(weaponpriority_hudselector_0, +1);
	else if(list == 1)
		weapon_cycle(weaponpriority_hudselector_1, +1);
	else if(list == 2)
		weapon_cycle(self.cvar_cl_weaponpriority, +1);
}

string weapon_fix_order_allow_incomplete(string order)
{
	return W_FixWeaponOrder(order, 0);
}

string weapon_fix_order_force_complete(string order)
{
	if(order == "")
		order = cvar_string("cl_weaponpriority");
	return W_FixWeaponOrder(order, 1);
}

float weapon_best(entity e)
{
	return weaypon_cycle_get(e, e.cvar_cl_weaponpriority, 0, -1, 0);
};

// generic weapons table
// TODO should they be macros instead?
float weapon_action(float wpn, float wrequest)
{
	return (get_weaponinfo(wpn)).weapon_func(wrequest);
};

string(float weaponid) weapon_name {
	return (get_weaponinfo(weaponid)).message;
}

float(float wpn) weapon_bit {
	return (get_weaponinfo(wpn)).weapons;
}

float weapon_ammo_item_code(float wpn)
{
	return (get_weaponinfo(wpn)).items;
}

void weapon_thrown_think()
{
	self.solid = SOLID_TRIGGER;
	self.owner = world;
	SUB_SetFade(self, time + 20, 1);
}

// returns amount of ammo used as string, or -1 for failure, or 0 for no ammo count
string weapon_throw_new(entity own, float wpn, float doreduce, vector org, vector velo)
{
	entity oldself, wep;
	float wa, thisammo, i, j;
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
	if(wa == IT_SUPERWEAPON || wa == 0)
	{
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if(item_start_failed)
			return string_null;
		wep.think = weapon_thrown_think;
		wep.nextthink = time + 0.5;
		return "";
	}
	else
	{
		s = "";
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if(item_start_failed)
			return string_null;
		if(doreduce)
		{
			for(i = 0, j = 1; i < 24; ++i, j *= 2)
			{
				if(wa & j)
				{
					ammofield = item_counter_field(j);
					thisammo = min(own.ammofield, wep.ammofield);
					wep.ammofield = thisammo;
					own.ammofield -= thisammo;
					s = strcat(s, " and ", ftos(thisammo), " ", item_counter_field_name(j));
				}
			}
			s = substring(s, 5, -1);
		}
		wep.think = weapon_thrown_think;
		wep.nextthink = time + 0.5;
		return s;
	}
}

float weapon_throwable(float w)
{
	float wb, wa;
	wb = weapon_bit(w);
	if(!wb)
		return 0;
	wa = weapon_ammo_item_code(w);
	if(start_weapons & wb)
	{
		if(wa == IT_SUPERWEAPON && start_items & IT_UNLIMITED_SUPERWEAPONS)
			return 0;
		if(wa != IT_SUPERWEAPON && start_items & IT_UNLIMITED_WEAPON_AMMO)
			return 0;
		// start weapons that take no ammo can't be dropped (this prevents dropping the laser, as long as it continues to use no ammo)
		if(wa == 0)
			return 0;
	}

	return 1;
}

// toss current weapon
void weapon_throw(vector velo, vector delta, float doreduce)
{
	local float w, wb;
	string a;

	w = self.weapon;
	if (w == 0)
		return; // just in case
	if not(GameHookChain_ThrowWeaponAllowed(doreduce))
		return;
	wb = weapon_bit(w);
	float akimbo_throw = Akimbo_Throw(wb);
	if not(akimbo_throw) {
		if not(g_pickup_items)
			return;
		if not(g_pickup_weapons)
			return;
		if(!weapon_throwable(w))
			return;
	}

	if(self.weapons & wb != wb)
		return;

	if not(akimbo_throw) {
		self.weapons &~= wb;
		weapon_switch_force(self, weapon_best(self));
	}
	a = weapon_throw_new(self, w, doreduce, self.origin + delta, velo);
	if not(a)
		return;
	if(self.health >= 1)
	{
		if(a == "")
			sprint(self, strcat("You dropped the ^2", weapon_name(w), "\n"));
		else
			sprint(self, strcat("You dropped the ^2", weapon_name(w), " with ", a, "\n"));
	}
};

// Bringed back weapon frame
void weapon_frame()
{
	vector fo, ri, up;

	makevectors(self.v_angle);
	if (GameHook_WeaponFrameHandle())
		return;
	if (!self.weaponentity || self.health < 1)
		return; // Dead player can't use weapons and injure impulse commands

	if(!self.switchweapon)
	{
		self.weapon = 0;
		self.weaponentity.state = WS_CLEAR;
		self.weaponname = "";
		self.items &~= IT_AMMO;
		return;
	}

	fo = v_forward; // save them in case the weapon think functions change it
	ri = v_right;
	up = v_up;

	// Change weapon
	if (self.weapon != self.switchweapon)
	{
		if (!g_balance_weaponswitchdelay)
		{
			if (Akimbo_Active(self) > 1)
			if not(Akimbo_HaveWeapon(self, self.switchweapon))
				return;
			weapon_action(self.weapon, WR_CLEAR);
			weapon_action(self.switchweapon, WR_SETUP);
			weapon_thinkf(WFRAME_IDLE, 0, weapon_ready);
		} else if (self.weaponentity.state == WS_CLEAR)
		{
			anim_set(self, self.anim_draw, FALSE, TRUE, TRUE);
			self.weaponentity.state = WS_RAISE;
			weapon_action(self.weapon, WR_CLEAR);
			weapon_action(self.switchweapon, WR_SETUP);
			// VorteX: add player model weapon select frame here
			// setcustomframe(PlayerWeaponRaise);
			weapon_thinkf(WFRAME_IDLE, g_balance_weaponswitchdelay, weapon_ready);
		}
		else if (self.weaponentity.state == WS_READY)
		{
#ifndef INDEPENDENT_ATTACK_FINISHED
			if(ATTACK_FINISHED(self) <= time + frametime * 0.5)
			{
#endif
			weapon_action(self.weapon, WR_CLEAR);
			// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
			sound (self, CHAN_WEAPON2, "weapons/weapon_switch.wav", VOL_BASE, ATTN_NORM);
			self.weaponentity.state = WS_DROP;
			// set up weapon switch think in the future, and start drop anim
			weapon_thinkf(WFRAME_DONTCHANGE, g_balance_weaponswitchdelay, weapon_clear);
#ifndef INDEPENDENT_ATTACK_FINISHED
			}
#endif
		}
	}

	float wb;
	wb = weapon_bit(self.weapon);

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	local float c;
	c = 0;
	while (c < 5)
	{
		c = c + 1;
		if(wb && ((self.weapons & wb) == 0))
		{
			weapon_switch_force(self, weapon_best(self));
			wb = 0;
		}
		if(wb)
		{
			v_forward = fo;
			v_right = ri;
			v_up = up;
			if (self.bot_melee)
				W_Melee_Attack_Check();
			else
				weapon_action(self.weapon, WR_THINK);
		}
		if (time + frametime * 0.5 >= self.weapon_nextthink)
		{
			if(self.weapon_think)
			{
				v_forward = fo;
				v_right = ri;
				v_up = up;
				self.weapon_think();
			}
			else
				bprint("\{1}^1ERROR: undefined weapon think function for ", self.netname, "\n");
		}
	}

	// don't let attack_finished fall behind when not firing (must be after weapon_setup calls!)
	//if (ATTACK_FINISHED(self) < time)
	//	ATTACK_FINISHED(self) = time;

	//if (self.weapon_nextthink < time)
	//	self.weapon_nextthink = time;

	// update currentammo incase it has changed
#if 0
	if (self.items & IT_CELLS)
		self.currentammo = self.ammo_cells;
	else if (self.items & IT_ROCKETS)
		self.currentammo = self.ammo_rockets;
	else if (self.items & IT_NAILS)
		self.currentammo = self.ammo_nails;
	else if (self.items & IT_SHELLS)
		self.currentammo = self.ammo_shells;
	else
		self.currentammo = 1;
#endif
}

void(float wpn) weapon_precache {
	string s = get_weaponinfo(wpn).mdl;
	precache_model(strcat("models/weapons/g_", s, ".md3"));
	precache_model(strcat("models/weapons/v_", s, ".md3"));
	precache_model(strcat("models/weapons/h_", s, ".dpm"));
	(get_weaponinfo(wpn)).weapon_func(WR_PRECACHE);
}

float internalteam;
void(float wpn) weapon_defaultspawnfunc {
	entity e;
	float t;
	var .float ammofield;
	string s;
	entity oldself;
	float i, j;
	if not(g_pickup_weapons) {
		remove(self);
		return;
	}
	if (GameHookChain_WeaponSpawnHandle(float wpn))
		return;

	// set the respawntime in advance (so replaced weapons can copy it)

	if(!self.respawntime)
	{
		e = get_weaponinfo(wpn);
		if(e.items == IT_SUPERWEAPON)
		{
			self.respawntime = g_pickup_respawntime_powerup;
			self.respawntimejitter = g_pickup_respawntimejitter_powerup;
		}
		else
		{
			self.respawntime = g_pickup_respawntime_weapon;
			self.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}

	if(self.classname != "droppedweapon" && self.classname != "replacedweapon")
	{
		e = get_weaponinfo(wpn);
		s = cvar_string(strcat("g_weaponreplace_", e.netname));
		if(s == "0")
		{
			remove(self);
			item_start_failed = TRUE;
			return;
		}
		t = tokenize_console(s);
		if(t >= 2)
		{
			self.team = --internalteam;
			oldself = self;
			for(i = 1; i < t; ++i)
			{
				s = argv(i);
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					e = get_weaponinfo(j);
					if(e.netname == s)
					{
						self = spawn();
						copyentity(oldself, self);
						self.classname = "replacedweapon";
						weapon_defaultspawnfunc(j);
						break;
					}
				}
				if(j > WEP_LAST)
				{
					print("The weapon replace list for ", oldself.classname, " contains an unknown weapon ", s, ". Skipped.\n");
				}
			}
			self = oldself;
		}
		if(t >= 1)
		{
			s = argv(0);
			wpn = 0;
			for(j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = get_weaponinfo(j);
				if(e.netname == s)
				{
					wpn = j;
					break;
				}
			}
			if(j > WEP_LAST)
			{
				print("The weapon replace list for ", self.classname, " contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		if(wpn == 0)
		{
			remove(self);
			item_start_failed = TRUE;
			return;
		}
	}

	e = get_weaponinfo(wpn);

	if(e.items && e.items != IT_SUPERWEAPON)
	{
		for(i = 0, j = 1; i < 24; ++i, j *= 2)
		{
			if(e.items & j)
			{
				ammofield = item_counter_field(j);
				if(!self.ammofield)
					self.ammofield = cvar(strcat("g_pickup_", item_counter_field_name(j)));
			}
		}
	}
	else
	{
		self.flags |= FL_NO_WEAPON_STAY;
	}

	// weapon stay isn't supported for teamed weapons
	if(self.team)
		self.flags |= FL_NO_WEAPON_STAY;

	item_start(e.model, "weapons/weaponpickup.wav", self.respawntime, self.respawntimejitter, e.message, 0, e.weapons, FL_WEAPON, weapon_pickupevalfunc, e.bot_pickupbasevalue);
	if (self.modelindex) // don't precache if self was removed
		weapon_precache(e.weapon);
}

// Setup weapon for client (after this raise frame will be launched)
void(float windex) weapon_setup {
	entity e;
	e = get_weaponinfo(windex);
	self.items &~= IT_AMMO;
	self.items = self.items | e.items;

	// the two weapon entities will notice this has changed and update their models
	self.weapon = windex;
	self.weaponname = e.mdl;
	self.bulletcounter = 0;
}

// perform weapon to attack (weaponstate and attack_finished check is here)
float(float secondary, float attacktime) weapon_prepareattack {
	if(!GameHookChain_WeaponPrepareAttack(secondary, attacktime)) {
		return FALSE;
	}

	if(attacktime >= 0)
	{
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(self) > time + frametime * 0.5)
			return FALSE;
		// don't fire while changing weapon
		if (self.weaponentity.state != WS_READY)
			return FALSE;
	}
	// do not even think about shooting if switching
	if(self.switchweapon != self.weapon)
		return FALSE;

	if not(player_can_fire(self, TRUE))
		return FALSE;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (!weapon_action(self.weapon, WR_CHECKAMMO1 + secondary))
	{
		if (Akimbo_Active(self) < 2)
			weapon_switch_force(self, weapon_best(self));
		return FALSE;
	}

	self.weaponentity.state = WS_INUSE;

	self.spawnshieldtime = min(self.spawnshieldtime, time); // kill spawn shield when you fire

	// if the weapon hasn't been firing continuously, reset the timer
	if(attacktime >= 0)
	{
		if (ATTACK_FINISHED(self) < time - frametime * 1.5)
		{
			ATTACK_FINISHED(self) = time;
			//dprint("resetting attack finished to ", ftos(time), "\n");
		}
		ATTACK_FINISHED(self) = ATTACK_FINISHED(self) + attacktime * weapon_rate_factor();
	}
	self.bulletcounter += 1;
	//dprint("attack finished ", ftos(ATTACK_FINISHED(self)), "\n");
	return TRUE;
}

float() weapon_rate_factor {
	float t;
	entity oldself = self;
	self = Akimbo_Owner(self);
	t = (1.0 / g_weaponratefactor) * GameHookChain_WeaponRateFactor();
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

float() weapon_model_customize {
	self.viewmodelforclient = Akimbo_Owner(self.owner);
	if(other.classname == "spectator")
		if(other.enemy == self.viewmodelforclient)
			self.viewmodelforclient = other;

	return TRUE;
}

float weapon_model_exterior_customize()
{
    self.alpha = player_calculate_alpha(self.owner, other);
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

void weapon_model_dlc_reset() {
	setattachment(self.weaponentity, self, "weapon");
}

void weapon_model_think()
{
	float tb, v_shot_idx;
	self.nextthink = time;
	if (intermission_running)
		self.frame = self.anim_idle_x;
	if (self.owner.weaponentity != self)
	{
		if (self.weaponentity)
			remove(self.weaponentity);
		remove(self);
		return;
	}
	if (PLAYER_REALLY_DEAD(self.owner))
	{
		self.model = "";
		if (self.weaponentity)
			self.weaponentity.model = "";
		return;
	}
	if (self.cnt != self.owner.weapon || self.dmg != self.owner.modelindex || self.deadflag != self.owner.deadflag)
	{
		self.cnt = self.owner.weapon;
		self.dmg = self.owner.modelindex;
		self.deadflag = self.owner.deadflag;
		if (self.owner.weaponname != "")
		{
			// if there is a child entity, hide it until we're sure we use it
			if (self.weaponentity)
				self.weaponentity.model = "";
			setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
			v_shot_idx = gettagindex(self, "shot"); // used later
			self.dlc_reset = world.dlc_reset;
			if(sv_qcweaponanimation)
			{
				self.angles = '0 0 0';
				makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
				self.movedir = weapon_offset_x * v_forward - weapon_offset_y * v_right + weapon_offset_z * v_up + weapon_adjust;
				self.movedir_x += 32;
				self.spawnorigin = self.movedir;
				// oldorigin - not calculated here
			}
			else
			{
				setmodel(self, strcat("models/weapons/h_", self.owner.weaponname, ".dpm")); // precision set below
				entity e = get_weaponinfo(self.owner.weapon);
				self.anim_fire1  = e.anim_fire1;
				self.anim_fire2  = e.anim_fire2;
				self.anim_idle   = e.anim_idle;
				self.anim_reload = e.anim_reload;

				// if we have a "weapon" tag, let's attach the v_ model to it ("invisible hand" style model)
				// if we don't, this is a "real" animated model
				if(gettagindex(self, "weapon"))
				{
					if (!self.weaponentity)
						self.weaponentity = spawn();
					setmodel(self.weaponentity, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision does not matter
					self.dlc_reset = weapon_model_dlc_reset;
					self.dlc_reset();
				}
				else
				{
					if(self.weaponentity)
						remove(self.weaponentity);
					self.weaponentity = world;
				}

				setorigin(self,'0 0 0');
				self.angles = '0 0 0';
				self.frame = 0;
				self.viewmodelforclient = world;

				float idx;
				idx = gettagindex(self, "shot");
				if(idx)
				{
					self.movedir = gettaginfo(self, idx);
				}
				else
				{
					print("WARNING: weapon model ", self.model, " does not support the 'shot' tag, will display shots TOTALLY wrong\n");
					self.movedir = '0 0 0';
				}

				idx = gettagindex(self, "shell");
				if(idx)
				{
					self.spawnorigin = gettaginfo(self, idx);
				}
				else
				{
					print("WARNING: weapon model ", self.model, " does not support the 'shell' tag, will display casings wrong\n");
					self.spawnorigin = self.movedir;
				}

				if(v_shot_idx)
				{
					self.oldorigin = '0 0 0';
				}
				else
				{
					if(self.weaponentity)
						idx = gettagindex(self, "weapon");
					else
						idx = gettagindex(self, "handle");
					if(idx)
					{
						self.oldorigin = self.movedir - gettaginfo(self, idx);
					}
					else
					{
						print("WARNING: weapon model ", self.model, " does not support the 'handle' tag and neither does the v_ model support the 'shot' tag, will display muzzle flashes TOTALLY wrong\n");
						self.oldorigin = '0 0 0'; // there is no way to recover from this
					}
				}

				self.viewmodelforclient = Akimbo_Owner(self.owner);
			}
		}
		else
		{
			self.model = "";
			if(self.weaponentity)
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

		if(self.movedir_x >= 0)
		{
			vector v0;
			v0 = self.movedir;
			float akimbo_active = Akimbo_Active(self.owner);
			self.movedir = weapon_shotorg_adjust(v0, FALSE, FALSE, akimbo_active);
			self.shotorg_visual = weapon_shotorg_adjust(v0, FALSE, TRUE, akimbo_active);
			self.view_ofs = weapon_shotorg_adjust(v0, FALSE, TRUE, akimbo_active) - v0;
		}
		self.spawnorigin += self.view_ofs; // offset the casings origin by the same amount

		// check if an instant weapon switch occurred
		if (sv_qcweaponanimation)
		{
			if (self.state == WS_READY)
			{
				self.angles = '0 0 0';
				makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
				setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
			}
		}
		else
			setorigin(self, self.view_ofs);
		// reset animstate now
		self.weapon_morph0time = 0;
		self.weapon_morph1time = 0;
		self.weapon_morph2time = 0;
		self.weapon_morph3time = 0;
		self.weapon_morph4time = 0;
		anim_set(self, self.anim_idle, TRUE, FALSE, TRUE);
	}

	tb = (self.effects & EF_TELEPORT_BIT);
	self.effects = self.owner.effects & EFMASK_CHEAP;
	self.effects &~= EF_LOWPRECISION;
	self.effects &~= EF_FULLBRIGHT; // can mask team color, so get rid of it
	self.effects &~= EF_TELEPORT_BIT;
	self.effects |= tb;

	self.colormap = self.owner.colormap;
	self.alpha = player_calculate_alpha(self.owner, self.owner);
	if (self.owner.cvar_cl_gunalpha)
		self.alpha *= self.owner.cvar_cl_gunalpha;

	if (self.weaponentity)
	{
		self.weaponentity.effects = self.effects;
		self.weaponentity.alpha = self.alpha;
		self.weaponentity.colormap = self.colormap;
	}

	self.angles = '0 0 0';
	local float f;
	f = 0;
	float useqcanimation = (sv_qcweaponanimation || self.wframe >= WFRAME_MELEE);
	if (self.state == WS_RAISE && !intermission_running && g_balance_weaponswitchdelay)
	{
		f = (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation)
		{
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	}
	else if (self.state == WS_DROP && !intermission_running && g_balance_weaponswitchdelay)
	{
		f = 1 - (self.owner.weapon_nextthink - time) * g_weaponratefactor * (1 / weapon_rate_factor_for(self.owner)) / g_balance_weaponswitchdelay;
		self.angles_x = -90 * f * f;
		if (useqcanimation)
		{
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	}
	else if (self.state == WS_CLEAR)
	{
		f = 1;
		self.angles_x = -90 * f * f;
		if (useqcanimation)
		{
			makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
			setorigin(self, QCWEAPONANIMATION_ORIGIN(self));
		}
	}
	else if (useqcanimation && time < self.owner.weapon_morph1time)
	{
		f = (time - self.owner.weapon_morph0time) / (self.owner.weapon_morph1time - self.owner.weapon_morph0time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph0angles * (1 - f) + self.owner.weapon_morph1angles * f;
		setorigin(self, self.owner.weapon_morph0origin * (1 - f) + self.owner.weapon_morph1origin * f);
	}
	else if (useqcanimation && time < self.owner.weapon_morph2time)
	{
		f = (time - self.owner.weapon_morph1time) / (self.owner.weapon_morph2time - self.owner.weapon_morph1time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph1angles * (1 - f) + self.owner.weapon_morph2angles * f;
		setorigin(self, self.owner.weapon_morph1origin * (1 - f) + self.owner.weapon_morph2origin * f);
	}
	else if (useqcanimation && time < self.owner.weapon_morph3time)
	{
		f = (time - self.owner.weapon_morph2time) / (self.owner.weapon_morph3time - self.owner.weapon_morph2time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph2angles * (1 - f) + self.owner.weapon_morph3angles * f;
		setorigin(self, self.owner.weapon_morph2origin * (1 - f) + self.owner.weapon_morph3origin * f);
	}
	else if (useqcanimation && time < self.owner.weapon_morph4time)
	{
		f = (time - self.owner.weapon_morph3time) / (self.owner.weapon_morph4time - self.owner.weapon_morph3time);
		f = 1 - pow(1 - f, 3);
		self.angles = self.owner.weapon_morph3angles * (1 - f) + self.owner.weapon_morph4angles * f;
		setorigin(self, self.owner.weapon_morph3origin * (1 - f) + self.owner.weapon_morph4origin * f);
	}
	else if (useqcanimation)
	{
		// begin a new idle morph
		self.owner.weapon_morph0time   = time;
		self.owner.weapon_morph0angles = self.angles;
		self.owner.weapon_morph0origin = self.origin;

		float r;
		float t;

		r = random();
		if (r < 0.1)
		{
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
		}
		else if (r < 0.2)
		{
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
		}
		else if (r < 0.3)
		{
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
		}
		else
		{
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

void weapon_model_exterior_dlc_reset() {
	float tag_found;
	if (self.owner.weaponname != "")
		setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
	else
		self.model = "";

	entity ao = Akimbo_Owner(self.owner);
	float akimbo_weapon = (Akimbo_Active(self.owner) == 2);
	if((tag_found = gettagindex(ao, "tag_weapon")))
	{
		self.tag_index = tag_found;
		self.tag_entity = ao;
	}
	else if (akimbo_weapon && g_akimbo_use_left_hand) {
		if (akimbo_weapon)
			setattachment(self, ao, "bip01 l hand");

		self.angles = stov(cvar_string("g_akimbo_use_left_hand_rotate"));
	} else {
		setattachment(self, ao, "bip01 r hand");
		if (akimbo_weapon)
			setorigin(self, '0 20 0');
	}
	// if that didn't find a tag, hide the exterior weapon model
	if (!self.tag_index)
		self.model = "";
}

void weapon_model_exterior_think()
{
	self.nextthink = time;
	if (self.owner.exteriorweaponentity != self)
	{
		remove(self);
		return;
	}
	if (PLAYER_REALLY_DEAD(self.owner))
	{
		self.model = "";
		return;
	}
	if (self.cnt != self.owner.weapon || self.dmg != self.owner.modelindex || self.deadflag != self.owner.deadflag)
	{
		self.cnt = self.owner.weapon;
		self.dmg = self.owner.modelindex;
		self.deadflag = self.owner.deadflag;
		self.dlc_reset = weapon_model_exterior_dlc_reset;
		self.dlc_reset();
	}
	self.effects = self.owner.effects | EF_LOWPRECISION;
	self.effects = self.effects & EFMASK_CHEAP; // eat performance

	self.colormap = self.owner.colormap;
}

// spawning weaponentity for client
void weapon_model_spawn()
{
	self.weaponentity = spawn();
	self.weaponentity.classname = "weaponentity";
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	setmodel(self.weaponentity, ""); // precision set when changed
	setorigin(self.weaponentity, '0 0 0');
	self.weaponentity.angles = '0 0 0';
	self.weaponentity.viewmodelforclient = Akimbo_Owner(self);
	self.weaponentity.flags = 0;
	self.weaponentity.think = weapon_model_think;
	self.weaponentity.customizeentityforclient = weapon_model_customize;
	self.weaponentity.nextthink = time;

	self.exteriorweaponentity = spawn();
	self.exteriorweaponentity.classname = "exteriorweaponentity";
	self.exteriorweaponentity.solid = SOLID_NOT;
	self.exteriorweaponentity.exteriorweaponentity = self.exteriorweaponentity;
	self.exteriorweaponentity.owner = self;
	setorigin(self.exteriorweaponentity, '0 0 0');
	self.exteriorweaponentity.angles = '0 0 0';
	self.exteriorweaponentity.think = weapon_model_exterior_think;
	self.exteriorweaponentity.customizeentityforclient = weapon_model_exterior_customize;
	self.exteriorweaponentity.nextthink = time;
}

void weapon_thinkf(float fr, float t, void() func)
{
	vector a;
	vector of, or, ou;
	float restartanim;

	if(fr == WFRAME_DONTCHANGE)
	{
		fr = self.weaponentity.wframe;
		restartanim = FALSE;
	}
	else if (fr == WFRAME_IDLE)
		restartanim = FALSE;
	else
		restartanim = TRUE;

	of = v_forward;
	or = v_right;
	ou = v_up;

	if (self.weaponentity)
	{
		self.weaponentity.wframe = fr;
		if (sv_qcweaponanimation || fr >= WFRAME_MELEE)
		{
			if (fr != WFRAME_IDLE)
			{
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

				if (fr == WFRAME_FIRE1)
				{
					self.weapon_morph1angles = '5 0 0';
					self.weapon_morph1time = time + t * 0.1;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
					self.weapon_morph4time = time + t + 1; // delay idle effect
				}
				else if (fr == WFRAME_FIRE2)
				{
					self.weapon_morph1angles = '10 0 0';
					self.weapon_morph1time = time + t * 0.1;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity);
					self.weapon_morph4time = time + t + 1; // delay idle effect
				}
				else if (fr == WFRAME_RELOAD)
				{
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
				}
				else if (fr == WFRAME_MELEE)
				{
					self.weapon_morph1time = time + t * 0.25;
					self.weapon_morph1angles = sv_qcanimation_melee_morph1angles;
					makevectors(self.weapon_morph1angles_x * '-1 0 0' + self.weapon_morph1angles_y * '0 1 0' + self.weapon_morph1angles_z * '0 0 1');
					self.weapon_morph1origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee_morph1origin;

					self.weapon_morph2time = time + t * 0.65;
					self.weapon_morph2angles = sv_qcanimation_melee_morph2angles;
					makevectors(self.weapon_morph2angles_x * '-1 0 0' + self.weapon_morph2angles_y * '0 1 0' + self.weapon_morph2angles_z * '0 0 1');
					self.weapon_morph2origin = QCWEAPONANIMATION_ORIGIN(self.weaponentity) + sv_qcanimation_melee_morph2origin;
				}
				else if (fr == WFRAME_MELEE2)
				{
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
		}
		else
		{
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

	if(self.weapon_think == weapon_ready && func != weapon_ready && self.weaponentity.state == WS_RAISE)
	{
		backtrace("Tried to override initial weapon think function - should this really happen?");
	}

	t *= weapon_rate_factor();

	// VorteX: haste can be added here
	if (self.weapon_think == weapon_ready)
	{
		self.weapon_nextthink = time;
		//dprint("started firing at ", ftos(time), "\n");
	}
	if (self.weapon_nextthink < time - frametime * 1.5 || self.weapon_nextthink > time + frametime * 1.5)
	{
		self.weapon_nextthink = time;
		//dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	self.weapon_nextthink = self.weapon_nextthink + t;
	self.weapon_think = func;
	//dprint("next ", ftos(self.weapon_nextthink), "\n");

	if (restartanim)
	if (t)
	if (!self.crouch) // shoot anim stands up, this looks bad
	{
		local vector anim;
		if (fr == WFRAME_MELEE2)
			anim = self.anim_melee2;
		else if (fr == WFRAME_MELEE || self.weapon == WEP_MELEE)
			anim = self.anim_melee;
		else
			anim = self.anim_shoot;
		anim_z = anim_y / t;
		anim_set(self, anim, FALSE, TRUE, TRUE);
	}
}

// Weapon subs
void() weapon_clear {
	if (self.weapon != -1)
		self.weapon = 0;

	if (self.weaponentity) {
		self.weaponentity.state = WS_CLEAR;
		self.weaponentity.effects = 0;
	}
}

void() weapon_ready {
	if (self.weaponentity)
		self.weaponentity.state = WS_READY;

	weapon_thinkf(WFRAME_IDLE, 1000000, weapon_ready);
}

// this function calculates w_shotorg and w_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put w_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
.float lastshot_time;
void(entity ent, vector s_forward, float recoil, string snd, float maxhits) weapon_setup_shotdir {
	vector vecs, vecs_visual, dv;
	entity ent_orig = ent;
	ent = Akimbo_Owner(ent);
	// Track max damage and set the stat to be sent later in g_world.qc
	if (maxhits > 0)
		damage_record_fires(ent, ent.weapon, maxhits);

	if(ent_orig.weaponentity.movedir_x > 0)
	{
		vecs = ent_orig.weaponentity.movedir;
		vecs_y = -vecs_y;
	}
	else
		vecs = '0 0 0';
	vecs_visual = ent_orig.weaponentity.shotorg_visual;
	vecs_visual_y = -vecs_visual_y;

	dv = v_right * vecs_y + v_up * vecs_z;
	w_shotorg = ent.origin + ent.view_ofs;

	w_shotorg_visual = w_shotorg + (v_right * vecs_visual_y + v_up * vecs_visual_z) + v_forward * 16;

	w_shotorg = w_shotorg + dv;

	// calculate the shotdir from the chosen shotorg
	if (Akimbo_Active(ent))
		w_shotdir = s_forward;
	else
	{
		float dphitcontentsmask_save = ent.dphitcontentsmask;
		if(ent.weapon == WEP_CAMPINGRIFLE)
			ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
		else
			ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

		WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * MAX_SHOT_DISTANCE, MOVE_NOMONSTERS, ent);
		ent.dphitcontentsmask = dphitcontentsmask_save;
		w_shotpoint = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
		w_shotdir = normalize(w_shotpoint - w_shotorg);
	}
	if (!g_norecoil)
		ent.punchangle_x = recoil * -1;

	if (ent.lastshot_time < time) {
		if (snd != "")
			sound (ent, CHAN_WEAPON, snd, VOL_BASE, ATTN_NORM);

		if (ent.items & IT_STRENGTH)
			sound (ent, CHAN_AUTO, "weapons/strength_fire.wav", VOL_BASE, ATTN_NORM);

		ent.lastshot_time = time;
	}
}

vector weapon_calculate_projectile_velocity(vector pvelocity, vector mvelocity)
{
	vector mdirection;
	float mspeed;
	float outspeed;
	vector outvelocity;

	mvelocity = mvelocity * g_weaponspeedfactor;

	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);

	if(g_projectiles_newton_style == 0)
	{
		// absolute velocity
		outvelocity = mvelocity;
	}
	else if(g_projectiles_newton_style == 1)
	{
		// true Newtonian projectiles
		outvelocity = pvelocity + mvelocity;
	}
	else if(g_projectiles_newton_style == 2)
	{
		// true Newtonian projectiles with automatic aim adjustment
		//
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
		solution = solve_quadratic(1, -2 * (mdirection * pvelocity), pvelocity * pvelocity - mspeed * mspeed);
		if(solution_z)
			outspeed = solution_y; // the larger one
		else
		{
			//outspeed = 0; // slowest possible shot
			outspeed = solution_x; // the real part (that is, the average!)
			//dprint("impossible shot, adjusting\n");
		}

		outspeed = bound(mspeed * g_projectiles_newton_style_2_minfactor, outspeed, mspeed * g_projectiles_newton_style_2_maxfactor);
		outvelocity = mdirection * outspeed;
	}
	else if(g_projectiles_newton_style == 3)
	{
		// pseudo-Newtonian:
		outspeed = mspeed + mdirection * pvelocity;
		outspeed = bound(mspeed * 0.7, outspeed, mspeed * 5.0);
		outvelocity = mdirection * outspeed;
	}
	else if(g_projectiles_newton_style == 4)
	{
		// tZorkian:
		outspeed = mspeed + vlen(pvelocity);
		outvelocity = mdirection * outspeed;
	}
	else
		error("g_projectiles_newton_style must be 0 (absolute), 1 (Newtonian), 2 (Newtonian + aimfix), 3 (pseudo Newtonian) or 4 (tZorkian)!");

	return outvelocity;
}

vector(vector vecs, float y_is_right, float allowcenter) weapon_shotorg_adjustfromclient {
	switch(self.owner.cvar_cl_gunalign)
	{
		case 1: // right
			break;

		case 2: // left
			vecs_y = -vecs_y;
			break;

		default:
		case 3:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs_y = 0;
				vecs_z -= 4;
			}
			else
			{
				// right
			}
			break;

		case 4:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs_y = 0;
				vecs_z -= 4;
			}
			else
			{
				// left
				vecs_y = -vecs_y;
			}
			break;
	}
	return vecs;
}

vector(vector vecs, float y_is_right, float visual, float akimbo_active) weapon_shotorg_adjust {
	if (akimbo_active)
	{
		if (akimbo_active == 2)
			vecs_y = -vecs_y;
		if not(visual)
		{
			if (g_shootfromeye)
				vecs_z = 0;
			else if (g_shootfromcenter)
				vecs_z -= 4;
		}
		vecs_y = vecs_y * 1.2;
		return vecs;
	}

	if (g_shootfromeye)
	{
		if (visual)
		{
			vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		}
		else
		{
			vecs_y = 0;
			vecs_z = 0;
		}
	}
	else if (g_shootfromcenter)
	{
		if (visual)
		{
			vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		}
		else
		{
			vecs_y = 0;
			vecs_z -= 4;
		}
	}
	else if (g_shootfromclient)
	{
		vecs = weapon_shotorg_adjustfromclient(vecs, y_is_right, (g_shootfromclient >= 2));
	}
	return vecs;
}

void(entity missile) weapon_setup_projectile_velocity {
	if(missile.owner == world)
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
	if(sv_qcweaponanimation)
	{
		setorigin(flash, w_shotorg + w_shotdir * 50);
		flash.angles = vectoangles(w_shotdir);
		flash.angles_z = random() * 360;
	}
	else
	{
		setattachment(flash, self.weaponentity, "shot");
		setorigin(flash, offset);

		xflash = spawn();
		copyentity(flash, xflash);

		flash.viewmodelforclient = Akimbo_Owner(self);

		if(self.weaponentity.oldorigin_x > 0)
		{
			setattachment(xflash, self.exteriorweaponentity, "");
			setorigin(xflash, self.weaponentity.oldorigin + offset);
		}
		else
		{
			setattachment(xflash, self.exteriorweaponentity, "shot");
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

void() weapon_init {
	float i;
	CACHE_CVAR(g_balance_weaponswitchdelay);
	CACHE_CVAR(g_projectiles_newton_style_2_minfactor);
	CACHE_CVAR(g_projectiles_newton_style_2_maxfactor);
	CACHE_CVAR(g_showweaponspawns);
	CACHE_CVAR(sv_qcweaponanimation);
	CACHE_CVAR(g_weaponspeedfactor);
	CACHE_CVAR(g_weaponratefactor);
	CACHE_CVAR(g_akimbo_use_left_hand);
	CACHE_CVAR(g_shootfromcenter);
	CACHE_CVAR(g_shootfromclient);
	CACHE_CVAR(g_shootfromeye);
	sv_qcanimation_melee_morph1angles = stov(cvar_string("sv_qcanimation_melee_morph1angles"));
	sv_qcanimation_melee_morph2angles = stov(cvar_string("sv_qcanimation_melee_morph2angles"));
	sv_qcanimation_melee_morph1origin = stov(cvar_string("sv_qcanimation_melee_morph1origin"));
	sv_qcanimation_melee_morph2origin = stov(cvar_string("sv_qcanimation_melee_morph2origin"));
	sv_qcanimation_melee2_morph1angles = stov(cvar_string("sv_qcanimation_melee2_morph1angles"));
	sv_qcanimation_melee2_morph2angles = stov(cvar_string("sv_qcanimation_melee2_morph2angles"));
	sv_qcanimation_melee2_morph1origin = stov(cvar_string("sv_qcanimation_melee2_morph1origin"));
	sv_qcanimation_melee2_morph2origin = stov(cvar_string("sv_qcanimation_melee2_morph2origin"));
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		(get_weaponinfo(i)).weapon_func(WR_CVAR_CACHE);
	}
	Melee_Init();
	W_BallisticInit();

	ProjInfo_RegisterAuto(PROJECTILE_BULLET, '0 0 0');
	ProjInfo_RegisterAuto(PROJECTILE_BULLET_GLOWING, '0 0 0');
	ProjInfo_RegisterAuto(PROJECTILE_BULLET_BIG, '0 0 0');
}
