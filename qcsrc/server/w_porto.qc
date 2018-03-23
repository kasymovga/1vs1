// RED - INPUT
// BLUE - OUTPUT
float g_balance_porto_primary_animtime;
float g_balance_porto_primary_lifetime;
float g_balance_porto_primary_refire;
float g_balance_porto_primary_speed;
float g_balance_powerup_strength_force;

.entity porto_current_in;
.entity porto_current_out;
.vector porto_v_angle; // holds "held" view angles
.float porto_v_angle_held;
.vector right_vector;

void W_Porto_Success (void)
{
	if(self.owner == world)
	{
		objerror("Cannot succeed successfully: no owner\n");
		return;
	}

	if (self.effects & EF_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;
	remove(self);
}

void W_Porto_Fail ()
{
	if(self.owner == world)
	{
		objerror("Cannot fail successfully: no owner\n");
		return;
	}

	if (self.effects & EF_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;

	remove(self);
}

void W_Porto_Remove (entity p)
{
	entity oldself;
	oldself = self;
	if(p.porto_current_in)
	{
		self = p.porto_current_in;
		W_Porto_Fail();
	}
	if(p.porto_current_out)
	{
		self = p.porto_current_out;
		W_Porto_Fail();
	}
	self = oldself;
}

void W_Porto_Think (void)
{
	trace_plane_normal = '0 0 0';
	if(self.owner.playerid != self.playerid)
		remove(self);
	else
		W_Porto_Fail();
}

void W_Porto_Touch (void)
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
		spamsound(self, CHAN_PROJECTILE, "porto/bounce.wav", VOL_BASE, ATTN_NORM);
		// just reflect
		self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * trace_plane_normal);
		self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		W_Porto_Fail();
	}
	else if(self.effects & EF_RED)
	{
		if(Portal_SpawnInPortalAtTrace(self.owner, self.right_vector, self.owner.portal_id))
		{
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			centerprint(self.owner, "^1In^7-portal created.");
			W_Porto_Success();
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail();
		}
	}
	else
	{
		if(Portal_SpawnOutPortalAtTrace(self.owner, self.right_vector, self.owner.portal_id))
		{
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			centerprint(self.owner, "^4Out^7-portal created.");
			W_Porto_Success();
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			W_Porto_Fail();
		}
	}
}

void W_Porto_Attack (float out)
{
	local entity gren;

	W_SetupShot (self, FALSE, 4, "porto/fire.wav", 0);
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;

	//pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = CSQCProjectile(TRUE, PROJECTILE_PORTO_RED, TRUE);
	gren.owner = self;
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
	gren.think = W_Porto_Think;
	gren.touch = W_Porto_Touch;
	gren.velocity = w_shotdir * g_balance_porto_primary_speed;
	if(self.items & IT_STRENGTH)
		gren.velocity = gren.velocity * g_balance_powerup_strength_force;
	W_SetupProjectileVelocity(gren);

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

float w_porto(float req)
{
	vector v_angle_save;

	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if(bot_aim(g_balance_porto_primary_speed, 0, g_balance_porto_primary_lifetime, FALSE))
			self.BUTTON_ATCK = TRUE;
	}
	else if (req == WR_THINK)
	{
		if(self.porto_v_angle_held)
		{
			if(!self.BUTTON_ATCK2)
			{
				self.porto_v_angle_held = 0;

				ClientData_Touch(self);
			}
		}
		else
		{
			if(self.BUTTON_ATCK2)
			{
				self.porto_v_angle = self.v_angle;
				self.porto_v_angle_held = 1;

				ClientData_Touch(self);
			}
		}
		v_angle_save = self.v_angle;
		if(self.porto_v_angle_held)
			makevectors(self.porto_v_angle); // override the previously set angles

		if (self.BUTTON_ATCK)
		if (!self.porto_current_in)
		if (!self.porto_forbidden)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire))
		{
			W_Porto_Attack(FALSE);
			weapon_thinkf(WFRAME_FIRE1, g_balance_porto_primary_animtime, w_ready);
		}
		if (self.BUTTON_ATCK2)
		if (!self.porto_current_out)
		if (!self.porto_forbidden)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire))
		{
			W_Porto_Attack(TRUE);
			weapon_thinkf(WFRAME_FIRE1, g_balance_porto_primary_animtime, w_ready);
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
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "felt # doing the impossible to him";
	else if (req == WR_RESETPLAYER)
	{
		self.porto_current_in = world;
		self.porto_current_out = world;
		self.portal_id = time;
	}
	else if (req == WR_CLEAR)
		W_Porto_Remove(self);
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_porto_primary_animtime);
		CACHE_CVAR(g_balance_porto_primary_lifetime);
		CACHE_CVAR(g_balance_porto_primary_refire);
		CACHE_CVAR(g_balance_porto_primary_speed);
		CACHE_CVAR(g_balance_powerup_strength_force);

		CSQCProjectile_Init(PROJECTILE_PORTO_RED);
		CSQCProjectile_Init(PROJECTILE_PORTO_BLUE);
	}
	return TRUE;
};
