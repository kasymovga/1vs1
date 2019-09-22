//Camping rifle Primary mode: manually operated bolt*, Secondary: full automatic**
//* Manually operating the bolt means that all the power of the gas is used to propell the bullet. In this mode the bolt is prevented from moving backwards in response to the firing of the bullet.
//** In fully automatic mode some of the gas is used to extract and reload the next cartrige, thus there is less power and range.

float g_balance_campingrifle_auto_reload_after_changing_weapons;
float g_balance_campingrifle_bursttime;
float g_balance_campingrifle_magazinecapacity;
float g_balance_campingrifle_primary_ammo;
float g_balance_campingrifle_primary_animtime;
float g_balance_campingrifle_primary_bulletconstant;
float g_balance_campingrifle_primary_burstcost;
float g_balance_campingrifle_primary_damage;
float g_balance_campingrifle_primary_force;
float g_balance_campingrifle_primary_gravityfactor;
float g_balance_campingrifle_primary_headshotaddeddamage;
float g_balance_campingrifle_primary_lifetime;
float g_balance_campingrifle_primary_refire;
float g_balance_campingrifle_primary_speed;
float g_balance_campingrifle_primary_spread;
float g_balance_campingrifle_secondary_ammo;
float g_balance_campingrifle_secondary_animtime;
float g_balance_campingrifle_secondary_bulletconstant;
float g_balance_campingrifle_secondary_burstcost;
float g_balance_campingrifle_secondary_damage;
float g_balance_campingrifle_secondary_force;
float g_balance_campingrifle_secondary_gravityfactor;
float g_balance_campingrifle_secondary_headshotaddeddamage;
float g_balance_campingrifle_secondary_lifetime;
float g_balance_campingrifle_secondary_refire;
float g_balance_campingrifle_secondary_speed;
float g_balance_campingrifle_secondary_spread;

.float campingrifle_ammoclip;
var .float cr_buttonatck1 = BUTTON_ATCK;
var .float cr_buttonatck2 = BUTTON_ATCK2;
.float campingrifle_accumulator;
.float campingrifle_hotreloadtime;

float weapon_campingrifle_checkmaxbullets()
{
	float maxbulls;
	maxbulls = g_balance_campingrifle_magazinecapacity;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		maxbulls = min(maxbulls, floor(self.ammo_nails / min(g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo)));
	if(self.campingrifle_ammoclip > maxbulls)
		self.campingrifle_ammoclip = maxbulls;
	return (self.campingrifle_ammoclip == maxbulls);
}

void weapon_campingrifle_hotreload()
{
	if (time < self.campingrifle_hotreloadtime)
		return;

	if (self.campingrifle_ammoclip >= g_balance_campingrifle_magazinecapacity)
		return;

	if (self.weaponentity.state != WS_READY)
		return;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (self.ammo_nails < min(g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo) * (self.campingrifle_ammoclip + 1))
		return;
	self.campingrifle_ammoclip++;
	self.campingrifle_hotreloadtime += g_balance_campingrifle_reloadtime;
}

void weapon_campingrifle_reloadandready()
{
	float t;
	self.campingrifle_ammoclip = g_balance_campingrifle_magazinecapacity;
	weapon_campingrifle_checkmaxbullets();
	t = ATTACK_FINISHED(self) - g_balance_campingrifle_reloadtime - 1;
	ATTACK_FINISHED(self) = t;
	weapon_ready();
}

void weapon_campingrifle_ready()
{
	float t;

	weapon_campingrifle_checkmaxbullets();
	if (self.campingrifle_ammoclip >= g_balance_campingrifle_magazinecapacity)
		return;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if(self.ammo_nails < min(g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo))
	{
		self.campingrifle_ammoclip = -1; // reload later
		return;
	}
	
	if (self.weaponentity)
	{
		if (self.weaponentity.wframe == WFRAME_RELOAD)
			return;

		// allow to switch away while reloading, but this will cause a new reload!
		self.weaponentity.state = WS_READY;
	}

	sound (self, CHAN_WEAPON2, "weapons/campingrifle_reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + g_balance_campingrifle_reloadtime + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, g_balance_campingrifle_reloadtime, weapon_campingrifle_reloadandready);

	self.campingrifle_ammoclip = -1;
}

void weapon_campingrifle_checkreloadandready()
{
	weapon_ready();
	if (g_balance_campingrifle_hotreload)
	{
		self.campingrifle_hotreloadtime = time + g_balance_campingrifle_reloadtime;
		return;
	}
	if (self.campingrifle_ammoclip <= 0)
		weapon_campingrifle_ready();
	else
		weapon_ready();
}

void weapon_campingrifle_fire(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant)
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_nails -= pAmmo;

	bullet_begin(pSpeed);
	if(deathtype & HITTYPE_SECONDARY)
		weapon_setup_shot (self, 2, "weapons/campingrifle_fire2.wav", 1);
	else
		weapon_setup_shot (self, 2, "weapons/campingrifle_fire.wav", 1);

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg_visual, w_shotdir * 2000, 1);

	if(self.BUTTON_ZOOM) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}

	bullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, particleeffectnum("tr_rifle"), ((deathtype & HITTYPE_SECONDARY) ? g_balance_campingrifle_primary_gravityfactor : g_balance_campingrifle_primary_gravityfactor), pBulletConstant);
	bullet_end();

	if (g_casings >= 2)
		casing_spawn (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
	
	self.campingrifle_ammoclip = self.campingrifle_ammoclip - 1;
	weapon_campingrifle_checkmaxbullets();
}

void weapon_campingrifle_attack()
{
	weapon_campingrifle_fire(g_balance_campingrifle_primary_spread, g_balance_campingrifle_primary_damage, g_balance_campingrifle_primary_headshotaddeddamage, g_balance_campingrifle_primary_force, g_balance_campingrifle_primary_speed, g_balance_campingrifle_primary_lifetime, g_balance_campingrifle_primary_ammo, WEP_CAMPINGRIFLE, g_balance_campingrifle_primary_bulletconstant);
}

void weapon_campingrifle_attack2()
{
	weapon_campingrifle_fire(g_balance_campingrifle_secondary_spread, g_balance_campingrifle_secondary_damage, g_balance_campingrifle_secondary_headshotaddeddamage, g_balance_campingrifle_secondary_force, g_balance_campingrifle_secondary_speed, g_balance_campingrifle_secondary_lifetime, g_balance_campingrifle_secondary_ammo, WEP_CAMPINGRIFLE | HITTYPE_SECONDARY, g_balance_campingrifle_secondary_bulletconstant);
}

void spawnfunc_weapon_campingrifle (void)
{
	weapon_defaultspawnfunc(WEP_CAMPINGRIFLE);
}

.float bot_secondary_campingriflemooth;
float weapon_campingrifle(float req)
{
	float full;
	if (req == WR_AIM)
	{
		self.cr_buttonatck1=FALSE;
		self.cr_buttonatck2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_secondary_campingriflemooth = 0;
		if(self.bot_secondary_campingriflemooth == 0)
		{
			if(bot_aim(g_balance_campingrifle_primary_speed, 0, g_balance_campingrifle_primary_lifetime, TRUE))
			{
				self.cr_buttonatck1 = TRUE;
				if(random() < 0.01) self.bot_secondary_campingriflemooth = 1;
			}
		}
		else
		{
			if(bot_aim(g_balance_campingrifle_secondary_speed, 0, g_balance_campingrifle_secondary_lifetime, TRUE))
			{
				self.cr_buttonatck2 = TRUE;
				if(random() < 0.03) self.bot_secondary_campingriflemooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if(self.campingrifle_ammoclip < 0 || (!self.campingrifle_ammoclip && (self.cr_buttonatck1 || self.cr_buttonatck2))) // forced reload (e.g. because interrupted)
		{
			if not(g_balance_campingrifle_hotreload)
			if(self.switchweapon == self.weapon)
			if(self.weaponentity.state == WS_READY)
				weapon_campingrifle_ready();
		}
		else if (self.campingrifle_ammoclip > 0)
		{
			self.campingrifle_accumulator = bound(time - g_balance_campingrifle_bursttime, self.campingrifle_accumulator, time);
			if (self.cr_buttonatck1)
			if (time >= self.campingrifle_accumulator + g_balance_campingrifle_primary_burstcost)
			if (weapon_prepareattack(0, g_balance_campingrifle_primary_refire))
			{
				weapon_campingrifle_attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_campingrifle_primary_animtime, weapon_campingrifle_checkreloadandready);
				self.campingrifle_accumulator += g_balance_campingrifle_primary_burstcost;
			}
			if (self.cr_buttonatck2)
			if (time >= self.campingrifle_accumulator + g_balance_campingrifle_secondary_burstcost)
			if (weapon_prepareattack(1, g_balance_campingrifle_secondary_refire))
			{
				weapon_campingrifle_attack2();
				weapon_thinkf(WFRAME_FIRE2, g_balance_campingrifle_secondary_animtime, weapon_campingrifle_checkreloadandready);
				self.campingrifle_accumulator += g_balance_campingrifle_secondary_burstcost;
			}
		}
		if (g_balance_campingrifle_hotreload)
			weapon_campingrifle_hotreload();
		else {
			self.ammoclip = self.campingrifle_ammoclip;
			if (self.ammoclip <= 0)
				self.ammoclip = 0;
		}

	}
	else if (req == WR_PRECACHE)
	{		
		precache_sound ("weapons/campingrifle_reload.wav");
		precache_sound ("weapons/campingrifle_fire.wav");
		precache_sound ("weapons/campingrifle_fire2.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_CAMPINGRIFLE);

		full = weapon_campingrifle_checkmaxbullets();
		if(g_balance_campingrifle_auto_reload_after_changing_weapons)
			if(!full)
				self.campingrifle_ammoclip = -1;

		if not(self.campingrifle_ammoclip)
			self.campingrifle_ammoclip = -1;

		self.campingrifle_hotreloadtime = time + g_balance_campingrifle_reloadtime;
	}
	else if (req == WR_CHECKAMMO1)
		return self.ammo_nails >= g_balance_campingrifle_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_nails >= g_balance_campingrifle_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "shot himself automatically";
		else
			w_deathtypestring = "sniped himself somehow";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_BOUNCE)
				w_deathtypestring = "failed to hide from #'s bullet hail";
			else
				w_deathtypestring = "died in #'s bullet hail";
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				// TODO special headshot message here too?
				w_deathtypestring = "failed to hide from #'s rifle";
			}
			else
			{
				if(w_deathtype & HITTYPE_HEADSHOT)
					w_deathtypestring = "got hit in the head by #";
				else
					w_deathtypestring = "was sniped by #";
			}
		}
	}
	else if (req == WR_RELOAD)
	{
		if not(g_balance_campingrifle_hotreload)
			weapon_campingrifle_ready();
	}
	else if (req == WR_RESETPLAYER)
	{
		self.campingrifle_accumulator = time - g_balance_campingrifle_bursttime;
		self.campingrifle_ammoclip = ((start_items & IT_UNLIMITED_WEAPON_AMMO) ? g_balance_campingrifle_magazinecapacity : -1);
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_campingrifle_auto_reload_after_changing_weapons);
		CACHE_CVAR(g_balance_campingrifle_bursttime);
		CACHE_CVAR(g_balance_campingrifle_magazinecapacity);
		if (g_balance_campingrifle_magazinecapacity < 0)
			g_balance_campingrifle_magazinecapacity = 8;
		CACHE_CVAR(g_balance_campingrifle_primary_ammo);
		CACHE_CVAR(g_balance_campingrifle_primary_animtime);
		CACHE_CVAR(g_balance_campingrifle_primary_bulletconstant);
		CACHE_CVAR(g_balance_campingrifle_primary_burstcost);
		CACHE_CVAR(g_balance_campingrifle_primary_damage);
		CACHE_CVAR(g_balance_campingrifle_primary_force);
		CACHE_CVAR(g_balance_campingrifle_primary_gravityfactor);
		CACHE_CVAR(g_balance_campingrifle_primary_headshotaddeddamage);
		CACHE_CVAR(g_balance_campingrifle_primary_lifetime);
		CACHE_CVAR(g_balance_campingrifle_primary_refire);
		CACHE_CVAR(g_balance_campingrifle_primary_speed);
		CACHE_CVAR(g_balance_campingrifle_primary_spread);
		CACHE_CVAR(g_balance_campingrifle_reloadtime);
		CACHE_CVAR(g_balance_campingrifle_secondary_ammo);
		CACHE_CVAR(g_balance_campingrifle_secondary_animtime);
		CACHE_CVAR(g_balance_campingrifle_secondary_bulletconstant);
		CACHE_CVAR(g_balance_campingrifle_secondary_burstcost);
		CACHE_CVAR(g_balance_campingrifle_secondary_damage);
		CACHE_CVAR(g_balance_campingrifle_secondary_force);
		CACHE_CVAR(g_balance_campingrifle_secondary_gravityfactor);
		CACHE_CVAR(g_balance_campingrifle_secondary_headshotaddeddamage);
		CACHE_CVAR(g_balance_campingrifle_secondary_lifetime);
		CACHE_CVAR(g_balance_campingrifle_secondary_refire);
		CACHE_CVAR(g_balance_campingrifle_secondary_speed);
		CACHE_CVAR(g_balance_campingrifle_secondary_spread);
		CACHE_CVAR(g_balance_campingrifle_hotreload);
		if (cvar("g_balance_campingrifle_swap_buttons")) {
			cr_buttonatck1 = BUTTON_ATCK2;
			cr_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
