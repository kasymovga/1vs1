/*============================================

      Wazat's Nexuiz Grappling Hook

        Contact: Wazat1@gmail.com


Installation instructions:
--------------------------

1. Place hook.c in your gamec source directory with the other source files.

2. Add this line to the bottom of progs.src:

gamec/hook.c

3. Open defs.h and add these lines to the very bottom:

// Wazat's grappling hook
.entity		hook;
void GrapplingHookFrame();
void RemoveGrapplingHook(entity pl);
void SetGrappleHookBindings();
// hook impulses
float GRAPHOOK_FIRE		= 20;
float GRAPHOOK_RELEASE		= 21;
// (note: you can change the hook impulse #'s to whatever you please)

4. Open client.c and add this to the top of PutClientInServer():

	RemoveGrapplingHook(self); // Wazat's Grappling Hook

5. Find ClientConnect() (in client.c) and add these lines to the bottom:

	// Wazat's grappling hook
	SetGrappleHookBindings();

6. Still in client.c, find PlayerPreThink and add this line just above the call to W_WeaponFrame:

 	GrapplingHookFrame();

7. Build and test the mod.  You'll want to bind a key to "+hook" like this:
bind ctrl "+hook"

And you should be done!


============================================*/

float g_balance_grapplehook_airfriction;
float g_balance_grapplehook_break_damage;
float g_balance_grapplehook_damage;
float g_balance_grapplehook_damage_interval;
float g_balance_grapplehook_dontpull;
float g_balance_grapplehook_force_rubber;
float g_balance_grapplehook_force_rubber_overstretch;
float g_balance_grapplehook_gravity;
float g_balance_grapplehook_health;
float g_balance_grapplehook_length_min;
float g_balance_grapplehook_speed_fly;
float g_balance_grapplehook_speed_pull;
float g_balance_grapplehook_stretch;
float g_grappling_hook_tarzan;
vector hook_shotorigin;

.string aiment_classname;
.float aiment_deadflag;
.float hook_attack_time;

void SetMovetypeFollow(entity ent, entity e)
{
	ent.movetype = MOVETYPE_FOLLOW; // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid
	ent.aiment = e; // make the hole follow bmodel
	if (ent.aiment.takedamage)
		ent.hook_attack_time = time + g_balance_grapplehook_damage_interval;
	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = strzone(e.classname);
	ent.aiment_deadflag = e.deadflag;
}
#if 0
void UnsetMovetypeFollow(entity ent)
{
	ent.hook_attack_time = 0;
	ent.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment = world;
}
#endif
float LostMovetypeFollow(entity ent)
{
#if 0
	if(ent.movetype != MOVETYPE_FOLLOW)
		if(ent.aiment)
			error("???");
#endif
	if(ent.aiment)
	{
		if(ent.aiment.classname != ent.aiment_classname)
			return 1;
		if(ent.aiment.deadflag != ent.aiment_deadflag)
			return 1;
	}
	return 0;
}

.float hook_length;
.float hook_switchweapon;

void RemoveGrapplingHook(entity pl)
{
	if(pl.hook == world)
		return;
	remove(pl.hook.hook);
	remove(pl.hook);
	pl.hook = world;
	if(pl.movetype == MOVETYPE_FLY)
		pl.movetype = MOVETYPE_WALK;

	//pl.disableclientprediction = FALSE;
}

void GrapplingHookThink();
void GrapplingHook_Stop()
{
	pointparticles(particleeffectnum("grapple_impact"), self.origin, '0 0 0', 1);
	sound (self, CHAN_PROJECTILE, "weapons/hook_impact.wav", VOL_BASE, ATTN_NORM);

	self.state = 1;
	self.hook.think = GrapplingHookThink;
	self.hook.nextthink = time;
	self.touch = SUB_Null;
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.hook_length = -1;
}

float GrapplingHook_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_HOOK);
	WriteByte(MSG_ENTITY, sf);
	entity _hook = self.owner;
	if (sf & 1)
		WriteByte(MSG_ENTITY, num_for_edict(_hook.owner));

	vector v;
	if (sf & 2) {
		if(_hook.owner.weapon == WEP_HOOK) {
			entity oldself = self;
			self = _hook;
			v = shotorg_adjust('26 9 -16', TRUE, TRUE, FALSE);
			self = oldself;
		} else
			v = '8 -8 -12';

		WriteChar(MSG_ENTITY, v_x);
		WriteChar(MSG_ENTITY, v_y);
		WriteChar(MSG_ENTITY, v_z);
	}
	if (sf & 4) {
		v = _hook.pos1;
		WriteCoord(MSG_ENTITY, v_x);
		WriteCoord(MSG_ENTITY, v_y);
		WriteCoord(MSG_ENTITY, v_z);
	}
	if (sf & 8) {
		v = _hook.pos2;
		WriteCoord(MSG_ENTITY, v_x);
		WriteCoord(MSG_ENTITY, v_y);
		WriteCoord(MSG_ENTITY, v_z);
	}
	return TRUE;
}

void GrapplingHookThink()
{
	float spd, dist, newlength;
	vector dir, org, myorg, end, v, v0, dv;
	entity oldself = self;
	self = self.owner;
	if(PLAYER_DEAD(self.owner) || self.owner.hook != self)	// how did that happen?
	{														// well, better fix it anyway
		remove(self.hook);
		remove(self);
		self = oldself;
		return;
	}
	if(LostMovetypeFollow(self))
	{
		RemoveGrapplingHook(self.owner);
		self = oldself;
		return;
	}

    if(self.aiment)
        WarpZone_RefSys_AddIncrementally(self, self.aiment);

	self.hook.nextthink = time;

	makevectors(self.owner.v_angle);
	org = self.owner.origin + self.owner.view_ofs + v_forward * hook_shotorigin_x + v_right * hook_shotorigin_y + v_up * hook_shotorigin_z;
    myorg = WarpZone_RefSys_TransformOrigin(self.owner, self, org);

#if 0
	tracebox(org, self.mins, self.maxs, self.origin, MOVE_NOMONSTERS, self.owner);
	// do not hit players with this, as they tend to get in the way just too often
	// NOTE: this assumes sky brushes cannot get in the way
	// if they can, assume the map is broken! :P
	if(trace_fraction < 1 && (!self.aiment || trace_ent != self.aiment))
	{
		// 0. stop it
		if(self.state != 1)
			GrapplingHook_Stop();

		// 1. detach the hook
		if(self.aiment)
			UnsetMovetypeFollow(self);

		// 2. cut it off
		setorigin(self, trace_endpos);

		// 3. reattach the hook
		if(trace_ent)
			if(trace_ent.movetype != MOVETYPE_NONE)
				SetMovetypeFollow(self, trace_ent);
	}
#endif

	if(self.hook_length < 0)
		self.hook_length = vlen(myorg - self.origin);

	if(self.state == 1)
	{
		dir = self.origin - myorg;
		dist = vlen(dir);
		dir = normalize(dir);

		if (self.aiment) {
			if not(PlayerCanFire(self.owner, FALSE)) {
				RemoveGrapplingHook(self.owner);
				return;
			}
			if (g_balance_grapplehook_damage_interval)
			if (self.hook_attack_time)
			if (self.aiment.takedamage)
			while (self.hook_attack_time <= time)
			{
				Damage(self.aiment, self.owner, self.owner, g_balance_grapplehook_damage, WEP_HOOK, self.origin, '0 0 0');
				self.hook_attack_time += g_balance_grapplehook_damage_interval;
			}
			if not(self.aiment) {
				RemoveGrapplingHook(self.owner);
				return;
			}
		}
		if(g_grappling_hook_tarzan)
		{
			v = v0 = WarpZone_RefSys_TransformVelocity(self.owner, self, self.owner.velocity);

			// first pull the rope...
			if(self.owner.hook_state & HOOK_PULLING)
			{
				newlength = self.hook_length;
				newlength = max(newlength - g_balance_grapplehook_speed_pull * frametime, g_balance_grapplehook_length_min);

				if(newlength < dist - g_balance_grapplehook_stretch) // overstretched?
				{
					newlength = dist - g_balance_grapplehook_stretch;
					if(v * dir < 0) // only if not already moving in hook direction
						v = v + frametime * dir * g_balance_grapplehook_force_rubber_overstretch;
				}

				self.hook_length = newlength;
			}

			if(self.owner.hook_state & HOOK_RELEASING)
			{
				newlength = dist;
				self.hook_length = newlength;
			}
			else
			{
				// then pull the player
				spd = bound(0, (dist - self.hook_length) / g_balance_grapplehook_stretch, 1);
				if not(g_balance_grapplehook_dontpull) {
					v = v * (1 - frametime * g_balance_grapplehook_airfriction);
					v = v + frametime * dir * spd * g_balance_grapplehook_force_rubber;
					self.owner.flags &~= FL_ONGROUND;
				}

				dv = ((v - v0) * dir) * dir;
				if(g_grappling_hook_tarzan >= 2)
				{
					if(self.aiment.pushfactor)
					{
						self.owner.velocity = self.owner.velocity - dv * 0.5;
						self.aiment.velocity = self.aiment.velocity - dv * self.aiment.pushfactor;
						self.aiment.flags &~= FL_ONGROUND;
						self.aiment.pusher = self.owner;
						self.aiment.pushltime = time + g_maxpushtime;
					}
				}
			}
			self.owner.velocity = WarpZone_RefSys_TransformVelocity(self, self.owner, v);
		}
		else
		{
			end = self.origin - dir*50;
			dist = vlen(end - myorg);
			if(dist < 200)
				spd = dist * (g_balance_grapplehook_speed_pull / 200);
			else
				spd = g_balance_grapplehook_speed_pull;
			if(spd < 50)
				spd = 0;
			self.owner.velocity = dir*spd;
			self.owner.movetype = MOVETYPE_FLY;

			self.owner.flags &~= FL_ONGROUND;
		}
	}

	myorg = WarpZone_RefSys_TransformOrigin(self, self.owner, self.origin);
	vector a = WarpZone_RefSys_TransformAngles(self, self.owner, self.angles);
	makevectors(a_x * '-1 0 0' + a_y * '0 1 0');
	myorg = myorg + v_forward * (-9);
	if (myorg != self.pos1) {
		self.pos1 = myorg;
		self.hook.SendFlags |= 4;
	}
	if (org != self.pos2) {
		self.pos2 = org;
		self.hook.SendFlags |= 8;
	}
	if (self.owner.teleport_time == time)
		self.hook.SendFlags |= 28;

	self = oldself;
}

void GrapplingHookTouch (void)
{
	PROJECTILE_SKIPNONSOLID
	if(SUB_OwnerCheck())
		return;
	if(SUB_NoImpactCheck())
	{
		RemoveGrapplingHook(self.owner);
		return;
	}

	if(other == world)
	{
		vector tic;
		tic = self.velocity * sys_ticrate;
		tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
		traceline(self.origin - tic, self.origin + tic, MOVE_NORMAL, self);
		if(trace_fraction >= 1)
		{
			dprint("Odd... did not hit...?\n");
		}
		else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		{
			dprint("Detected and prevented the sky-grapple bug.\n");
			RemoveGrapplingHook(self.owner);
			return;
		}
	}

	GrapplingHook_Stop();

	if(other)
		if(other.movetype != MOVETYPE_NONE) {
			SetMovetypeFollow(self, other);
            WarpZone_RefSys_BeginAddingIncrementally(self, self.aiment);
		}

	//self.owner.disableclientprediction = TRUE;
}

void GrapplingHook_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health > 0)
	{
		float f;
		if (attacker == self.owner)
			f = g_balance_selfdamagepercent;
		else
			f = 1;

		self.health = self.health - damage * f;
		if (self.health <= 0)
		{
			if(attacker != self.owner)
			{
				self.owner.pusher = attacker;
				self.owner.pushltime = time + g_maxpushtime;
			}
			if (g_balance_grapplehook_break_damage)
			if (f)
				Damage(self.owner, inflictor, attacker, g_balance_grapplehook_break_damage * f, WEP_HOOK, self.owner.origin, '0 0 0');

			RemoveGrapplingHook(self.owner);
		}
	}
}

void FireGrapplingHook (void)
{
	local entity missile;
	local vector org;

	makevectors(self.v_angle);

	// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
	sound (self, CHAN_WEAPON2, "weapons/hook_fire.wav", VOL_BASE, ATTN_NORM);
	org = self.origin + self.view_ofs + v_forward * hook_shotorigin_x + v_right * hook_shotorigin_y + v_up * hook_shotorigin_z;
	pointparticles(particleeffectnum("grapple_muzzleflash"), org, '0 0 0', 1);

	missile = WarpZone_RefSys_SpawnSameRefSys(self);
	missile.owner = self;
	missile.hook = spawn();
	missile.hook.owner = missile;
	Net_LinkEntity(missile.hook, FALSE, 0, GrapplingHook_SendEntity);
	self.hook = missile;
	missile.classname = "grapplinghook";

	missile.movetype = (g_balance_grapplehook_gravity ? MOVETYPE_TOSS : MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);

	setmodel (missile, "models/hook.md3"); // precision set below
	setsize (missile, '-3 -3 -3', '3 3 3');
	setorigin (missile, org);

	missile.state = 0; // not latched onto anything

	missile.velocity = v_forward * g_balance_grapplehook_speed_fly;
	W_SetupProjectileVelocity(missile);

	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = GrapplingHookTouch;
	missile.hook.think = GrapplingHookThink;
	missile.hook.nextthink = time + 0.1;

	missile.effects = /*EF_FULLBRIGHT | EF_ADDITIVE |*/ EF_LOWPRECISION;

	missile.health = g_balance_grapplehook_health;//120
	missile.event_damage = GrapplingHook_Damage;
	missile.takedamage = DAMAGE_AIM;
	missile.damageforcescale = 0;

	entity oldself = self;
	self = missile.hook;
	GrapplingHookThink();
	self = oldself;
}

void GrapplingHookFrame()
{
	float button_hook = self.BUTTON_HOOK;
	if(g_grappling_hook && timeoutStatus != 2 && self.weapon != WEP_HOOK)
	{
		// offhand hook controls
		if(button_hook)
		{
			if not(self.hook || (self.hook_state & HOOK_WAITING_FOR_RELEASE))
			if (time > game_starttime)
			{
				self.hook_state |= HOOK_FIRING;
				self.hook_state |= HOOK_WAITING_FOR_RELEASE;
			}
		}
		else
		{
			self.hook_state |= HOOK_REMOVING;
			self.hook_state &~= HOOK_WAITING_FOR_RELEASE;
		}

		self.hook_state &~= HOOK_RELEASING;
		if(self.BUTTON_CROUCH)
		{
			self.hook_state &~= HOOK_PULLING;
			//self.hook_state |= HOOK_RELEASING;
		}
		else
		{
			self.hook_state |= HOOK_PULLING;
			//self.hook_state &~= HOOK_RELEASING;
		}
	}
	else if(!(self.items & IT_JETPACK) && !g_grappling_hook && self.switchweapon != WEP_HOOK)
	{
		if(button_hook && !self.hook_switchweapon)
			W_SwitchWeapon(WEP_HOOK);
	}
	self.hook_switchweapon = button_hook;

	if(!g_grappling_hook && self.weapon != WEP_HOOK)
	{
		self.hook_state &~= HOOK_FIRING;
		self.hook_state |= HOOK_REMOVING;
	}

	if (self.hook_state & HOOK_FIRING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		FireGrapplingHook();
		self.hook_state &~= HOOK_FIRING;
	}
	else if(self.hook_state & HOOK_REMOVING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		self.hook_state &~= HOOK_REMOVING;
	}
}

var void() GrappleHook_RealClientConnect_NextLink;
void GrappleHook_RealClientConnect(void) {
	// this function has been modified for Nexuiz
	// don't remove these lines! old server or demos coud overwrite the new aliases
	stuffcmd(self, "alias +hook +button6\n");
	stuffcmd(self, "alias -hook -button6\n");
	GrappleHook_RealClientConnect_NextLink();
}

var void(entity targ, entity attacker, float deathtype) GrappleHook_DamageForceModsSet_NextLink;
void GrappleHook_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if(targ.classname == "player")
		if(targ.hook) {
			if(targ.hook.aiment)
				if(targ.hook.aiment == attacker)
					RemoveGrapplingHook(targ); // STOP THAT, you parasite!

			if (targ.hook.state)
			if not(attacker)
			if (deathtype == DEATH_FALL) {
				GameHook_DamageMod = 0;
				GameHook_ForceMod = 0;
			}
		}

	GrappleHook_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

float GrappleHookInit_done;
void GrappleHookInit()
{
	if (GrappleHookInit_done)
		return;

	GrappleHookInit_done = TRUE;
	GrappleHook_RealClientConnect_NextLink = GameHookChain_RealClientConnect;
	GameHookChain_RealClientConnect = GrappleHook_RealClientConnect;
	GrappleHook_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = GrappleHook_DamageForceModsSet;
}

void GrappleHookReadCvars()
{
	CACHE_CVAR(g_balance_grapplehook_airfriction);
	CACHE_CVAR(g_balance_grapplehook_break_damage);
	CACHE_CVAR(g_balance_grapplehook_damage);
	CACHE_CVAR(g_balance_grapplehook_damage_interval);
	CACHE_CVAR(g_balance_grapplehook_dontpull);
	CACHE_CVAR(g_balance_grapplehook_force_rubber);
	CACHE_CVAR(g_balance_grapplehook_force_rubber_overstretch);
	CACHE_CVAR(g_balance_grapplehook_gravity);
	CACHE_CVAR(g_balance_grapplehook_health);
	CACHE_CVAR(g_balance_grapplehook_length_min);
	CACHE_CVAR(g_balance_grapplehook_speed_fly);
	CACHE_CVAR(g_balance_grapplehook_speed_pull);
	CACHE_CVAR(g_balance_grapplehook_stretch);
	CACHE_CVAR(g_grappling_hook_tarzan);
	CACHE_CVAR(g_grappling_hook);
	if (g_grappling_hook)
		GrappleHookInit();
}
