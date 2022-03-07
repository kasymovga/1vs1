float NADGET_ABILITY;
float g_nadgets;
float g_nadgets_detonate_on_death;
float g_nadgets_sentry_disown_on_death;
float g_nadgets_regen_compensate;
float g_nadgets_remove_on_death;
float g_nadgets_storage_limit_factor;
float g_nadgets_regen;
float g_nadgets_ammo;
float g_nadgets_regen_damagepause;
float g_nadgets_shield_damage_store_allow_cancel_discharge;
float g_nadgets_initial_regen;
float g_nadgets_drop_on_death;

void nadget_UpdateDetonables(void);
void nadget_ForceDetonateAll(void);

var void() nadget_PlayerPreThink_NextLink;
void nadget_PlayerPreThink();
var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) nadget_player_damage_handle_NextLink;
float nadget_player_damage_handle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force);

// Nadgets mutator
// Intended for the Camping Rifle Arena mode

var float(string cmd, float tokens) nadget_ClientCommandHandle_NextLink;
float nadget_ClientCommandHandle(string cmd, float tokens) {
	if(cmd == "picknade") {
		nadget_Pick(tokens);
		return TRUE;
	}
	return nadget_ClientCommandHandle_NextLink(cmd, tokens);
}

var float(entity plr, float wep) nadget_player_can_fire_NextLink;
float nadget_player_can_fire(entity plr, float wep) {
	if (self.hg_stealth)
		return FALSE;

	return nadget_player_can_fire_NextLink(plr, wep);
}

var void(void(string item, string cmd) Add_Item) nadget_gamemenu_send_NextLink;
void nadget_gamemenu_send(void(string item, string cmd) Add_Item) {
	Add_Item("Switch Nadget", "cmd picknade;");
	nadget_gamemenu_send_NextLink(Add_Item);
}

var void(float killed) nadget_PlayerClear_NextLink;
void nadget_PlayerClear(float killed) {
	if (killed) {
		if(g_nadgets_remove_on_death > 1)
			nadget_RemoveAll(self);

		if(self.hg_power > 0 && g_nadgets_drop_on_death) {
			nadget_SetContext(self.hg_altstate);
			self.hg_power = 0;
			nadget_Attack();
		}
		if(g_nadgets_detonate_on_death > 1)
			nadget_ForceDetonateAll();
	} else {
		if ((self.classname != "player" && self.team <= 0) || self.classname == "disconnecting") {
			nadget_RemoveAll(self);
			nadget_GenericProjectile_DetonateAll(self, TRUE);
		}
	}
	NADGET_DO_IN_ALL_CONTEXTS({
		if(self.hg_ctx_type_picked_nextround >= 0)
			self.hg_ctx_type_picked = self.hg_ctx_type_picked_nextround;
		self.hg_ctx_type_picked_nextround = -1;
	})
    self.hg_power = 0;
    self.hg_bonus = 0;
    self.hg_bonustype = NADGET_NORMAL;
    self.hg_shield = 0;
	self.hg_linker = world;
	if (self.classname == "player")
		NADGET_DO_IN_ALL_CONTEXTS(nadget_ResetAmmo(self, FALSE);)

    self.hg_shield = 0;
	self.hg_stealth = 0;
	self.hg_stealthalpha = 0;
    nadget_UpdateDetonables();
	nadget_PlayerClear_NextLink(killed);
}

var void() nadget_ObserverSpawn_Next;

void nadget_ObserverSpawn(void) {
    //self.hg_type1_picked = 0;
    //self.hg_type2_picked = 0;
    self.hg_next1 = 0;
    self.hg_next2 = 0;

    nadget_ObserverSpawn_Next();
}

var float() nadget_spectator_to_player_handle_NextLink;
float nadget_spectator_to_player_handle() {
	if (g_nadgets || (self.abilities & NADGET_ABILITY)) {
		if (nadget_ShowMenu(FALSE))
			return TRUE;
	}
	return nadget_spectator_to_player_handle_NextLink();
}

var float(entity plr) nadget_PlayerCanBeCarrier_NextLink;
float(entity plr) nadget_PlayerCanBeCarrier {
	if (nadget_PlayerCanBeCarrier_NextLink(plr))
	if not(plr.hg_stealth)
		return TRUE;

	return FALSE;
}

var void(entity plr) nadget_SpectateCopy_NextLink;
void(entity plr) nadget_SpectateCopy {
	self.hg_power = plr.hg_power;
	self.hg_type1 = plr.hg_type1;
	self.hg_type2 = plr.hg_type2;
	self.hg_next1 = plr.hg_next1;
	self.hg_next2 = plr.hg_next2;
	self.hg_ammo1 = plr.hg_ammo1;
	self.hg_ammo2 = plr.hg_ammo2;
	self.hg_regentime1 = plr.hg_regentime1;
	self.hg_regentime2 = plr.hg_regentime2;
	self.hg_maxregentime1 = plr.hg_maxregentime1;
	self.hg_maxregentime2 = plr.hg_maxregentime2;
	self.hg_regenpaused1 = plr.hg_regenpaused1;
	self.hg_regenpaused2 = plr.hg_regenpaused2;
	self.hg_regenrate1 = plr.hg_regenrate1;
	self.hg_regenrate2 = plr.hg_regenrate2;
	self.hg_bonus = plr.hg_bonus;
	self.hg_bonustype = plr.hg_bonustype;
	self.hg_detonables = plr.hg_detonables;
	self.hg_launchspeed = plr.hg_launchspeed;
	nadget_SpectateCopy_NextLink(plr);
}

var float() nadget_ThrowWeaponHandle_NextLink;
float nadget_ThrowWeaponHandle() {
	nadget_ThrowWeaponHandle_NextLink();
	nadget_Trigger();
	return TRUE;
}

float(.float hg_type_field, .float hg_ammo_field) nadget_bot_aim_nadget {
	float mt = GRENVAR(self.hg_type_field, "movetype");
	float _gravity = 0;
	if (mt == MOVETYPE_BOUNCE || mt == MOVETYPE_TOSS) {
		_gravity = GRENVAR(self.hg_type_field, "gravity");
	}
	if (self.hg_ammo_field > 0) {
		if (self.hg_type_field == NADGET_NORMAL || self.hg_type_field == NADGET_PLASMA ||
				self.hg_type_field == NADGET_LASER || self.hg_type_field == NADGET_TRANSLOC ||
				self.hg_type_field == NADGET_REMOTE || self.hg_type_field == NADGET_RAZE) {
			self.hg_launchspeed = GRENVAR(self.hg_type_field, "launchspeed");
			if (self.hg_launchspeed) {
				if(bot_aim((GRENVAR(self.hg_type_field, "speed_min") + GRENVAR(self.hg_type_field, "speed")) * 0.25, GRENVAR(self.hg_type_field, "speed_up") * 0.5, GRENVAR(self.hg_type_field, "lifetime"), _gravity)) {
					self.hg_power = 0.5;
					return TRUE;
				}
			} else {
				if(bot_aim(GRENVAR(self.hg_type_field, "speed"), GRENVAR(self.hg_type_field, "speed_up"), GRENVAR(self.hg_type_field, "lifetime"), _gravity)) {
					self.hg_power = 0.5;
					return TRUE;
				}
			}
		} else if (self.hg_type_field == NADGET_CLOAK) {
			self.hg_power = 0.5;
			return TRUE;
		} else {
			if(bot_aim(2000, 0, 0.5, 0)) { //Enemy close
				self.hg_power = 0.5;
				if (self.hg_type_field == NADGET_LINKER)
					bot_stay(self, 0.5);

				return TRUE;
			}
		}
	} else if (self.hg_type_field == NADGET_LINKER) {
		if (self.hg_linker)
		if (random() > 0.5)
			bot_stay(self, 0);
	}
	if (self.hg_type_field == NADGET_CLOAK)
	if (self.hg_stealth) {
		return TRUE;
	}
	if (self.hg_type_field == NADGET_SHIELD)
	if (self.hg_shield)
	if (self.hg_shield_stored > g_nadgets_shield_damage_store_base + (g_nadgets_shield_damage_store_limit - g_nadgets_shield_damage_store_base) * 0.75)
		nadget_Trigger();

	return FALSE;
}

var float(void) nadget_bot_aim_next;
float(void) nadget_bot_aim {
	if (nadget_bot_aim_nadget(hg_type1, hg_ammo1))
		return TRUE;

	if (nadget_bot_aim_nadget(hg_type2, hg_ammo2)) {
		self.hg_altstate = 1;
		return TRUE;
	}
	return nadget_bot_aim_next();
}

var float(float deathtype, entity targ, entity inflictor, entity attacker) nadget_player_obituary_frag_next;
float(float deathtype, entity targ, entity inflictor, entity attacker) nadget_player_obituary_frag {
	if (DEATH_ISNADGET(deathtype)) {
		weapon_fragprefix = "^5NADGET";
		bprint ("^1", targ.netname, "^1 was nadefragged by ", attacker.netname, "\n");
		return TRUE;
	}
	return nadget_player_obituary_frag_next(deathtype, targ, inflictor, attacker);
}

float nadget_init_done;
void(void) nadget_init_common {
	if (nadget_init_done)
		return;

	nadget_init_done = TRUE;
	CVAR_CACHE(g_nadgets_double);
	CVAR_CACHE(g_nadgets_detonate_on_death);
	CVAR_CACHE(g_nadgets_sentry_disown_on_death);
	CVAR_CACHE(g_nadgets_regen_compensate);
	CVAR_CACHE(g_nadgets_remove_on_death);
	CVAR_CACHE(g_nadgets_storage_limit_factor);
	CVAR_CACHE(g_nadgets_regen);
	CVAR_CACHE(g_nadgets_regen_damagepause);
	CVAR_CACHE(g_nadgets_shield_damage_store_allow_cancel_discharge);
	CVAR_CACHE(g_nadgets_ammo);
	CVAR_CACHE(g_nadgets_initial_regen);
	CVAR_CACHE(g_nadgets_drop_on_death);
	addstat(STAT_HGFORCE, STAT_FLOAT, hg_power);
	addstat(STAT_HGAMMO, STAT_INT, hg_ammo1);
	addstat(STAT_HGREGEN, STAT_FLOAT, hg_regentime1);
	addstat(STAT_HGREGENMAX, STAT_FLOAT, hg_maxregentime1);
	addstat(STAT_HGREGENPAUSED, STAT_INT, hg_regenpaused1);
	addstat(STAT_HGREGENRATE, STAT_FLOAT, hg_regenrate1);
	addstat(STAT_HGDETONABLES, STAT_INT, hg_detonables);
	addstat(STAT_HGLAUNCH, STAT_FLOAT, hg_launchspeed);
	addstat(STAT_HGTYPE, STAT_INT, hg_type1);
	addstat(STAT_HGBONUS, STAT_INT, hg_bonus);
	addstat(STAT_HGBONUSTYPE, STAT_INT, hg_bonustype);
	addstat(STAT_HGREFIRE, STAT_FLOAT, hg_next1);
	nadget_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = nadget_PlayerClear;
	nadget_player_can_fire_NextLink = gamehook_chain_player_can_fire;
	gamehook_chain_player_can_fire = nadget_player_can_fire;
	nadget_gamemenu_send_NextLink = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = nadget_gamemenu_send;
	nadget_ClientCommandHandle_NextLink = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = nadget_ClientCommandHandle;
	nadget_player_damage_handle_NextLink = gamehook_chain_player_damage_handle;
	gamehook_chain_player_damage_handle = nadget_player_damage_handle;
	nadget_spectator_to_player_handle_NextLink = gamehook_chain_spectator_to_player_handle;
	gamehook_chain_spectator_to_player_handle = nadget_spectator_to_player_handle;
	nadget_PlayerCanBeCarrier_NextLink = gamehook_chain_PlayerCanBeCarrier;
	gamehook_chain_PlayerCanBeCarrier = nadget_PlayerCanBeCarrier;
	nadget_SpectateCopy_NextLink = gamehook_chain_spectator_copy;
	gamehook_chain_spectator_copy = nadget_SpectateCopy;
	nadget_bot_aim_next = gamehook_chain_bot_aim;
	gamehook_chain_bot_aim = nadget_bot_aim;
	nadget_player_obituary_frag_next = gamehook_chain_player_obituary_frag;
	gamehook_chain_player_obituary_frag = nadget_player_obituary_frag;
	if (g_nadgets_double) {
		addstat(STAT_HGTYPE2, STAT_INT, hg_type2);
		addstat(STAT_HGREFIRE2, STAT_FLOAT, hg_next2);
		addstat(STAT_HGAMMO2, STAT_INT, hg_ammo2);
		addstat(STAT_HGREGEN2, STAT_FLOAT, hg_regentime2);
		addstat(STAT_HGREGENMAX2, STAT_FLOAT, hg_maxregentime2);
		addstat(STAT_HGREGENPAUSED2, STAT_INT, hg_regenpaused2);
		addstat(STAT_HGREGENRATE2, STAT_FLOAT, hg_regenrate2);
	}
	CVAR_CACHE(g_nadgets_detonatelaunches);
	#define NADGETDEF(id,shortname,longname,color) nadget_Hook_Init_##shortname();
	NADGETDEFS
	#undef NADGETDEF
	nadget_precache();
	projectile_register_auto(PROJECTILE_HG_GENERIC, NADGET_SIZE_DEFAULT * '1 -1 1', GRENVAR(NADGET_NORMAL, "movetype"));
	projectile_register_auto(PROJECTILE_HG_LASER, NADGET_SIZE_DEFAULT * '1 -1 1', GRENVAR(NADGET_LASER, "movetype"));
	projectile_register_auto(PROJECTILE_HG_NAPALM, NADGET_SIZE_DEFAULT * '1 -1 1', GRENVAR(NADGET_NAPALM, "movetype"));
	projectile_register_auto(PROJECTILE_HG_PLASMA, NADGET_SIZE_DEFAULT * '1 -1 1', GRENVAR(NADGET_PLASMA, "movetype"));
	projectile_register_auto(PROJECTILE_HG_REMOTE, NADGET_SIZE_DEFAULT * '1 -1 1', GRENVAR(NADGET_REMOTE, "movetype"));
	projectile_register_auto(PROJECTILE_HG_TRANSLOC, NADGET_SIZE_TRANSLOC * '1 -1 1', GRENVAR(NADGET_TRANSLOC, "movetype"));
	projectile_register_auto(PROJECTILE_HG_RAZE, '16 -3 3', GRENVAR(NADGET_RAZE, "movetype"));
	projectile_register_auto(PROJECTILE_HG_PLASMA_SHARD, '0 -3 -3', MOVETYPE_BOUNCE);
	nadget_ObserverSpawn_Next = gamehook_chain_observer_spawn;
	gamehook_chain_observer_spawn = nadget_ObserverSpawn;
	nadget_PlayerPreThink_NextLink = gamehook_chain_player_think;
	gamehook_chain_player_think = nadget_PlayerPreThink;
	nadget_ThrowWeaponHandle_NextLink = gamehook_chain_ThrowWeaponHandle;
	gamehook_chain_ThrowWeaponHandle = nadget_ThrowWeaponHandle;
	Napalm_Init();
	hint_add("You can detonate FireTrap of enemy shooting on it");
	hint_add("Translocator nadget can be used as teleporting or killing enemy shooting directly on enemy");
	hint_add("You can increase speed using laser nadget, you can jump higher with laser nadget aiming to ground or wall with laser nadget");
	hint_add("When enemy stand close to FireTrap you will see red indicator indicating");
}

void(entity e, string args) nadget_ability_init {
	if (e) {
		if (e.abilities & NADGET_ABILITY) {
			if not(e.hg_type1) {
				entity oldself = self;;
				self = e;
				if not(nadget_ShowMenu(0))
					nadget_ResetAmmo(self, FALSE);

				self = oldself;
			}
		} else {
			nadget_RemoveAll(e);
			e.hg_type1 = 0;
			e.hg_type2 = 0;
		}
	} else
		nadget_init_common();
}

void(void) nadget_init {
	CVAR_CACHE(g_nadgets);
	if (!g_nadgets)
		NADGET_ABILITY = ability_register("nadget", nadget_ability_init);

	if not(g_nadgets)
		return;

	nadget_init_common();
}

void nadget_precache(void) {
	heal_init();
	dlc_require("rm_effects_v2");
	dlc_require("rm_laser");
	dlc_require("rm_arc");
	dlc_require("pryaxe_balls");
	dlc_require("nadgets");
	precache_model("models/ctf/shield.md3");
	precache_model("models/rtzsentry.iqm");
	precache_model("models/ebomb.mdl");
	precache_sound("kh/alarm.wav");
	precache_sound("weapons/grenade_bounce1.wav");
	precache_sound("weapons/grenade_bounce2.wav");
	precache_sound("weapons/grenade_bounce3.wav");
	precache_sound("weapons/grenade_bounce4.wav");
	precache_sound("weapons/grenade_bounce5.wav");
	precache_sound("weapons/grenade_bounce6.wav");
	precache_sound("weapons/grenade_fire.wav");
	precache_sound("weapons/electro_bounce.wav");
	precache_sound("weapons/rocket_mode.wav");
	precache_sound("weapons/nexfire.wav");
	precache_sound("weapons/electro_fire2.wav");
	precache_sound("weapons/electro_fly.wav");
	precache_sound("porto/expire.wav");
	precache_sound("porto/bounce.wav");
	precache_sound("misc/powerup_shield.wav");
	precache_sound("misc/powerup.wav");
	precache_sound("kh/capture.wav");
	dlc_precache_sound("misc/gg.wav");
	dlc_precache_sound("misc/stealth.wav");
	dlc_precache_sound("misc/unstealth.wav");
	dlc_precache_sound(RM_SOUND_LASER_PRIMARY);
	dlc_precache_sound(RM_SOUND_LASER_SECONDARY);
	dlc_precache_sound("weapons/grenade_stick.wav");
	dlc_precache_sound("weapons/rm_nadebeep.wav");
	dlc_precache_sound("misc/arc1.wav");
	dlc_precache_sound("misc/arc2.wav");
}

void nadget_SetContext(float isalt) {
    hg_context_isaltintended = isalt;

    if(!g_nadgets_double)
        isalt = FALSE;

    if(isalt) {
        hg_ctx_next = hg_next2;
        hg_ctx_ammo = hg_ammo2;
        hg_ctx_type = hg_type2;
        hg_ctx_type_picked = hg_type2_picked;
        hg_ctx_type_picked_nextround = hg_type2_picked_nextround;
        hg_ctx_regentime = hg_regentime2;
        hg_ctx_maxregentime = hg_maxregentime2;
        hg_ctx_regenrate = hg_regenrate2;
        hg_ctx_regenpaused = hg_regenpaused2;
    } else {
        hg_ctx_next = hg_next1;
        hg_ctx_ammo = hg_ammo1;
        hg_ctx_type = hg_type1;
        hg_ctx_type_picked = hg_type1_picked;
        hg_ctx_type_picked_nextround = hg_type1_picked_nextround;
        hg_ctx_regentime = hg_regentime1;
        hg_ctx_maxregentime = hg_maxregentime1;
        hg_ctx_regenrate = hg_regenrate1;
        hg_ctx_regenpaused = hg_regenpaused1;
    }

    hg_context_isalt = isalt;
}

void nadget_GiveBonus(entity p, float hgtype, float amount, string reason, float allowOptout) {
    if((allowOptout && p.hg_optout))
        return;

    amount *= GRENVAR(hgtype, "bonus_amount_multiplier") /* * Buffs_NadgetBonusMultiplier(p) */;

    if(amount < 1)
        return;

    if(p.hg_bonustype != hgtype)
        p.hg_bonus = 0;

	p.hg_bonus += amount;
	p.hg_bonustype = hgtype;
    p.hg_bonus_next = 0;

	string n = nadget_TypeToExpandedName(hgtype);
	entity e;

	FOR_EACH_REALCLIENT(e) if(e.iscreature || e.classname == "spectator") {
        entity check = e;
        if(!e.iscreature)
            check = e.enemy;

        if(check == p)
            //bigprint(e, strcat("^7You got a ^3", n, "^7 bonus!"), reason, 3);
            centerprint(e, strcat("^7You got a ^3", n, "^7 bonus!", "\n", reason));
        else if(team_is_different_teams(check, p))
            //bigprint(e, strcat("^3Enemy got a ^1", n, " ^3bonus!"), strcat("Given to ^3", p.netname, " ^7(", reason, ")"), 3);
            centerprint(e, strcat("^3Enemy got a ^1", n, " ^3bonus!\nGiven to ^3", p.netname, " ^7(", reason, ")"));
        else
            centerprint(e, strcat("^3", p.netname, "^7 got a ^3", n, " ^7bonus (", reason, ")"));
    }

	bprint(strcat("^3", p.netname, " ^7got a ^3", n, "^7 bonus (", reason, ")\n"));
    sound_play2all("kh/alarm.wav");
}

void nadget_GiveRandomBonus(entity p, float amount, string reason, float allowOptout) {
    if((allowOptout && p.hg_optout))
        return;

    random_selection_init();

    float n;
    for(n = NADGET_START; n <= NADGET_END; ++n) {
        //if(g_freeze || (n != NADGET_BAIT)) {
            float w = GRENVAR(n, "bonus_random_weight");
            if(w)
                random_selection_add(world, n, "", w, 1);
        //}
    }

    if(random_selection_chosen_float)
        nadget_GiveBonus(p, random_selection_chosen_float, amount, reason, allowOptout);
}

float nadget_RegenTime(entity e) {
    float base      = GRENVAR(e.hg_ctx_type, "regen_time");
    float exponent  = GRENVAR(e.hg_ctx_type, "regen_exponent");
    float factor    = GRENVAR(e.hg_ctx_type, "regen_factor");

    return base * (1 + pow(e.hg_ctx_ammo, exponent) * factor);
}

void nadget_SetRegenTime(entity e, float t) {
    e.hg_ctx_regentime = t;
    e.hg_ctx_maxregentime = t;
}

float nadget_PlayerMayDetonate(entity p) {
    if(g_nadgets_detonate_on_death)
        return TRUE;
    return PLAYER_REALLY_ALIVE(p);
}

void nadget_RemoveAll(entity plr) {
    entity n;
	string c;
    for (n = nextent(world); n; n = nextent(n)) {
		c = n.classname;
        if ((c == "hg_generic_projectile")  ||
               (c == "hg_plasma")   ||
               (c == "hg_napalm")   ||
               (c == "hg_linker")   ||
               ((c == "hg_sentry") &&(!g_nadgets_sentry_disown_on_death)))
        if((n.realowner && n.realowner == plr) || n.owner == plr)
            nadget_FadeOut(n);
    }
}

float nadget_PlayerNadgetType(entity e) {
    float picked = nadget_NameToType(cvar_string("g_nadgets_type"));
    float argc = tokenize_console(nadget_SelectableTypes(hg_context_isalt));
    float i;

    if(argc) {
		picked = NADGET_RANDOM;
		for(i = 0; i < argc; ++i)
			if(e.hg_ctx_type_picked == nadget_NameToType(argv(i))) {
				picked = e.hg_ctx_type_picked;
				break;
			}
	}
    if(picked == NADGET_RANDOM) {
        random_selection_init();
        float n; for(i = 0; i < argc; ++i) {
            n = nadget_NameToType(argv(i));
            if(n != NADGET_RANDOM && (!hg_context_isalt || n != e.hg_type1_picked))
                random_selection_add(world, n, "", 1, 0);
        }
        picked = random_selection_chosen_float;
    }
	if (picked == NADGET_RANDOM)
		picked = NADGET_NORMAL;

    e.hg_ctx_type_picked = picked;
    return e.hg_ctx_type_picked;
}

void nadget_SetNadgetType(entity p, float t) {
    p.hg_ctx_type = t;

#if 0
    if(p.scorekeeper) {
        float s = p.scorekeeper.(scores[SP_STATUSICONS]) & 0xFFFFFF00;
        PlayerScore_Set(p, SP_STATUSICONS, s + nadget_CompressDualType(p.hg_type1, p.hg_type2) & 0x000000FF);
    }
#endif
}

void nadget_FadeOut_Think(void) {
	self.alpha = approach(self.alpha, 0, frametime);
	if (self.classname == "hg_linker")
		self.enemy.alpha = self.alpha * 0.5;

	if (!self.alpha) {
		if (self.classname == "hg_linker") {
			if (self.enemy);
				remove(self.enemy);

			remove(self);
		} else
			nadget_GenericProjectile_Remove();

		return;
	}
	self.nextthink = time;
}

void nadget_FadeOut(entity n) {
    if(n.classname == "hg_sentry") {
        entity o = self;
        self = n;
        nadget_Sentry_Explode();
        self = o;
        return;
    }

    if(n.hg_waypoint)
        WaypointSprite_Disown(n.hg_waypoint, 0.5);

    if(n.hg_detonable_updated && n.owner)
        n.owner.hg_detonables -= 1;

    if(!n.alpha)
        n.alpha = 1;

    n.solid = SOLID_NOT;
    n.takedamage = DAMAGE_NO;
    n.hg_detonable_updated = FALSE;
    n.event_damage = NULL;
    n.use = NULL;
    n.think = nadget_FadeOut_Think;
    n.nextthink = time;
}

void nadget_SetCooldown(.float cdfield, float gcd, float cd) {
#if 0
    float cdmul = Buffs_NadgetCooldown(self);
    gcd *= cdmul;
    cd *= cdmul;
#endif

    self.hg_next1 = max(self.hg_next1, time + gcd);
    self.hg_next2 = max(self.hg_next2, time + gcd);
    self.hg_bonus_next = max(self.hg_bonus_next, time + gcd);
    self.cdfield = max(self.cdfield, time + cd);
}

float nadget_Attack_CallHook(float hgtype) {
    switch(hgtype) {
        #define NADGETDEF(id,shortname,longname,color) case id: return nadget_Hook_Attack_##shortname();
        NADGETDEFS
        #undef NADGETDEF
    }
	return -1;
}

void nadget_Attack(void) {
    if(self.deadflag != DEAD_NO)
        return;

    float hgtype;

    hg_ammo_used = 1;
    hg_ammo_available = 0;

    float n_bonus;
    var .float cdfield;

    if(hg_context_isaltintended)
        n_bonus = 0;
    else
        n_bonus = self.hg_bonus;

    if(n_bonus) {
        hgtype = self.hg_bonustype;
        hg_ammo_available = self.hg_bonus;
        cdfield = hg_bonus_next;
    } else {
        hgtype = self.hg_ctx_type;
        hg_ammo_available = self.hg_ctx_ammo;
        cdfield = hg_ctx_next;
    }

    if(time < self.cdfield)
        return;

    if(!n_bonus && !self.hg_ctx_ammo)
        return;

    switch(nadget_Attack_CallHook(hgtype)) {
        case NADGET_ATTACK_OK:
            break;
        case NADGET_ATTACK_FAIL_COOLDOWN: // fallthrough
            self.cdfield = time + 1;
        case NADGET_ATTACK_FAIL:
            return;
        default:
            error(strcat(nadget_TypeToExpandedName(hgtype), " s (", ftos(hgtype), ") attack function returned an invalid result\n"));
            return;
    }

    nadget_SetCooldown(cdfield, GRENVAR(hgtype, "global_cooldown"), GRENVAR(hgtype, "cooldown"));

    if(n_bonus) {
        self.hg_bonus -= hg_ammo_used;
    } else {
        if(g_nadgets_regen_compensate) {
            float oregen = nadget_RegenTime(self);
            self.hg_ctx_ammo -= hg_ammo_used;
            self.hg_ctx_maxregentime = nadget_RegenTime(self);
            self.hg_ctx_regentime = self.hg_ctx_regentime - oregen + self.hg_ctx_maxregentime;
        } else {
            self.hg_ctx_ammo -= hg_ammo_used;
            nadget_SetRegenTime(self, nadget_RegenTime(self));
        }
    }

    //self.buff_stealth_time = time;
    self.hg_nadesused += hg_ammo_used;
}

void nadget_UpdateDetonables(void) {
    entity nade = NULL;
    self.hg_detonables = 0;

    for(;(nade = find(nade, classname, "hg_generic_projectile"));)
        if(nade.owner == self && !nade.hg_detonatetime && nade.hg_detonable && nade.hg_detonateready <= time)
            self.hg_detonables += 1;

    for(;(nade = find(nade, classname, "hg_sentry"));)
        if(nade.realowner == self)
            self.hg_detonables += 1;
}

float nadget_RegenLimit(entity plr) {
    float mx = 0;

    mx = GRENVAR(plr.hg_ctx_type, "regen_limit");

    if(mx < 1)
        return 0;

#if 0
    if(Buffs_Present(plr, BUFF_ADEPT))
        mx += GRENVAR(plr.hg_ctx_type, "adept_regen_limit_extend");

    float supply = Buffs_Present(plr, BUFF_SUPPLY);
    if(supply)
        mx += CVAR(g_buffs_supply_hg_extra_regen_limit) * rint(supply);
#endif

    return mx;
}

float nadget_StorageLimit(entity plr) {
    float rlim = nadget_RegenLimit(plr);
    return max(rlim, rint(rlim * g_nadgets_storage_limit_factor));
}

void nadget_AdvanceRegen(entity plr, float delta, float limit) {
    if(limit && plr.hg_ctx_ammo >= limit)
        return;

    plr.hg_ctx_regentime -= delta;

    if(plr.hg_ctx_regentime <= 0) {
        float rem = -plr.hg_ctx_regentime;
        if(math_almost_equals(rem, 0))
            rem = 0;

        plr.hg_ctx_ammo += 1;
        nadget_SetRegenTime(plr, nadget_RegenTime(plr));

        if(rem)
            nadget_AdvanceRegen(plr, rem, limit);
    }
}

void nadget_PlayerPreThink(void) {
	nadget_PlayerPreThink_NextLink();
    if(time < map_starttime)
        return;

	if not(g_nadgets || ((self.abilities & NADGET_ABILITY) && self.hg_type1))
		return;

    nadget_Shield_PlayerFrame();
    nadget_Cloak_PlayerFrame();
	float mayfire = player_can_fire(self, FALSE);
	float held, isalt = 0;
	held = self.(g_nadgets_detonatelaunches ? hg_detonatepressed : BUTTON_USE);

    float n_type;

    if(!held) {
        held = self.BUTTON_NADGET2;
        if(held) {
            isalt = TRUE;
        }
    }

    float charging;

    if(self.hg_altcharge || (g_nadgets_detonatelaunches && !self.hg_altstate)) {
        charging = (held || self.hg_power);

        if(self.hg_power && held && held != self.hg_state)
            charging = FALSE;
    } else {
        charging = held;
    }

    if(self.hg_power)
        isalt = self.hg_altstate;

    nadget_SetContext(isalt);

    if(!isalt && self.hg_bonus) {
        hg_ctx_ammo = hg_bonus;
        hg_ctx_next = hg_bonus_next;
        n_type = self.hg_bonustype;
    } else {
        n_type = self.hg_ctx_type;
    }

    if(held && held != self.hg_state) {
        if(!self.hg_ctx_ammo && self.deadflag == DEAD_NO) {
            centerprint(self, strcat("Out of ", nadget_TypeToExpandedName(n_type), "s!"));
        }
    }

    if(charging && time >= self.hg_ctx_next && self.hg_ctx_ammo && mayfire) {
        float ls = GRENVAR(n_type, "launchspeed");

        self.hg_launchspeed = ls;

        if(ls)
            self.hg_power = bound(0.01, self.hg_power + frametime * ls, 1);
        else {
            self.hg_power = 0;
            nadget_Attack();
        }
	} else {
		if(self.hg_power && mayfire/* && self.hg_launchspeed*/)
			nadget_Attack();
		self.hg_power = 0;
	}

	if(self.hg_power == 1 && mayfire && GRENVAR(n_type, "launch_fullforce_launches_immediately"))
		nadget_Attack();

	self.hg_state = held;
    self.hg_altstate = isalt;

	float mx, dpause;
    if(g_nadgets_regen) NADGET_DO_IN_ALL_CONTEXTS({
        mx = nadget_RegenLimit(self);
        dpause = g_nadgets_regen_damagepause;

        self.hg_ctx_regenrate = GRENVAR(self.hg_ctx_type, "regen_scale");
        dpause = min(dpause, dpause / self.hg_ctx_regenrate);
        self.hg_ctx_regenpaused = (((self.hg_stealth || self.hg_stealth_saved) && self.hg_ctx_type == NADGET_CLOAK) || (time - self.lastdamage <= dpause) );

        if(self.hg_ctx_ammo < mx || !mx) {
            if(!self.hg_ctx_regenpaused) {
                nadget_AdvanceRegen(self, frametime * self.hg_ctx_regenrate, mx);
            }
        } else
            self.hg_ctx_regenrate = 0;
    })

    if(self.hg_detonatepressed)
        self.hg_detonatepressed = FALSE;
}

void nadget_Trigger(void) {
    if(PLAYER_DEAD(self))
        return;

    if(self.hg_stealth || self.hg_stealth_saved)
        nadget_Cloak_Trigger();
    else if(self.hg_shield || (self.hg_shield_stored && g_nadgets_shield_damage_store_allow_cancel_discharge))
        nadget_Shield_Trigger();
    else {
        nadget_Sentry_Trigger();
		nadget_GenericProjectile_DetonateAll(self, FALSE);
        self.hg_detonatepressed = TRUE;
    }
}

void nadget_CopyAmmoState(entity src, entity dst) {
    dst.hg_ctx_ammo = src.hg_ctx_ammo;
    dst.hg_ctx_regentime = src.hg_ctx_regentime;
    dst.hg_ctx_maxregentime = src.hg_ctx_maxregentime;
    dst.hg_ctx_regenrate = src.hg_ctx_regenrate;
    dst.hg_ctx_regenpaused = src.hg_ctx_regenpaused;
}

void nadget_ResetAmmo(entity p, float clearammo) {
	if not(g_nadgets || (p.abilities & NADGET_ABILITY)) {
		return;
	}
    p.hg_ctx_ammo = (clearammo ? 0 : g_nadgets_ammo);

    nadget_SetNadgetType(p, nadget_PlayerNadgetType(p));
    nadget_SetRegenTime(p, nadget_RegenTime(p));

    if(!clearammo) {
        float mx = nadget_StorageLimit(p);
        nadget_AdvanceRegen(p, g_nadgets_initial_regen, mx);

        if(!g_nadgets_regen) {
            if(p.hg_ctx_regentime / p.hg_ctx_maxregentime < 0.5)
                nadget_AdvanceRegen(p, p.hg_ctx_regentime, mx);
            else
                p.hg_ctx_regentime = p.hg_ctx_maxregentime;
        }
    }
}

void nadget_ResetState(entity p, float clearammo) {
}

void nadget_ForceDetonateAll(void) {
    nadget_GenericProjectile_DetonateAll(self, TRUE);

	entity s;
    for(s = world; (s = find(s, classname, "hg_sentry"));) {
        if(s.realowner == self)
            nadget_FadeOut(s);
    }
}

string nadget_SelectableTypes(float issecondary) {
    string types;

    if(!g_nadgets_double) {
        types = cvar_string("g_nadgets_type_selectable");
    } else if(issecondary) {
        types = cvar_string("g_nadgets_type_selectable_secondary");
    } else {
        types = cvar_string("g_nadgets_type_selectable_primary");
    }

    if(types == "all") {
        types = "";

        #define NADGETDEF(id,shortname,longname,color) \
            types = strcat(types, #shortname, " ");
        NADGETDEFS
        #undef NADGETDEF
    } else if(types == "0") {
		return "";
	}
    return types;
}

void nadget_WriteNadgetSelect(void) {
    msg_entity = self;
    net_write_byte(MSG_ONE, SVC_TEMPENTITY);
    net_write_byte(MSG_ONE, NET_TE_CSQC_NADGETSELECT);
    net_write_byte(MSG_ONE, g_nadgets_double);
    net_write_string(MSG_ONE, nadget_SelectableTypes(FALSE));

    if(g_nadgets_double)
        net_write_string(MSG_ONE, nadget_SelectableTypes(TRUE));
}

float nadget_ShowMenu(float always) {
    if((self.hg_type1_picked && self.BUTTON_CHAT) && always < 2)
        return FALSE;

    if(nadget_SelectableTypes(FALSE) != "" && (always || !self.hg_type1_picked || (g_nadgets_double && !self.hg_type2_picked)) && clienttype(self) == CLIENTTYPE_REAL) {
        nadget_WriteNadgetSelect();
        return TRUE;
    }
    return FALSE;
}

void target_bonusnadgets_use() {
	if(!PLAYER_DEAD(activator))
		nadget_GiveBonus(activator, self.hg_type1, self.cnt, self.message, FALSE);
}

void spawnfunc_target_bonusnadgets(void) {
    self.classname = "target_bonusnadgets";
    self.hg_type1 = nadget_NameToType(self.netname);
    self.cnt = floor(max(0, self.cnt));

    if(!self.message)
        self.message = "a secret has been triggered";

    self.use = target_bonusnadgets_use;
}

void nadget_Pick(float tokens) {
	if not(self.flags & FL_CLIENT)
		return;

	if(tokens < 2) {
		nadget_ShowMenu(2);
		return;
	}

	float isplayer = self.classname != "spectator" && self.classname != "observer";
	float nr = (self.hg_type1 && isplayer && self.hg_nadesused && !warmup_active);

	float t1 = nadget_NameToType(argv(1));
	float t2 = nadget_NameToType(argv(2));
	float success, t, i, argc;

	if(g_nadgets_double && t1 == t2 && t1 != NADGET_RANDOM && t2 != NADGET_RANDOM) {
		sprint(self, "^1Primary and secondary nadgets can't be of the same type\n");
		return;
	}

	float revert;
	entity astate = NULL;
	NADGET_DO_IN_ALL_CONTEXTS({
		argc = tokenize_console(nadget_SelectableTypes(hg_context_isalt));
		success = FALSE;
		t = (hg_context_isalt ? t2 : t1);

		if(argc) for(i = 0; i < argc; ++i) {
			if(t == nadget_NameToType(argv(i))) {
				sprint(self, strcat("^1Your ", (g_nadgets_double ? (hg_context_isalt ? "secondary " : "primary ") : ""), "nadget type ", (nr ? "will be" : "has been"), " set to the ^2", nadget_TypeToExpandedName(t), (nr ? "^1 on the next respawn.\n" : "^1.\n")));
				self.hg_ctx_type_picked_nextround = t;
				if(!nr) {
					self.hg_ctx_type_picked = t;
					nadget_ResetAmmo(self, FALSE);

					if(astate) {
						revert = FALSE;

						if(astate.hg_ctx_ammo > self.hg_ctx_ammo) {
							revert = TRUE;
						} else if(astate.hg_ctx_ammo == self.hg_ctx_ammo) {
							if(astate.hg_ctx_regentime < self.hg_ctx_regentime)
								revert = TRUE;
						}

						if(revert)
							nadget_CopyAmmoState(astate, self);

						remove(astate);
						astate = world;
					}
					self.hg_ctx_type_picked_nextround = -1;
				}

				success = TRUE;
				break;
			}
		}

		if(!success) {
			sprint(self, "^1This nadget type is either invalid or not allowed on this server.\n");
			return;
		}
	})
}

float nadget_player_damage_handle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	gamehook_chain_player_damage_mod = nadget_Shield_Damage(attacker, _damage, deathtype, hitloc);
	return nadget_player_damage_handle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}
