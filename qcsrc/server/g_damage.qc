.float dmg;
.float dmg_edge;
.float dmg_force;
.float dmg_radius;
.entity dmg_indicator;

float bot_taunt;
float bot_talk;
float g_score_bestweapon;
float g_balance_firetransfer_damage;
float g_balance_firetransfer_time;
float g_balance_selfdamagepercent;
float g_friendlyfire;
float g_friendlyfire_force;
float g_mirrordamage;
float g_mirrorforce;
float g_teamdamage_threshold;
float g_throughfloor_damage;
float g_throughfloor_force;
string sv_announcer_extra_meleefrag;
string sv_announcer_extra_doublekill;
float sv_announcer_extra_doublekill_interval;
string sv_announcer_extra_telefrag;
string sv_announcer_extra_firstblood;
string sv_announcer_extra_twohits; //used in w_nex.qc

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

void UpdateFrags(entity player, float f)
{
	PlayerTeamScore_AddScore(player, f);
}

// NOTE: f=0 means still count as a (positive) kill, but count no frags for it
void W_SwitchWeapon_Force(entity e, float w);
void GiveFrags (entity attacker, entity targ, float f)
{
	// TODO route through PlayerScores instead
	if(gameover) return;

	if(f < 0)
	{
		if(targ == attacker)
		{
			// suicide
			PlayerScore_Add(attacker, SP_SUICIDES, 1);
		}
		else
		{
			// teamkill
			PlayerScore_Add(attacker, SP_KILLS, -1); // or maybe add a teamkills field?
		}
	}
	else
	{
		// regular frag
		PlayerScore_Add(attacker, SP_KILLS, 1);
	}

	PlayerScore_Add(targ, SP_DEATHS, 1);

	f = GameHook_FragsHandle(attacker, targ, f);

	attacker.totalfrags += f;

	if(f)
		UpdateFrags(attacker, f);
}

void Bot_Say(entity source, float teamsay, entity privatesay, string msglist, string prefix);
void Obituary (entity attacker, entity inflictor, entity targ, float deathtype)
{
	string	s, a;
	float p, w;

	if (targ.classname == "player")
	{
		s = targ.netname;
		a = attacker.netname;

		w_fragprefix = "";
		if (targ == attacker)
		{
			if not(clienttype(attacker) == CLIENTTYPE_REAL)
				Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_suicide"), "");
			if (deathtype == DEATH_TEAMCHANGE) {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", ColoredTeamName(targ.team)));
			} else if (deathtype == DEATH_AUTOTEAMCHANGE) {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(targ.team)));
				return;
			} else if (deathtype == DEATH_NOAMMO) {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
			} else if (deathtype == DEATH_ROT) {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
			} else if (deathtype == DEATH_MIRRORDAMAGE) {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
			} else {
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
			}
			w = DEATH_WEAPONOF(deathtype);
			if(WEP_VALID(w))
			{
				w_deathtypestring = "couldn't resist the urge to self-destruct";
				w_deathtype = deathtype;
				weapon_action(w, WR_SUICIDEMESSAGE);
				bprint("^1", s, "^1 ", w_deathtypestring, "\n");
			}
			else if (deathtype == DEATH_KILL)
				bprint ("^1",s, "^1 couldn't take it anymore\n");
			else if (deathtype == DEATH_ROT)
				bprint ("^1",s, "^1 died\n");
			else if (deathtype == DEATH_NOAMMO)
				bprint ("^7",s, "^7 committed suicide. What's the point of living without ammo?\n");
			else if (deathtype == DEATH_MIRRORDAMAGE)
				bprint ("^1",s, "^1 didn't become friends with the Lord of Teamplay\n");
			else if (deathtype == DEATH_FIRE)
				bprint ("^1",s, "^1 burned to death\n");
			else if (deathtype != DEATH_TEAMCHANGE)
				bprint ("^1",s, "^1 couldn't resist the urge to self-destruct\n");

			if(deathtype != DEATH_TEAMCHANGE)
			{
				GiveFrags(attacker, targ, -1);
			}
			if (targ.killcount > 2)
				bprint ("^1",s,"^1 ended it all after a ",ftos(targ.killcount)," kill spree\n");
		}
		else if (attacker.classname == "player")
		{
			if not(clienttype(attacker) == CLIENTTYPE_REAL)
			{
				if (bot_talk)
				if (random() <= bot_talk)
				{
					if (teamplay && attacker.team == targ.team)
						Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_teamkill"), strcat(targ.netname, "^7: "));
					else
						Bot_Say(attacker, FALSE, world, cvar_string("bot_messages_frag"), strcat(targ.netname, "^7: "));
				}
				if (bot_taunt)
				if (random() <= bot_taunt)
				{
					local entity oldself;
					oldself = self;
					self = attacker;
					VoiceMessage("taunt", "");
					self = oldself;
				}
			}
			if not(clienttype(targ) == CLIENTTYPE_REAL)
			if (bot_talk)
			if (random() <= bot_talk)
			{
				if (teamplay && attacker.team == targ.team)
				{
					Bot_Say(targ, FALSE, world, cvar_string("bot_messages_teamkilled"), strcat(attacker.netname, "^7: "));
				}
				else
				{
					if (random() < 0.5)
						Bot_Say(targ, FALSE, world, cvar_string("bot_messages_fragged"), "");
					else
						Bot_Say(targ, FALSE, world, cvar_string("bot_messages_fragged_priv"), strcat(attacker.netname, "^7: "));
				}
			}
			if(teamplay && attacker.team == targ.team)
			{
				centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s, ", a team mate!"));
				bprint ("^1", a, "^1 mows down a team mate\n");
				GiveFrags(attacker, targ, -1);
				if (targ.killcount > 2) {
					bprint ("^1",s,"'s ^1",ftos(targ.killcount)," kill spree was ended by a team mate!\n");
				}
				if (attacker.killcount > 2) {
					bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," kill spree by killing a team mate\n");
				}
				attacker.killcount = 0;
			}
			else
			{
				string blood_message, victim_message;
				if (!checkrules_firstblood)
				{
					checkrules_firstblood = TRUE;
					bprint("^1",a, "^1 drew first blood", "\n");
					blood_message = "^1First blood\n";
					victim_message = "^1First victim\n";  // or First casualty
					if (sv_announcer_extra_firstblood != "")
						announce(attacker, sv_announcer_extra_firstblood);
				}


				w = DEATH_WEAPONOF(deathtype);
				if(WEP_VALID(w))
				{
					w_deathtypestring = "was blasted by";
					w_deathtype = deathtype;
					weapon_action(w, WR_KILLMESSAGE);
					p = strstrofs(w_deathtypestring, "#", 0);
					if(p < 0)
						bprint("^1", s, "^1 ", w_deathtypestring, " ", a, "\n");
					else
						bprint("^1", s, "^1 ", substring(w_deathtypestring, 0, p), a, "^1", substring(w_deathtypestring, p+1, strlen(w_deathtypestring) - (p+1)), "\n");
				}
				else if (deathtype == DEATH_DROWN)
					bprint ("^1",s, "^1 was drowned by ", a, "\n");
				else if (deathtype == DEATH_SLIME)
					bprint ("^1",s, "^1 was slimed by ", a, "\n");
				else if (deathtype == DEATH_LAVA)
					bprint ("^1",s, "^1 was cooked by ", a, "\n");
				else if (deathtype == DEATH_FALL)
					bprint ("^1",s, "^1 was grounded by ", a, "\n");
				else if (deathtype == DEATH_SWAMP)
					bprint ("^1",s, "^1 was conserved by ", a, "\n");
				else if (deathtype == DEATH_HURTTRIGGER && inflictor.message2 != "")
				{
					p = strstrofs(inflictor.message2, "#", 0);
					if(p < 0)
						bprint("^1", s, "^1 ", inflictor.message2, " ", a, "\n");
					else
						bprint("^1", s, "^1 ", substring(inflictor.message2, 0, p), a, "^1", substring(inflictor.message2, p+1, strlen(inflictor.message2) - (p+1)), "\n");
				}
				else if(deathtype == DEATH_TURRET)
					bprint ("^1",s, "^1 was pushed into the line of fire by ^1", a, "\n");
				else if (deathtype == DEATH_FIRE)
					bprint ("^1",s, "^1 was burnt to death by ^1", a, "\n");
				else
					bprint ("^1",s, "^1 was ", w_fragprefix, "^1fragged by ", a, "\n");

				GiveFrags(attacker, targ, 1);

				if (targ.killcount > 2) {
					bprint ("^1",s,"'s ^1", ftos(targ.killcount), " kill spree was ended by ", a, "\n");
				}

				attacker.killcount = attacker.killcount + 1;

				if (attacker.killcount > 2) {
					bprint ("^1",a,"^1 has ",ftos(attacker.killcount)," frags in a row\n");
				}
				float fragtime = time;

				if (attacker.killcount == 3)
				{
					bprint (a,"^7 made a ^1TRIPLE FRAG\n");
					announce(attacker, "announcer/male/03kills.wav");
				}
				else if (attacker.killcount == 5)
				{
					bprint (a,"^7 unleashes ^1RAGE\n");
					announce(attacker, "announcer/male/05kills.wav");
				}
				else if (attacker.killcount == 10)
				{
					bprint (a,"^7 starts the ^1MASSACRE!\n");
					announce(attacker, "announcer/male/10kills.wav");
				}
				else if (attacker.killcount == 15)
				{
					bprint (a,"^7 executes ^1MAYHEM!\n");
					announce(attacker, "announcer/male/15kills.wav");
				}
				else if (attacker.killcount == 20)
				{
					bprint (a,"^7 is a ^1BERSERKER!\n");
					announce(attacker, "announcer/male/20kills.wav");
				}
				else if (attacker.killcount == 25)
				{
					bprint (a,"^7 inflicts ^1CARNAGE!\n");
					announce(attacker, "announcer/male/25kills.wav");
				}
				else if (attacker.killcount == 30)
				{
					bprint (a,"^7 unleashes ^1ARMAGEDDON!\n");
					announce(attacker, "announcer/male/30kills.wav");
				}
				else if (time - attacker.lastfrag < sv_announcer_extra_doublekill_interval && attacker.lastfrag && sv_announcer_extra_doublekill != "")
				{
						if (announce(attacker, sv_announcer_extra_doublekill))
							fragtime = 0;
				}
				if (DEATH_ISWEAPON(deathtype, WEP_MELEE) && sv_announcer_extra_meleefrag != "")
				{
						announce(targ, sv_announcer_extra_meleefrag);
						announce(attacker, sv_announcer_extra_meleefrag);
				}
				centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ", w_fragprefix, "^4fragged ^7", s));
				centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ", w_fragprefix, "^1fragged by ^7", a));
				attacker.taunt_soundtime = time + 1;
				attacker.lastfrag = fragtime;
			}
		}
		else if (attacker.classname == "monster")
		{
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were fragged by ^7", attacker.netname));
			bprint ("^1",s, "^1 was killed by ", attacker.netname, "\n");
		}
		else
		{
			if not(clienttype(targ) == CLIENTTYPE_REAL)
			if (bot_talk)
			if (random() <= bot_talk)
				Bot_Say(targ, FALSE, world, cvar_string("bot_messages_suicide"), "");
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!"));
			if (deathtype == DEATH_HURTTRIGGER && inflictor.message != "")
				bprint ("^1",s, "^1 ", inflictor.message, "\n");
			else if (deathtype == DEATH_DROWN)
				bprint ("^1",s, "^1 drowned\n");
			else if (deathtype == DEATH_SLIME)
				bprint ("^1",s, "^1 was slimed\n");
			else if (deathtype == DEATH_LAVA)
				bprint ("^1",s, "^1 turned into hot slag\n");
			else if (deathtype == DEATH_FALL)
				bprint ("^1",s, "^1 hit the ground with a crunch\n");
			else if (deathtype == DEATH_SWAMP)
				bprint ("^1",s, "^1 is now conserved for centuries to come\n");
			else if(deathtype == DEATH_TURRET)
				bprint ("^1",s, "^1 was mowed down by a turret \n");
			else if(deathtype == DEATH_FIRE)
				bprint ("^1",s, "^1 burnt to death\n");
			else
				bprint ("^1",s, "^1 died\n");
			GiveFrags(targ, targ, -1);
			if(PlayerScore_Add(targ, SP_SCORE, 0) == -5) {
				announce(targ, "announcer/male/botlike.wav");
			}

			if (targ.killcount > 2)
				bprint ("^1",s,"^1 died with a ",ftos(targ.killcount)," kill spree\n");
		}
		targ.death_origin = targ.origin;
		if(targ != attacker)
			targ.killer_origin = attacker.origin;
		// FIXME: this should go in PutClientInServer
		if (targ.killcount)
			targ.killcount = 0;
	}
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

	if(targ.classname == "player")
		if(targ.hook)
			if(targ.hook.aiment)
				if(targ.hook.aiment == attacker)
					RemoveGrapplingHook(targ); // STOP THAT, you parasite!

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
			else if(attacker.team == targ.team)
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
				PlayerScore_Set(attacker, SP_BESTWEP, f);
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
				PlayerScore_Set(attacker, SP_BESTWEP, f);
			}
		}
		attacker.damage_hits = weaponid + 64 * rint(attacker.bullets_hit[weaponid]);
	}
}

void Damage_RecordInit() {
	CACHE_CVAR(g_score_bestweapon);
	if (g_score_bestweapon)
		ScoreInfo_SetLabel_PlayerScore(SP_BESTWEP, "bestwep", 0);
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
							WarpZone_TraceLine(blastorigin, WarpZone_UnTransformOrigin(targ, nearest), MOVE_NOMONSTERS, inflictor);
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

.float fire_damagepersec;
.float fire_endtime;
.float fire_deathtype;
.entity fire_owner;
.float fire_hitsound;
.entity fire_burner;

void fireburner_think();

float Fire_IsBurning(entity e)
{
	return (time < e.fire_endtime);
}

float Fire_AddDamage(entity e, entity o, float d, float t, float dt)
{
	float dps;
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;

	if(e.classname == "player")
	{
		if(e.deadflag)
			return -1;
	}
	else
	{
		if(!e.fire_burner)
		{
			// print("adding a fire burner to ", e.classname, "\n");
			e.fire_burner = spawn();
			e.fire_burner.classname = "fireburner";
			e.fire_burner.think = fireburner_think;
			e.fire_burner.nextthink = time;
			e.fire_burner.owner = e;
		}
	}

	t = max(t, 0.1);
	dps = d / t;
	if(Fire_IsBurning(e))
	{
		mintime = e.fire_endtime - time;
		maxtime = max(mintime, t);

		mindps = e.fire_damagepersec;
		maxdps = max(mindps, dps);

		if(maxtime > mintime || maxdps > mindps)
		{
			mindamage = mindps * mintime;
			maxdamage = mindamage + d;

			// interval [mintime, maxtime] * [mindps, maxdps]
			// intersected with
			// [mindamage, maxdamage]
			// maximum of this!

			if(maxdamage >= maxtime * maxdps)
			{
				totaltime = maxtime;
				totaldamage = maxtime * maxdps;

				// this branch increases totaldamage if either t > mintime, or dps > mindps
			}
			else
			{
				// maxdamage is inside the interval!
				// first, try to use mindps; only if this fails, increase dps as needed
				totaltime = min(maxdamage / mindps, maxtime); // maxdamage / mindps >= mindamage / mindps = mintime
				totaldamage = maxdamage;
				// can totaldamage / totaltime be >= maxdps?
				// max(mindps, maxdamage / maxtime) >= maxdps?
				// we know maxdamage < maxtime * maxdps
				// so it cannot be

				// this branch ALWAYS increases totaldamage, but requires maxdamage < maxtime * maxdps
			}

			// total conditions for increasing:
			//     maxtime > mintime OR maxdps > mindps OR maxtime * maxdps > maxdamage
			// however:
			//     if maxtime = mintime, maxdps = mindps
			// then:
			//     maxdamage = mindamage + d
			//     mindamage = mindps * mintime = maxdps * maxtime < maxdamage!
			// so the last condition is not needed

			e.fire_damagepersec = totaldamage / totaltime;
			e.fire_endtime = time + totaltime;
			if(totaldamage > 1.2 * mindamage)
			{
				e.fire_deathtype = dt;
				if(e.fire_owner != o)
				{
					e.fire_owner = o;
					e.fire_hitsound = FALSE;
				}
			}
			return max(0, totaldamage - mindamage); // can never be negative, but to make sure
		}
		else
			return 0;
	}
	else
	{
		e.fire_damagepersec = dps;
		e.fire_endtime = time + t;
		e.fire_deathtype = dt;
		e.fire_owner = o;
		e.fire_hitsound = FALSE;
		return d;
	}
}

void Fire_ApplyDamage(entity e)
{
	float t, d, hi, ty;

	if not(Fire_IsBurning(e))
		return;

	// water and slime stop fire
	if(e.waterlevel)
	if(e.watertype != CONTENT_LAVA)
		e.fire_endtime = 0;

	t = min(frametime, e.fire_endtime - time);
	d = e.fire_damagepersec * t;

	hi = e.fire_owner.hitsound;
	ty = e.fire_owner.typehitsound;
	Damage(e, e, e.fire_owner, d, e.fire_deathtype, e.origin, '0 0 0');
	if(e.fire_hitsound && e.fire_owner)
	{
		e.fire_owner.hitsound = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = TRUE;

	if not(IS_INDEPENDENT_PLAYER(e))
	FOR_EACH_PLAYER(other) if(e != other)
	{
		if(other.classname == "player")
		if(other.deadflag == DEAD_NO)
		if not(IS_INDEPENDENT_PLAYER(other))
		if(boxesoverlap(e.absmin, e.absmax, other.absmin, other.absmax))
		{
			t = g_balance_firetransfer_time * (e.fire_endtime - time);
			d = g_balance_firetransfer_damage * e.fire_damagepersec * t;
			Fire_AddDamage(other, e, d, t, DEATH_FIRE);
		}
	}
}

void Fire_ApplyEffect(entity e)
{
	if(Fire_IsBurning(e))
		e.effects |= EF_FLAME;
	else
		e.effects &~= EF_FLAME;
}

void fireburner_think()
{
	// for players, this is done in the regular loop
	if(wasfreed(self.owner))
	{
		remove(self);
		return;
	}
	Fire_ApplyEffect(self.owner);
	if(!Fire_IsBurning(self.owner))
	{
		self.owner.fire_burner = world;
		remove(self);
		return;
	}
	Fire_ApplyDamage(self.owner);
	self.nextthink = time;
}

#define EXTRA_ANNOUNCER(x) do { sv_announcer_extra_##x = strzone(cvar_string("sv_announcer_extra_"#x)); if (sv_announcer_extra_##x != "") { precache_sound(sv_announcer_extra_##x); print("Extra announcer sound "#x" ", sv_announcer_extra_##x, "\n");} } while (0)
void Damage_ReadCvars()
{
	CACHE_CVAR(bot_taunt);
	CACHE_CVAR(bot_talk);
	CACHE_CVAR(g_balance_firetransfer_damage);
	CACHE_CVAR(g_balance_firetransfer_time);
	CACHE_CVAR(g_friendlyfire);
	CACHE_CVAR(g_friendlyfire_force);
	CACHE_CVAR(g_mirrordamage);
	CACHE_CVAR(g_mirrorforce);
	CACHE_CVAR(g_teamdamage_threshold);
	CACHE_CVAR(g_throughfloor_damage);
	CACHE_CVAR(g_throughfloor_force);
	CACHE_CVAR(g_balance_selfdamagepercent);
	//Extra sounds
	EXTRA_ANNOUNCER(meleefrag);
	CACHE_CVAR(sv_announcer_extra_doublekill_interval);
	if (sv_announcer_extra_doublekill_interval) {
		EXTRA_ANNOUNCER(doublekill);
	}
	EXTRA_ANNOUNCER(twohits); //Used in w_nex.qc
	EXTRA_ANNOUNCER(telefrag);
	EXTRA_ANNOUNCER(firstblood);
}

.float heal_next_particle;
float Heal(entity targ, entity inflictor, entity healer, float heal, float aheal, float hlimit, float alimit, float healtype, float pauserot, float pausearot, vector hitloc, vector force) {

    if(targ.classname == "player") {
        if(hlimit)  hlimit = min(g_balance_health_limit, hlimit);
        else        hlimit = g_balance_health_limit;
        if(alimit)  alimit = min(g_balance_armor_limit,  alimit);
        else        alimit = g_balance_armor_limit;

#if 0
        if(g_clanarena) {
            hlimit = min(g_clanarena_start_health, hlimit);
            alimit = min(g_clanarena_start_armor,  alimit);

            if(healtype != DEATH_HURTTRIGGER)
            if(!(DEATH_HGTYPE(healtype) == HG_LINKER && healtype & HITTYPE_SECONDARY)) {
                float lim = g_clanarena_heal_limit;
                hlimit = min(hlimit, lim);
                alimit = min(alimit, lim);
            }
        }
#endif
    }

#if 0
    float silent = (healtype == DEATH_ITEM);
#endif

    if(pauserot  < 0) pauserot  = g_balance_pause_health_rot;
    if(pausearot < 0) pausearot = g_balance_pause_armor_rot;

	heal  = max(0, min(heal,  hlimit - targ.health));
	aheal = max(0, min(aheal, alimit - targ.armorvalue));

    targ.health += heal;
    targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);

    targ.armorvalue += aheal;
    targ.pauserotarmor_finished = max(targ.pauserotarmor_finished, time + pausearot);

#if 0
    if(targ.classname == "player")
        Buffs_ConduitDamage(targ, healer, heal, aheal, healtype, TRUE);
#endif

    if(heal || aheal) {
#if 0
        float vdtype = VDMG_TYPE_HEAL;

        if(heal >= 100 || aheal >= 100)
            vdtype |= VDMG_TYPE_CRIT;
        else if(DEATH_ISWEAPON(healtype, WEP_CAMPINGRIFLE) && (healtype & HITTYPE_HEADSHOT))
            vdtype |= VDMG_TYPE_CRIT;

        VisualDamage(healer, targ, heal, aheal, vdtype, hitloc);
        HealScore(targ, healer, heal + aheal);
#endif

#if 0
        if(!silent) {
#endif
            if(time > targ.heal_next_particle) {
                //te_heal(targ);
                targ.heal_next_particle = time + 0.2;
            }

            if(heal)  sound(targ, CHAN_AUTO, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);
            if(aheal) sound(targ, CHAN_AUTO, "misc/armor10.wav", VOL_BASE, ATTN_NORM);
#if 0
        }
#endif
    }

    // apply push
    if(targ.damageforcescale)
    if(vlen(force)) {
        targ.velocity = targ.velocity + targ.damageforcescale * force;
        targ.flags &~= FL_ONGROUND;
    }

    return heal + aheal;
}

void ArcEffect(vector from, vector to, float t) {
    // te_csqc_lightningarc(from, to, TRUE, t);
    // W_Zapper_Attack2_Effect(t, from, to);
    te_csqc_lightningarc(from, to);
}

void ArcDamage_Recurse(entity targ, entity attacker, float damage, float deathtype,
                       vector arcoffset, float range, float mul, float force, float default_color,
                       float targetTeamMates, float targetFrozen, float targetAlive, .float hitfield) {
    entity oldself = self;
    entity plr, newtarget;
    float dist, shortest;

    if(targetFrozen)
        damage = 1;
    else
        damage = damage * mul;

    if(damage < 1)
        return;

    newtarget = world;
    shortest = range;
    targ.hitfield = TRUE;

    FOR_EACH_PLAYER(plr)
    if(plr != attacker)
    if(plr != targ)
    if(plr.deadflag == DEAD_NO || (plr.deadflag == DEAD_FREEZE && targetFrozen))
    if(!plr.hg_stealth || (targetTeamMates && plr.team == attacker.team))
    if(!plr.hitfield) {
        float sameteam = (teamplay && plr.team == attacker.team);
        if((!sameteam && (((plr.deadflag != DEAD_FREEZE) && targetAlive) || ((plr.deadflag == DEAD_FREEZE) && targetFrozen))) || (sameteam && targetTeamMates)) {
            dist = vlen(plr.origin - targ.origin);
            if(dist < shortest) {
                traceline(targ.origin + arcoffset, plr.origin + arcoffset, MOVE_NORMAL, world);

                if(trace_fraction < 1 && trace_ent == plr) {
                    shortest = dist;
                    newtarget = plr;
                }
            }
        }
    }

    if(newtarget) {
        ArcEffect(targ.origin + arcoffset, newtarget.origin + arcoffset,
                  (targetTeamMates ? 0 : (teamplay ? attacker.team : default_color)));

        Damage(newtarget, attacker, attacker, damage, deathtype, '0 0 0',
               normalize(newtarget.origin - targ.origin) * force);

        ArcDamage_Recurse(newtarget, attacker, damage, deathtype, arcoffset, range, mul, force,
                          default_color, targetTeamMates, targetFrozen, targetAlive, hitfield);

        if(targetTeamMates)
            sound(newtarget, CHAN_PROJECTILE, "kh/capture.wav", 0.4, ATTN_NORM);
        else
            sound(newtarget, CHAN_PROJECTILE, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"),
                  VOL_BASE, ATTN_NORM * 0.3);
    }

    self = oldself;
}

void ArcDamage(entity targ, entity attacker, float damage, float deathtype,
               float range, float mul, float force, float default_color, .float hitfield) {

#if 0
    float targetTeamMates = (teamplay && Buffs_Present(attacker, BUFF_MEDIC) && targ.team == attacker.team);
#else
    float targetTeamMates = 0;
#endif

    if(teamplay && targ.team == attacker.team && !targetTeamMates)
        return;

    float targetFrozen = (targ.deadflag == DEAD_FREEZE) && !targetTeamMates;
    float targetAlive = !targetFrozen && !targetTeamMates;

    ArcDamage_Recurse(targ, attacker, damage, deathtype,
                      attacker.maxs_z * '0 0 0.5', range, mul, force, default_color,
                      targetTeamMates, targetFrozen, targetAlive, hitfield);

    entity e; for(e = world; (e = findfloat(e, hitfield, TRUE));)
        e.hitfield = FALSE;
}
