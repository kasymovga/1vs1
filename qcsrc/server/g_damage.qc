float SP_BESTWEP;
.float dmg;
.float dmg_edge;
.float dmg_force;
.float dmg_radius;
.entity dmg_indicator;

float bot_taunt;
float bot_talk;
float g_score_bestweapon;
float g_balance_selfdamagepercent;
float g_friendlyfire;
float g_friendlyfire_force;
float g_mirrordamage;
float g_mirrorforce;
float g_teamdamage_threshold;
float g_throughfloor_damage;
float g_throughfloor_force;

float Damage_DamageInfo_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_DAMAGEINFO);
	WriteShort(MSG_ENTITY, self.projectiledeathtype);
	WriteCoord(MSG_ENTITY, floor(self.origin_x));
	WriteCoord(MSG_ENTITY, floor(self.origin_y));
	WriteCoord(MSG_ENTITY, floor(self.origin_z));
	WriteShort(MSG_ENTITY, self.oldorigin_x);
	WriteByte(MSG_ENTITY, self.team);
	return TRUE;
}

void Damage_DamageInfo(vector org, float coredamage, float edgedamage, float rad, vector force, float deathtype, entity dmgowner)
{
	// TODO maybe call this from non-edgedamage too?
	// TODO maybe make the client do the particle effects for the weapons and the impact sounds using this info?

	entity e;
	e = spawn();
	setorigin(e, org);
	e.projectiledeathtype = deathtype;
	e.oldorigin_x = compressShortVector(force);

	if(teamplay) {
		e.team = dmgowner.team;
	}

	Net_LinkEntity(e, FALSE, 0.2, Damage_DamageInfo_SendEntity);
}

#define DAMAGE_CENTERPRINT_SPACER NEWLINES

float checkrules_firstblood;

float yoda;
float damage_goodhits;
float damage_gooddamage;
float headshot;
float damage_headshotbonus; // bonus multiplier for head shots, set to 0 after use

.float dmg_team;
.float teamkill_complain;
.float teamkill_soundtime;
.entity teamkill_soundsource;
.entity pusher;
.float taunt_soundtime;
.float lastfrag;


float IsDifferentTeam(entity a, entity b)
{
	if(teamplay)
	{
		if(a.team == b.team)
			return 0;
	}
	else
	{
		if(a == b)
			return 0;
	}
	return 1;
}

void Damage (entity targ, entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	float mirrordamage;
	float mirrorforce;
	mirrordamage = 0;
	mirrorforce = 0;
	if (targ.flags & FL_GODMODE)
	if (deathtype != DEATH_HURTTRIGGER)
	if (deathtype != DEATH_TEAMCHANGE)
		damage = 0;

	if (gameover || targ.killcount == -666)
		return;

	local entity oldself;
	oldself = self;
	self = targ;

	// special rule: gravity bomb does not hit team mates (other than for disconnecting the hook)
	if(DEATH_ISWEAPON(deathtype, WEP_HOOK) || DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
		if(targ.classname == "player")
			if not(IsDifferentTeam(targ, attacker))
			{
				self = oldself;
				return;
			}
	}
	if(deathtype == DEATH_KILL || deathtype == DEATH_TEAMCHANGE || deathtype == DEATH_AUTOTEAMCHANGE)
	{
		// These are ALWAYS lethal
		// No damage modification here
		// Instead, prepare the victim for his death...
		targ.armorvalue = 0;
		targ.spawnshieldtime = 0;
		targ.health = 0.9; // this is < 1
		targ.flags -= targ.flags & FL_GODMODE;
		damage = 100000;
	}
	else if(deathtype == DEATH_MIRRORDAMAGE || deathtype == DEATH_NOAMMO)
	{
		// no processing
	}
	else
	{
		if(targ.classname == "player")
		{
			if(attacker.classname == "player" && targ != attacker && (IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(targ)))
			{
				damage = 0;
				force = '0 0 0';
			}
			else if(attacker.team == targ.team && !targ.saboteur)
			{
				if(attacker != targ)
				{
					if(teamplay)
					{
						if(targ.deadflag == DEAD_NO)
						{
							float teamdamage0 = max(attacker.dmg_team, g_teamdamage_threshold);
							attacker.dmg_team = attacker.dmg_team + damage;
							if(attacker.dmg_team > teamdamage0)
								mirrordamage = g_mirrordamage * (attacker.dmg_team - teamdamage0);
							mirrorforce = g_mirrorforce * vlen(force);
							damage = g_friendlyfire * damage;
							force = g_friendlyfire_force * force;
							// mirrordamage will be used LATER
						}
					}
				}
			}
		}
		if (targ == attacker)
			damage = damage * g_balance_selfdamagepercent;	// Partial damage if the attacker hits himself

		GameHook_DamageMod = GameHook_ForceMod = GameHook_MirrorDamageMod = GameHook_MirrorForceMod = 1;
		GameHookChain_DamageForceModsSet(targ, attacker, deathtype);
		damage = damage * GameHook_DamageMod;
		force = force * GameHook_ForceMod;
		mirrordamage = mirrordamage * GameHook_MirrorDamageMod;
		mirrorforce = mirrorforce * GameHook_MirrorForceMod;
		// count the damage
		if(attacker)
		if(!targ.deadflag)
		if(targ.takedamage == DAMAGE_AIM)
		if(targ != attacker)
		{
			if(targ.classname == "player")
			{
				// HEAD SHOT:
				// find height of hit on player axis
				// if above view_ofs and below maxs, and also in the middle half of the bbox, it is head shot
				vector headmins, headmaxs, org;
				org = targ.origin;
				headmins = org + '0.6 0 0' * targ.mins_x + '0 0.6 0' * targ.mins_y + '0 0 1' * (1.3 * targ.view_ofs_z - 0.3 * targ.maxs_z);
				headmaxs = org + '0.6 0 0' * targ.maxs_x + '0 0.6 0' * targ.maxs_y + '0 0 1' * targ.maxs_z;
				if(trace_hits_box(railgun_start, railgun_end, headmins, headmaxs))
				{
					deathtype |= HITTYPE_HEADSHOT;
				}
			}
			else if(targ.classname == "turret_head")
			{
				deathtype |= HITTYPE_HEADSHOT;
			}
			if(deathtype & HITTYPE_HEADSHOT)
				damage *= 1 + damage_headshotbonus;

			if(targ.classname == "player")
			{
				if(IsDifferentTeam(targ, attacker))
				{
					if(damage > 0)
					{
						if(targ.BUTTON_CHAT)
							attacker.typehitsound += 1;
						else
							attacker.hitsound += 1;

						damage_goodhits += 1;
						damage_gooddamage += damage;

						if not(DEATH_ISSPECIAL(deathtype))
						{
							if(IsFlying(targ))
								yoda = max(1, yoda);

							if(targ.items & IT_INVISIBILITY)
								yoda = 2;

							if(deathtype & HITTYPE_HEADSHOT)
								headshot = 1;
						}
					}
				}
				else
				{
					if(deathtype != DEATH_FIRE)
						attacker.typehitsound += 1;
					if(mirrordamage > 0)
						if(time > attacker.teamkill_complain)
						{
							attacker.teamkill_complain = time + 5;
							attacker.teamkill_soundtime = time + 0.4;
							attacker.teamkill_soundsource = targ;
						}
				}
			}
		}
	}

	// apply push
	if (self.damageforcescale)
	if (vlen(force))
	{
		self.velocity = self.velocity + self.damageforcescale * force;
		self.flags &~= FL_ONGROUND;
		UpdateCSQCProjectile(self);
	}
	// apply damage
	if (damage != 0 || (self.damageforcescale && vlen(force)))
	if (self.event_damage) {
		self.event_damage (inflictor, attacker, damage, deathtype, hitloc, force);
		self.lastdamage = time;
	}
	self = oldself;

	GameHookChain_DamageForceDone(targ, attacker, damage, force);
	// apply mirror damage if any
	if(mirrordamage > 0 || mirrorforce > 0)
	{
		force = normalize(attacker.origin + attacker.view_ofs - hitloc) * mirrorforce;
		if not(GameHookChain_MirrorDamageHandle(attacker, inflictor, mirrordamage, force)) {
			Damage(attacker, inflictor, attacker, mirrordamage, DEATH_MIRRORDAMAGE, attacker.origin, force);
		}
	}
}

vector NearestPointOnBox(entity box, vector org)
{
	vector m1, m2, nearest;

	m1 = box.mins + box.origin;
	m2 = box.maxs + box.origin;

	nearest_x = bound(m1_x, org_x, m2_x);
	nearest_y = bound(m1_y, org_y, m2_y);
	nearest_z = bound(m1_z, org_z, m2_z);

	return nearest;
}

.float actual_damage[WEP_COUNT]; //amount of damage done

void Damage_RecordFires(entity attacker, float deathtype, float shots)
{
	float weaponid;
	weaponid = DEATH_WEAPONOF(deathtype);
	if not(inWarmupStage)
	if(weaponid)
	{
		// Track damage done and update the stat to be sent later in g_world.qc
		float f = attacker.bullets_fired[weaponid] + shots;
		attacker.(bullets_fired[weaponid]) = f;
		attacker.maxdamage_fired = weaponid + 64 * rint(attacker.bullets_fired[weaponid]);
		entity s = attacker.scorekeeper;
		if (g_score_bestweapon)
		if (s) {
			float bestwep = s.scores[SP_BESTWEP] & 63;
			if (weaponid == bestwep) {
				f = rint(attacker.bullets_hit[weaponid] * 100 / f) * 64 + weaponid;
				scores_player_set(attacker, SP_BESTWEP, f);
			}
		}
	}
}

void Damage_RecordHits(entity attacker, entity targ, float deathtype, float hits, float damage)
{
	float weaponid;
	weaponid = DEATH_WEAPONOF(deathtype);
	if (targ.deadflag == DEAD_NO)
	if (targ.iscreature)
	if (targ != attacker)
	if (!teamplay || targ.team != attacker.team)
	if not(inWarmupStage)
	if(weaponid)
	{
		// Track damage done and update the stat to be sent later in g_world.qc
		float h = attacker.bullets_hit[weaponid] + hits;
		attacker.(bullets_hit[weaponid]) = h;
		float d = attacker.actual_damage[weaponid] + damage;
		attacker.(actual_damage[weaponid]) = d;
		entity s = attacker.scorekeeper;
		if (g_score_bestweapon)
		if (s) {
			float bestwep = s.scores[SP_BESTWEP] & 63;
			if (attacker.actual_damage[bestwep] <= d) {
				float f;
				f = rint(h * 100 / attacker.bullets_fired[weaponid]) * 64 + weaponid;
				scores_player_set(attacker, SP_BESTWEP, f);
			}
		}
		attacker.damage_hits = weaponid + 64 * rint(attacker.bullets_hit[weaponid]);
	}
}

void Damage_RecordInit() {
	CACHE_CVAR(g_score_bestweapon);
	if (g_score_bestweapon)
		SP_BESTWEP = scores_register_score("bestwep", 0);
}

float RadiusDamage_running;
void RadiusDamage (entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float deathtype, entity directhitentity)
// Returns total damage applies to creatures
{
	entity	targ;
	float	finaldmg;
	float	power;
	vector	blastorigin;
	vector	force;
	vector  diff;
	vector  center;
	vector  nearest;
	entity  next;
	if(RadiusDamage_running)
	{
		string save;
		print("RadiusDamage called recursively!\n");
		print("Expect stuff to go HORRIBLY wrong.\n");
		print("Causing a stack trace...\n");
		save = cvar_string("prvm_backtraceforwarnings");
		cvar_set("prvm_backtraceforwarnings", "1");
		fclose(-1); // calls VM_Warning
		cvar_set("prvm_backtraceforwarnings", save);
		return;
	}

	RadiusDamage_running = 1;

	blastorigin = (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5);

	if(deathtype != (WEP_HOOK | HITTYPE_SECONDARY | HITTYPE_BOUNCE)) // only send gravity bomb damage once
	{
		force = inflictor.velocity;
		if(vlen(force) == 0)
			force = '0 0 -1';
		else
			force = normalize(force);
		if(forceintensity >= 0)
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, rad, forceintensity * force, deathtype, attacker);
		else
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, -rad, (-forceintensity) * force, deathtype, attacker);
	}
	float record_damage = attacker.flags & FL_CLIENT;
	targ = WarpZone_FindRadius(blastorigin, rad, FALSE);
	while (targ)
	{
		next = targ.chain;
		if (targ != inflictor)
			if (ignore != targ) if(targ.takedamage)
			{
				// LordHavoc: measure distance to nearest point on target (not origin)
				// (this guarentees 100% damage on a touch impact)
				nearest = targ.WarpZone_findradius_nearest;
				diff = targ.WarpZone_findradius_dist;
				// round up a little on the damage to ensure full damage on impacts
				// and turn the distance into a fraction of the radius
				power = 1 - ((vlen (diff) - 2) / rad);
				//bprint(" ");
				//bprint(ftos(power));
				//if (targ == attacker)
				//	print(ftos(power), "\n");
				if (power > 0)
				{
					if (power > 1)
						power = 1;
					finaldmg = coredamage * power + edgedamage * (1 - power);
					if (finaldmg > 0)
					{
						local float a;
						local float c;
						local float hits;
						local float total;
						local float hitratio;
						local vector hitloc;
						center = targ.origin + (targ.mins + targ.maxs) * 0.5;
						// if it's a player, use the view origin as reference
						if (targ.classname == "player")
							center = targ.origin + targ.view_ofs;
						force = normalize(center - WarpZone_TransformOrigin(targ, blastorigin));
						force = force * (finaldmg / coredamage) * forceintensity;
						// test line of sight to multiple positions on box,
						// and do damage if any of them hit
						hits = 0;
						if (targ.classname == "player")
							total = ceil(bound(1, finaldmg, 10));
						else
							total = ceil(bound(1, finaldmg/10, 5));
						hitloc = nearest;
						c = 0;
						while (c < total)
						{
							WarpZone_TraceLine(blastorigin, WarpZone_UnTransformOrigin(targ, nearest), MOVE_NOMONSTERS, inflictor); //targ have .warpzone_transform from WarpZone_FindRadius
							if (trace_fraction == 1 || trace_ent == targ)
							{
								hits = hits + 1;
								if (hits > 1)
									hitloc = hitloc + nearest;
								else
									hitloc = nearest;
							}
							nearest_x = targ.origin_x + targ.mins_x + random() * targ.size_x;
							nearest_y = targ.origin_y + targ.mins_y + random() * targ.size_y;
							nearest_z = targ.origin_z + targ.mins_z + random() * targ.size_z;
							c = c + 1;
						}
						nearest = hitloc * (1 / max(1, hits));
						hitratio = (hits / total);
						a = bound(0, g_throughfloor_damage + (1-g_throughfloor_damage) * hitratio, 1);
						finaldmg = finaldmg * a;
						a = bound(0, g_throughfloor_force + (1-g_throughfloor_force) * hitratio, 1);
						force = force * a;
						if(hits || g_throughfloor_damage || g_throughfloor_force)
						{
							if (record_damage)
								Damage_RecordHits(attacker, targ, deathtype, 1, finaldmg);

							if(targ == directhitentity || DEATH_ISSPECIAL(deathtype))
								Damage (targ, inflictor, attacker, finaldmg, deathtype, nearest, force);
							else
								Damage (targ, inflictor, attacker, finaldmg, deathtype | HITTYPE_SPLASH, nearest, force);
						}
					}
				}
			}
		targ = next;
	}

	RadiusDamage_running = 0;
}

void Damage_ReadCvars()
{
	CACHE_CVAR(bot_taunt);
	CACHE_CVAR(bot_talk);
	CACHE_CVAR(g_friendlyfire);
	CACHE_CVAR(g_friendlyfire_force);
	CACHE_CVAR(g_mirrordamage);
	CACHE_CVAR(g_mirrorforce);
	CACHE_CVAR(g_teamdamage_threshold);
	CACHE_CVAR(g_throughfloor_damage);
	CACHE_CVAR(g_throughfloor_force);
	CACHE_CVAR(g_balance_selfdamagepercent);
}

.float heal_next_particle;
float Heal(entity targ, entity inflictor, entity healer, float heal, float aheal, float hlimit, float alimit, float healtype, float pauserot, float pausearot, vector hitloc, vector force) {

    if(targ.classname == "player") {
        if(hlimit)  hlimit = min(g_balance_health_limit, hlimit);
        else        hlimit = g_balance_health_limit;
        if(alimit)  alimit = min(g_balance_armor_limit,  alimit);
        else        alimit = g_balance_armor_limit;

    }
    if(pauserot  < 0) pauserot  = g_balance_pause_health_rot;
    if(pausearot < 0) pausearot = g_balance_pause_armor_rot;

	heal  = max(0, min(heal,  hlimit - targ.health));
	aheal = max(0, min(aheal, alimit - targ.armorvalue));

    targ.health += heal;
    targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);

    targ.armorvalue += aheal;
    targ.pauserotarmor_finished = max(targ.pauserotarmor_finished, time + pausearot);
    if(heal || aheal) {
		if(time > targ.heal_next_particle) {
			//te_heal(targ);
			targ.heal_next_particle = time + 0.2;
		}

		if(heal)  sound(targ, CHAN_AUTO, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);
		if(aheal) sound(targ, CHAN_AUTO, "misc/armor10.wav", VOL_BASE, ATTN_NORM);
    }

    // apply push
    if(targ.damageforcescale)
    if(vlen(force)) {
        targ.velocity = targ.velocity + targ.damageforcescale * force;
        targ.flags &~= FL_ONGROUND;
    }

    return heal + aheal;
}
