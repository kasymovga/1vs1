float NADGET_ABILITY;
float g_nadgets;
float g_nadgets_detonate_on_death;
float g_nadgets_sentry_disown_on_death;
float g_nadgets_regen_compensate;
float g_nadgets_remove_on_death;
float g_nadgets_storage_limit_factor;
float g_nadgets_regen;
float g_nadgets_ammo;
float g_nadgets_weapon_drop;
float g_nadgets_regen_damagepause;
float g_nadgets_shield_damage_store_allow_cancel_discharge;
float g_nadgets_initial_regen;
float g_nadgets_drop_on_death;
float g_nadgets_show_in_sbar;
float g_nadgets_bonus_at_revive;
float g_nadgets_transloc_adept_revive;
float g_nadgets_transloc_medic_revive_health_multiplier;
float g_nadgets_plasma_adept_projectiles_on_bounce;
float g_nadgets_plasma_projectile_frozenlock_dps;
float g_nadgets_plasma_projectile_frozenlock_dps_radius;
float g_nadgets_plasma_projectile_frozenlock_dps_force;

void nadget_UpdateDetonables(void);
void nadget_ForceDetonateAll(void);

.float nadget_bonus_points;

var void() nadget_PlayerPreThink_next;
void nadget_PlayerPreThink();
var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) nadget_player_damage_handle_next;
float nadget_player_damage_handle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force);

// Nadgets mutator
// Intended for the Camping Rifle Arena mode

var float(string cmd, float tokens) nadget_cmd_client_handle_next;
float(string cmd, float tokens) nadget_cmd_client_handle {
	if(cmd == "picknade") {
		nadget_Pick(tokens);
		return TRUE;
	}
	return nadget_cmd_client_handle_next(cmd, tokens);
}

var float(entity plr, float wep) nadget_player_can_fire_next;
float(entity plr, float wep) nadget_player_can_fire {
	if (self.hg_stealth)
		return FALSE;

	if (self.hg_plasmalock > time)
		return FALSE;

	return nadget_player_can_fire_next(plr, wep);
}

var void(void(string item, string cmd) Add_Item) nadget_gamemenu_send_next;
void(void(string item, string cmd) Add_Item) nadget_gamemenu_send {
	Add_Item("Switch Nadget", "cmd picknade;");
	nadget_gamemenu_send_next(Add_Item);
}

var void(float killed) nadget_player_clear_next;
void(float killed) nadget_player_clear {
	if (killed) {
		if (g_nadgets_remove_on_death > 1)
			nadget_RemoveAll(self);

		if (self.hg_power > 0 && g_nadgets_drop_on_death) {
			nadget_SetContext(self.hg_altstate);
			self.hg_power = 0;
			nadget_Attack();
		}
		if (g_nadgets_detonate_on_death > 1)
			nadget_ForceDetonateAll();

		self.nadget_bonus_points = 0;
	} else {
		if ((self.classname != "player" && self.team <= 0) || self.classname == "disconnecting") {
			self.nadget_bonus_points = 0;
			nadget_RemoveAll(self);
			nadget_GenericProjectile_DetonateAll(self, TRUE);
		}
	}
	NADGET_DO_IN_ALL_CONTEXTS({
		if (self.hg_ctx_type_picked_nextround >= 0)
			self.hg_ctx_type_picked = self.hg_ctx_type_picked_nextround;

		self.hg_ctx_type_picked_nextround = -1;
	}, self.hg_type2)
	self.hg_power = 0;
	self.hg_bonus = 0;
	self.hg_bonustype = 0;
	self.hg_shield = 0;
	self.hg_linker = world;
	if (self.classname == "player")
		NADGET_DO_IN_ALL_CONTEXTS(nadget_ResetAmmo(self, FALSE);, self.hg_type2)

	self.hg_shield = 0;
	self.hg_stealth = 0;
	self.hg_stealthalpha = 0;
	self.hg_plasmalock = 0;
	self.hg_plasmalock_owner = NULL;
	self.hg_plasmalock_nexteffect = 0;
	nadget_UpdateDetonables();
	nadget_player_clear_next(killed);
}

var void() nadget_observer_spawn_next;
void(void) nadget_observer_spawn {
	//self.hg_type1_picked = 0;
	//self.hg_type2_picked = 0;
	self.hg_next1 = 0;
	self.hg_next2 = 0;
	nadget_observer_spawn_next();
}

var float() nadget_spectator_to_player_handle_next;
float nadget_spectator_to_player_handle() {
	if (g_nadgets || (self.abilities & NADGET_ABILITY)) {
		if (nadget_ShowMenu(FALSE))
			return TRUE;
	}
	return nadget_spectator_to_player_handle_next();
}

var float(entity plr) nadget_PlayerCanBeCarrier_next;
float(entity plr) nadget_PlayerCanBeCarrier {
	if (nadget_PlayerCanBeCarrier_next(plr))
	if not(plr.hg_stealth)
		return TRUE;

	return FALSE;
}

var void(entity plr) nadget_spectator_copy_next;
void(entity plr) nadget_spectator_copy {
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
	nadget_spectator_copy_next(plr);
}

var float() nadget_weapon_throw_handle_next;
float() nadget_weapon_throw_handle {
	nadget_weapon_throw_handle_next();
	if (item_drop_required(self))
		return FALSE;

	nadget_Trigger();
	return !g_nadgets_weapon_drop;
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
		//bprint ("^1", targ.netname, "^1 was nadefragged by ", attacker.netname, "\n");
		return FALSE;
	}
	return nadget_player_obituary_frag_next(deathtype, targ, inflictor, attacker);
}

var void(void) nadget_score_basics_end_next;
void(void) nadget_score_basics_end {
	nadget_score_basics_end_next();
	if not(g_nadgets_show_in_sbar) return;
	NADGET_SCORE = score_register("nade", 0);
	if not(g_nadgets_double || NADGET_ABILITY) return;
	NADGET_SCORE_SECONDARY = score_register("nade2", 0);
}

var void(entity unfrozer) nadget_ice_unfroze_next;
void(entity unfrozer) nadget_ice_unfroze {
	nadget_ice_unfroze_next(unfrozer);
	unfrozer.nadget_bonus_points++;
	if (g_nadgets_bonus_at_revive && unfrozer.nadget_bonus_points >= g_nadgets_bonus_at_revive) {
		nadget_GiveRandomBonus(unfrozer, 1, strcat("for reviving ", ftos(unfrozer.nadget_bonus_points), " players"));
		unfrozer.nadget_bonus_points = 0;
	}
}

var void() nadget_player_effects_next;
void() nadget_player_effects {
	if (time < self.hg_plasmalock) {
		self.effects |= (EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);
		if (self.hg_plasmalock_owner.classname != "player") {
			self.hg_plasmalock_owner = NULL;
			self.hg_plasmalock = 0;
		}
		if (time > self.hg_plasmalock_nexteffect) {
			float edelay = 0.35;
			self.hg_plasmalock_nexteffect = time + edelay;
			vector eorigin = self.origin + self.maxs_z * '0 0 0.5';
			float pdmg = g_nadgets_plasma_projectile_frozenlock_dps * edelay;
			if (pdmg)
				damage_radius(self, self.hg_plasmalock_owner, pdmg, pdmg, g_nadgets_plasma_projectile_frozenlock_dps_radius, world, g_nadgets_plasma_projectile_frozenlock_dps_force, EFFECT_IMPACT_PLASMA, self.projectiledeathtype, NULL);

			effect_lightningarc(eorigin + randomvec() * 100, eorigin + randomvec() * 10/*, TRUE, self.hg_plasmalock_owner.team*/); //FIXME
			sound(self, CHAN_AUTO, "sound/weapons/electro_impact.wav", 0.4, 1.5);
		}
	}
	nadget_player_effects_next();
}

var float() nadget_JumpVelocityMod_next;
float() nadget_JumpVelocityMod {
	float jump_mod = nadget_JumpVelocityMod_next();
	if (self.hg_plasmalock > time) jump_mod = 0;
	return jump_mod;
}

var float() nadget_physics_max_speed_mod_next;
float() nadget_physics_max_speed_mod {
	float maxspd_mod = nadget_physics_max_speed_mod_next();
	if (self.hg_plasmalock > time) maxspd_mod = 0;
	return maxspd_mod;
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
	CVAR_CACHE(g_nadgets_weapon_drop);
	CVAR_CACHE(g_nadgets_initial_regen);
	CVAR_CACHE(g_nadgets_drop_on_death);
	CVAR_CACHE(g_nadgets_bonus_at_revive);
	CVAR_CACHE(g_nadgets_transloc_adept_revive);
	CVAR_CACHE(g_nadgets_transloc_medic_revive_health_multiplier);
	CVAR_CACHE(g_nadgets_plasma_adept_projectiles_on_bounce);
	CVAR_CACHE(g_nadgets_plasma_adept_stun);
	CVAR_CACHE(g_nadgets_plasma_projectile_frozenlock);
	CVAR_CACHE(g_nadgets_plasma_projectile_frozenlock_dps);
	CVAR_CACHE(g_nadgets_plasma_projectile_frozenlock_dps_radius);
	CVAR_CACHE(g_nadgets_plasma_projectile_frozenlock_dps_force);
	CVAR_CACHE(g_nadgets_cloak_damagereduction_factor);
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
	nadget_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = nadget_player_clear;
	nadget_player_can_fire_next = plugin_chain_player_can_fire;
	plugin_chain_player_can_fire = nadget_player_can_fire;
	nadget_gamemenu_send_next = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = nadget_gamemenu_send;
	nadget_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = nadget_cmd_client_handle;
	nadget_player_damage_handle_next = plugin_chain_player_damage_handle;
	plugin_chain_player_damage_handle = nadget_player_damage_handle;
	nadget_spectator_to_player_handle_next = plugin_chain_spectator_to_player_handle;
	plugin_chain_spectator_to_player_handle = nadget_spectator_to_player_handle;
	nadget_PlayerCanBeCarrier_next = plugin_chain_PlayerCanBeCarrier;
	plugin_chain_PlayerCanBeCarrier = nadget_PlayerCanBeCarrier;
	nadget_spectator_copy_next = plugin_chain_spectator_copy;
	plugin_chain_spectator_copy = nadget_spectator_copy;
	nadget_bot_aim_next = plugin_chain_bot_aim;
	plugin_chain_bot_aim = nadget_bot_aim;
	nadget_player_obituary_frag_next = plugin_chain_player_obituary_frag;
	plugin_chain_player_obituary_frag = nadget_player_obituary_frag;
	nadget_ice_unfroze_next = plugin_chain_ice_unfroze; //sort of hack
	plugin_chain_ice_unfroze = nadget_ice_unfroze;
	nadget_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = nadget_player_effects;
	nadget_JumpVelocityMod_next = plugin_chain_JumpVelocityMod;
	plugin_chain_JumpVelocityMod = nadget_JumpVelocityMod;
	nadget_physics_max_speed_mod_next = plugin_chain_physics_max_speed_mod;
	plugin_chain_physics_max_speed_mod = nadget_physics_max_speed_mod;
	if (g_nadgets_double || NADGET_ABILITY) {
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
	projectile_register_auto(PROJECTILE_HG_GENERIC, NADGET_SIZE_DEFAULT * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_LASER, NADGET_SIZE_DEFAULT * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_NAPALM, NADGET_SIZE_DEFAULT * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_PLASMA, NADGET_SIZE_DEFAULT * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_REMOTE, NADGET_SIZE_DEFAULT * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_TRANSLOC, NADGET_SIZE_TRANSLOC * '1 -1 1');
	projectile_register_auto(PROJECTILE_HG_RAZE, '16 -3 3');
	projectile_register_auto(PROJECTILE_HG_PLASMA_SHARD, '0 -3 -3');
	projectile_register_auto(PROJECTILE_HG_SCAN, NADGET_SIZE_DEFAULT * '1 -1 1');
	nadget_observer_spawn_next = plugin_chain_observer_spawn;
	plugin_chain_observer_spawn = nadget_observer_spawn;
	nadget_PlayerPreThink_next = plugin_chain_player_think;
	plugin_chain_player_think = nadget_PlayerPreThink;
	nadget_weapon_throw_handle_next = plugin_chain_weapon_throw_handle;
	plugin_chain_weapon_throw_handle = nadget_weapon_throw_handle;
	nadget_score_basics_end_next = plugin_chain_score_basics_end;
	plugin_chain_score_basics_end = nadget_score_basics_end;
	napalm_init();
	hint_add("You can detonate FireTrap of enemy shooting on it");
	hint_add("Translocator nadget can be used as teleporting or killing enemy shooting directly on enemy");
	hint_add("You can increase speed using laser nadget, you can jump higher with laser nadget aiming to ground or wall with laser nadget");
	hint_add("When enemy stand close to FireTrap you will see red indicator indicating");
}

void(entity e, string args, float set) nadget_ability_init {
	if (e) {
		if (set) {
			entity oldself = self;;
			self = e;
			self.hg_type1_picked &= ~1024;
			if (args != "") {
				string arg1 = str_car(args);
				self.hg_type1 = self.hg_type1_picked = nadget_NameToType(arg1);
				self.hg_type1_picked |= 1024;
				NADGET_DO_IN_ALL_CONTEXTS({
					nadget_ResetAmmo(self, FALSE);
				}, self.hg_type2);
				string arg2 = str_car(str_cdr(args));
				if (arg2 != "")
					self.hg_type2 = self.hg_type2_picked = nadget_NameToType(arg2);
				else
					self.hg_type2 = self.hg_type2_picked = 0;

				if (g_nadgets_show_in_sbar) {
					score_player_set(self, NADGET_SCORE, self.hg_type1);
					score_player_set(self, NADGET_SCORE_SECONDARY, self.hg_type2);
				}
				NADGET_DO_IN_ALL_CONTEXTS({
					nadget_ResetAmmo(self, FALSE);
				}, self.hg_type2);
			} else {
				if not(nadget_ShowMenu(0)) {
					NADGET_DO_IN_ALL_CONTEXTS({
						nadget_ResetAmmo(self, FALSE);
					}, g_nadgets_double);
				}
				if not(g_nadgets_double)
					self.hg_type2 = self.hg_type2_picked = 0;
			}
			self = oldself;
		} else {
			nadget_RemoveAll(e);
			e.hg_type1 = 0;
			e.hg_type2 = 0;
			e.hg_type1_picked = 0;
			if (g_nadgets_show_in_sbar) {
				score_player_set(self, NADGET_SCORE, self.hg_type1);
				score_player_set(self, NADGET_SCORE_SECONDARY, self.hg_type2);
			}
		}
	} else
		nadget_init_common();
}

void(void) nadget_init {
	CVAR_CACHE(g_nadgets);
	CVAR_CACHE(g_nadgets_show_in_sbar);
	if (!g_nadgets)
		NADGET_ABILITY = ability_register("nadget", nadget_ability_init);

	if not(g_nadgets)
		return;

	nadget_init_common();
}

void nadget_precache(void) {
	heal_init();
	dlc_require(DLC_RM_EFFECTS);
	dlc_require("rm_laser");
	dlc_require("rm_arc");
	dlc_require("pryaxe_balls");
	dlc_require("nadgets_v3");
	dlc_require("nadgets-scan-magnet");
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
	precache_sound("sound/weapons/electro_impact.wav");
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

void nadget_GiveBonus(entity p, float hgtype, float amount, string reason) {
    amount *= GRENVAR(hgtype, "bonus_amount_multiplier") * rm_buffs_nadget_bonus_multiplier(p);

    if(amount < 1)
        return;

    if(p.hg_bonustype != hgtype)
        p.hg_bonus = 0;

	p.hg_bonus += amount;
	p.hg_bonustype = hgtype;
    p.hg_bonus_next = 0;

	string n = nadget_TypeToExpandedName(hgtype);
	entity e;

	CLIENT_FOR_EACH_REAL(e) if(e.iscreature || e.classname == "spectator") {
        entity check = e;
        if(!e.iscreature)
            check = e.enemy;

		if(check == p) {
			RM_ELSE({rm_bigprint(e, strcat("^7You got a ^3", n, "^7 bonus!"), reason, 3);},
					{print_to_spec(e, PRINT_CENTER, "^7You got a ^3{1}^7 bonus!\n{2}", n, reason, "");})
		} else if(team_is_different_teams(check, p)) {
			RM_ELSE({rm_bigprint(e, strcat("^3Enemy got a ^1", n, " ^3bonus!"), strcat("Given to ^3", p.netname, " ^7(", reason, ")"), 3);},
					{print_to_spec(e, PRINT_CENTER, "^3Enemy got a ^1{1} ^3bonus!\nGiven to ^3{2} ^7({3})", n, p.netname, reason);})
		} else
			print_to_spec(e, PRINT_CENTER, "^3{1}{1}^7 got a ^3{2} ^7bonus ({3})", n, p.netname, reason);
	}
	print_all(PRINT_INFO, "^3{1} ^7got a ^3{2}^7 bonus ({3})", p.netname, n, reason);
    sound_play2all("kh/alarm.wav");
}

void nadget_GiveRandomBonus(entity p, float amount, string reason) {
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
        nadget_GiveBonus(p, random_selection_chosen_float, amount, reason);
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
		if ((c == "hg_generic_projectile" ||
				c == "hg_plasma" ||
				c == "hg_napalm" ||
				c == "hg_linker" ||
				(c == "hg_sentry" && (!g_nadgets_sentry_disown_on_death)))
				&& ((n.realowner && n.realowner == plr) || n.owner == plr)) {
			pointparticles(particleeffectnum("morphed_damage_dissolve"), (n.absmin + n.absmax) * 0.5, '0 0 0', 1);
			stdproc_remove_entity(n);
		}
	}
}

float nadget_PlayerNadgetType(entity e) {
    float picked = nadget_NameToType(cvar_string("g_nadgets_type"));
    float argc = tokenize_console(nadget_SelectableTypes(hg_context_isalt));
    float i;
	if (e.hg_ctx_type_picked & 1024)
		return (e.hg_ctx_type_picked & 1023);

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
	if (g_nadgets_show_in_sbar) score_player_set(self, (hg_context_isalt ? NADGET_SCORE_SECONDARY : NADGET_SCORE), self.hg_ctx_type);
}

void nadget_SetCooldown(.float cdfield, float gcd, float cd) {
    float cdmul = rm_buffs_nadget_cooldown(self);
    gcd *= cdmul;
    cd *= cdmul;
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
		if (self.hg_bonus <= 0)
			self.hg_bonustype = 0;
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

		if (RM_BUFFS_PRESENT(plr, RM_BUFFS_ADEPT))
			mx += GRENVAR(plr.hg_ctx_type, "adept_regen_limit_extend");

		float supply = RM_BUFFS_PRESENT(plr, RM_BUFFS_SUPPLY);
		if (supply)
			mx += g_buffs_supply_hg_extra_regen_limit * rint(supply);

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
	nadget_PlayerPreThink_next();
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
        held = self.BUTTON_HOOK;
        if(held) {
            isalt = TRUE;
        }
    }
	if (isalt && !self.hg_type2)
		return;

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
			print_to_spec(self, PRINT_CENTER, "Out of {1}s!", nadget_TypeToExpandedName(n_type), "", "");
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
		dpause = g_nadgets_regen_damagepause * rm_buffs_nadget_regen_damage_pause(self);
        self.hg_ctx_regenrate = GRENVAR(self.hg_ctx_type, "regen_scale");
        dpause = min(dpause, dpause / self.hg_ctx_regenrate);
        self.hg_ctx_regenpaused = (((self.hg_stealth || self.hg_stealth_saved) && self.hg_ctx_type == NADGET_CLOAK) || (time - self.lastdamage <= dpause) );

        if(self.hg_ctx_ammo < mx || !mx) {
            if(!self.hg_ctx_regenpaused) {
                nadget_AdvanceRegen(self, frametime * self.hg_ctx_regenrate, mx);
            }
        } else
            self.hg_ctx_regenrate = 0;
    }, self.hg_type2)

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
		if(RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT)) {
			NADGET_DO_IN_ALL_CONTEXTS({
				if(self.hg_ctx_type == NADGET_LASER) {
					nadget_Attack();
				}
			}, self.hg_type2)
		}
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
		p.hg_type1 = 0;
		p.hg_type2 = 0;
		if (g_nadgets_show_in_sbar) {
			score_player_set(self, NADGET_SCORE, self.hg_type1);
			if (NADGET_SCORE_SECONDARY)
				score_player_set(self, NADGET_SCORE_SECONDARY, self.hg_type2);
		}
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
	entity oldself;
	for (s = world; (s = find(s, classname, "hg_sentry"));) {
		if (s.realowner == self) {
			oldself = self;
			self = s;
			nadget_Sentry_Explode();
			self = oldself;
		}
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
	if (!g_nadgets && !(self.abilities & NADGET_ABILITY)) {
		if (clienttype(self) == CLIENTTYPE_REAL)
			print_to(self, PRINT_CENTER, "You don't have nadget ability", "", "", "");

		return;
	}
	msg_entity = self;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_NADGETSELECT);
	net_write_byte(MSG_ONE, g_nadgets_double);
	net_write_string(MSG_ONE, nadget_SelectableTypes(FALSE));
	if (g_nadgets_double)
		net_write_string(MSG_ONE, nadget_SelectableTypes(TRUE));
}

float nadget_ShowMenu(float always) {
	if (self.hg_type1_picked & 1024)
		return FALSE;

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
		nadget_GiveBonus(activator, self.hg_type1, self.cnt, self.message);
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

	if (self.hg_type1_picked & 1024) {
		if (clienttype(self) == CLIENTTYPE_REAL)
			print_to(self, PRINT_CENTER, "Your nadget type is forced", "", "", "");

		return;
	}
	if(tokens < 2) {
		nadget_ShowMenu(2);
		return;
	}

	float isplayer = self.classname != "spectator" && self.classname != "observer";

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
		float nr = (self.hg_ctx_type && isplayer && self.hg_nadesused && !warmup_active);

		if(argc) for(i = 0; i < argc; ++i) {
			if(t == nadget_NameToType(argv(i))) {
				print_to(self, PRINT_INFO, strcat("^1Your ", (g_nadgets_double ? (hg_context_isalt ? "secondary " : "primary ") : ""), "nadget type ", (nr ? "will be" : "has been"), " set to the ^2{1}", (nr ? "^1 on the next respawn." : "^1.")), nadget_TypeToExpandedName(t), "", "");
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
	}, g_nadgets_double)
}

float nadget_player_damage_handle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	plugin_chain_player_damage_mod *= nadget_Shield_Damage(attacker, _damage, deathtype, hitloc);
	return nadget_player_damage_handle_next(inflictor, attacker, _damage, deathtype, hitloc, force);
}
