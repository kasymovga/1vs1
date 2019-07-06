// RED - INPUT
// BLUE - OUTPUT
float g_balance_porto_primary_animtime;
float g_balance_porto_primary_lifetime;
float g_balance_porto_primary_refire;
float g_balance_porto_primary_speed;
float g_balance_powerup_strength_force;

.entity porto_current_in;
.entity porto_current_out;
.vector right_vector;

void weapon_port_success (void)
{
	if(self.owner == world)
	{
		entity_abort("Cannot succeed successfully: no owner\n");
		return;
	}

	if (self.effects & EF_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;
	remove(self);
}

void weapoon_porto_fail ()
{
	if(self.owner == world)
	{
		entity_abort("Cannot fail successfully: no owner\n");
		return;
	}

	if (self.effects & EF_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;

	remove(self);
}

void weapon_porto_remove (entity p)
{
	entity oldself;
	oldself = self;
	if(p.porto_current_in)
	{
		self = p.porto_current_in;
		weapoon_porto_fail();
	}
	if(p.porto_current_out)
	{
		self = p.porto_current_out;
		weapoon_porto_fail();
	}
	self = oldself;
}

void weapon_porto_think (void)
{
	trace_plane_normal = '0 0 0';
	if(self.owner.playerid != self.playerid)
		remove(self);
	else
		weapoon_porto_fail();
}

void weapon_porto_touch (void)
{
	PROJECTILE_SKIPNONSOLID
	vector norm;

	// do not use PROJECTILE_TOUCH here

	if(other.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if(trace_ent.iscreature)
	{
		traceline(trace_ent.origin, trace_ent.origin + '0 0 2' * PL_MIN_z, MOVE_WORLDONLY, self);
		if(trace_fraction >= 1)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
	}

	if(self.owner.playerid != self.playerid)
	{
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		remove(self);
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
	{
		sound_spam(self, CHAN_PROJECTILE, "porto/bounce.wav", VOL_BASE, ATTN_NORM);
		// just reflect
		self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * trace_plane_normal);
		self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		weapoon_porto_fail();
	}
	else if(self.effects & EF_RED)
	{
		if(Portal_SpawnInPortalAtTrace(self.owner, self.right_vector, self.owner.portal_id))
		{
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			centerprint(self.owner, "^1In^7-portal created.");
			weapon_port_success();
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			weapoon_porto_fail();
		}
	}
	else
	{
		if(Portal_SpawnOutPortalAtTrace(self.owner, self.right_vector, self.owner.portal_id))
		{
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			centerprint(self.owner, "^4Out^7-portal created.");
			weapon_port_success();
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			weapoon_porto_fail();
		}
	}
}

void weapon_porto_attack (float out)
{
	local entity gren;

	weapon_setup_shot (self, 4, "porto/fire.wav", 0);
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;

	//pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = projectile(TRUE, PROJECTILE_PORTO_RED, TRUE, self);
	gren.playerid = self.playerid;
	gren.classname = "porto";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = 200;
	gren.movetype = MOVETYPE_BOUNCEMISSILE;
	PROJECTILE_MAKETRIGGER(gren);
	if (out)
	{
		gren.effects = EF_BLUE;
		self.porto_current_out = gren;
	}
	else
	{
		gren.effects = EF_RED;
		self.porto_current_in = gren;
	}
	gren.scale = 4;
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_porto_primary_lifetime;
	gren.think = weapon_porto_think;
	gren.touch = weapon_porto_touch;
	gren.velocity = w_shotdir * g_balance_porto_primary_speed;
	if(self.items & IT_STRENGTH)
		gren.velocity = gren.velocity * g_balance_powerup_strength_force;
	weapon_setup_projectile_velocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.playerid = self.playerid;
	makevectors(vectoangles(gren.velocity));
	gren.right_vector = v_right;

	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

void spawnfunc_weapon_porto (void)
{
	weapon_defaultspawnfunc(WEP_PORTO);
}

float weapon_porto(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if(bot_aim(g_balance_porto_primary_speed, 0, g_balance_porto_primary_lifetime, FALSE))
			self.BUTTON_ATCK = TRUE;
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (!self.porto_current_in)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire))
		{
			weapon_porto_attack(FALSE);
			weapon_thinkf(WFRAME_FIRE1, g_balance_porto_primary_animtime, weapon_ready);
		}
		if (self.BUTTON_ATCK2)
		if (!self.porto_current_out)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire))
		{
			weapon_porto_attack(TRUE);
			weapon_thinkf(WFRAME_FIRE1, g_balance_porto_primary_animtime, weapon_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/portal.md3");
		precache_sound ("porto/bounce.wav");
		precache_sound ("porto/create.wav");
		precache_sound ("porto/expire.wav");
		precache_sound ("porto/explode.wav");
		precache_sound ("porto/fire.wav");
		precache_sound ("porto/unsupported.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_PORTO);
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE) {
		w_fragprefix = "^6TELE";
		w_deathtypestring = "was telefragged by";
	} else if (req == WR_RESETPLAYER)
	{
		self.porto_current_in = world;
		self.porto_current_out = world;
		self.portal_id = time;
	}
	else if (req == WR_CLEAR)
		weapon_porto_remove(self);
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_porto_primary_animtime);
		CACHE_CVAR(g_balance_porto_primary_lifetime);
		CACHE_CVAR(g_balance_porto_primary_refire);
		CACHE_CVAR(g_balance_porto_primary_speed);
		CACHE_CVAR(g_balance_powerup_strength_force);

		projectile_init(PROJECTILE_PORTO_RED);
		projectile_init(PROJECTILE_PORTO_BLUE);
	}
	return TRUE;
}
