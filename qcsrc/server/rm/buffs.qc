float g_buffs_random_spawns_distant;
float g_buffs_random_spawns_min;
float g_buffs_random_spawns_max;
float g_buffs_randomize_interval_force;
float g_buffs_conduit_range;
float g_buffs_vampire_limit;
float g_buffs_vampire_pauserot;
float g_buffs_supply_grant_ammo;
float g_buffs_guard_pickup_health;
float g_buffs_guard_pickup_armor;
float g_buffs_wrath_hgpower;
float g_buffs_supply_hg_regenscale;
float g_buffs_wrath_hgregen;
float g_buffs_wrath_hgcooldown;
float g_buffs_wrath_hgregen_damagepause;
float g_buffs_wrath_hgbonusmultiplier;
float g_buffs_supply_clip_limit_multiplier;
float g_buffs_medic_healfactor;
float g_buffs_medic_selfhealfactor;
float g_buffs_medic_forcefactor_self;
float g_buffs_medic_forcefactor_team;
float g_buffs_medic_maxhealth;
float g_buffs_medic_pauserot;
float g_buffs_medic_damagefactor;
float g_buffs_ignite_damage_fire;
float g_buffs_ignite_burntime;
float g_buffs_ignite_damage_base;
float g_buffs_tenacity_takedamage_self;
float g_buffs_tenacity_takedamage_aoe;
float g_buffs_tenacity_takedamage;
float g_buffs_vampire_time;
float g_buffs_vampire_factor;
float g_buffs_vampire_limit;
float g_buffs_vampire_pauserot;
float g_buffs_wrath_hgregen_fromdamage;
float g_buffs_arc_multiplier_hg;
float g_buffs_arc_multiplier;
float g_buffs_arc_range;
float g_buffs_arc_pushback;
float g_buffs_conduit_factor_heal_to_heal;
float g_buffs_conduit_factor_damage_to_heal;
float g_buffs_conduit_factor_damage_to_damage;
float g_buffs_conduit_factor_heal_to_damage;
float g_buffs_endurance_damage_dot_duration;
float g_buffs_endurance_damage_direct;
float g_buffs_endurance_damage_dot;
float g_buffs_reaper_buff_banmask;
float g_buffs_meodp_selfdamage;
float g_buffs_meodp_selfdamage_min;
float g_buffs_meodp_healthfactor;
float g_buffs_meodp_armorfactor;
float g_buffs_activate_delay;
float g_buffs_activate_delay_dual;
float g_buffs_reactivate_delay;
float g_buffs_reactivate_delay_dual;
float g_buffs_team_swap;
float g_buffs_haste_refire_rate;
float g_buffs_haste_move_rate;
float g_buffs_supply_pickup_multiplier;
float g_buffs_stealth_alpha;
float g_buffs_stealth_regaintime;
float g_buffs_guard_health;
float g_buffs_guard_armor;
float g_buffs_guard_health_regen;
float g_buffs_guard_armor_regen;

#define ON_BUFF_ADDED(b) if(self.buffs & (b)) if not(self.oldbuffs & (b))
#define ON_BUFF_REMOVED(b) if(self.oldbuffs & (b)) if not(self.buffs & (b))

.entity buff_chain;
.float buff_oldsolid;
.void(void) teamswap;

const vector BUFFS_MARGIN_MINS = '-4 -4 0';
const vector BUFFS_MARGIN_MAXS = ' 4  4 0';

var void(void) rm_buffs_player_think_next;
void(void) rm_buffs_player_think;
var void(float killed) rm_buffs_player_clear_next;
void(float killed) rm_buffs_player_clear;

float Buffs_Random_Spawn_EntFilter(entity e) {
    return ((e.flags & FL_ITEM) && e.classname != "item_buff_randomspawn") || e.classname == "info_player_deathmatch";
}

void Buffs_Random_Spawn_Init(void) {
	entity e;
    for(e = NULL; (e = rm_findfilter(e, Buffs_Random_Spawn_EntFilter));) {
        e.buff_oldsolid = e.solid;
        e.solid = SOLID_BBOX;
    }
}

void Buffs_Random_Spawn_Cleanup(void) {
	entity e;
    for(e = NULL; (e = rm_findfilter(e, Buffs_Random_Spawn_EntFilter));) {
        e.solid = e.buff_oldsolid;
        e.buff_oldsolid = 0;
    }
}

entity Buffs_Random_Spawn_Test_Overlap(entity buff) {
	entity e;
    for(e = NULL; (e = rm_findfilter(e, Buffs_Random_Spawn_EntFilter));) if(e != buff) {
        if(math_boxes_overlap(buff.absmin, buff.absmax, e.absmin, e.absmax))
            return e;
    }

    return NULL;
}

void Buffs_Random_Spawn(void) {
    entity o = self;
    self = spawn();
    self.buffs = BUFF_RANDOM;
    self.classname = "item_buff_randomspawn";
    Buffs_BuffPickup_Setup();

    if(Buffs_Random_Spawn_EntFilter(self)) {
        self.buff_oldsolid = self.solid;
        self.solid = SOLID_BBOX;
    }

    float a = max(1, g_buffs_random_spawns_distant), mx = -1;
    vector org = '0 0 0';
    entity blist = findchain_tofield(classname, "item_buff", buff_chain);

    vector omins = self.mins;
    vector omaxs = self.maxs;
    setsize(self, omins + BUFFS_MARGIN_MINS, omaxs + BUFFS_MARGIN_MAXS);

	float i;
	float fails = 0;
	float failed = 1;
	for(i = 0; i < a && fails < 10; ++i) {
		failed = 0;
        entity_move_to_random_location(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_WATER | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 128, 1024, 256);

		//FIXME
        //snap_to_grid(self, 32);
        //snap_to_entity(self, 1024, Buffs_Random_Spawn_EntFilter);

        setsize(self, '-1 -1 0' + '0 0 1' * self.mins_z, '1 1 0' + '0 0 1' * self.maxs_z);
		builtin_droptofloor();
        setsize(self, omins + BUFFS_MARGIN_MINS, omaxs + BUFFS_MARGIN_MAXS);
        entity_move_out_of_solid_with_type(self, TRACE_MOVE_WORLDONLY);

		//FIXME
        //if(check_uneven_ground(self, 1))
        //    goto fail;

        trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NORMAL, self);

        if(trace_startsolid)
            goto fail;

        if(trace_ent && Buffs_Random_Spawn_EntFilter(trace_ent))
            goto fail;

        if(Buffs_Random_Spawn_Test_Overlap(self))
            goto fail;

        float d = 1000000;

		entity b;
        for(b = blist; b; b = b.buff_chain) if(b != self) {
            d = min(d, vlen(self.origin - b.origin));
        }

        if(d * (1 + 0.1 * random()) > mx) {
            org = self.origin;
            mx = d;
        }
		break;
:fail
		failed = 1;
		--i;
		fails++;
    }
	if (failed) {
		print("Failed to spawn buff: no place found\n");
		remove(self);
	} else {
		setorigin(self, org);
		setsize(self, omins, omaxs);
		entity_move_out_of_solid_with_type(self, TRACE_MOVE_WORLDONLY);
	}
    self = o;
}

var float() rm_buffs_weapon_rate_factor_next;
float() rm_buffs_weapon_rate_factor {
	float f = rm_buffs_weapon_rate_factor_next();
	if (Buffs_Present(self, BUFF_HASTE))
		return f * g_buffs_haste_refire_rate;

	return f;
}

var float() rm_buffs_physics_max_speed_mod_next;
float() rm_buffs_physics_max_speed_mod {
	float f = rm_buffs_physics_max_speed_mod_next();
	if (Buffs_Present(self, BUFF_HASTE))
		return f * g_buffs_haste_move_rate;

	return f;
}

//var void(entity attacker, entity targ, float deathtype) rm_buffs_damage_mods_set_next;
//void(entity attacker, entity targ, float deathtype) rm_buffs_damage_mods_set {
//	rm_buffs_damage_mods_set_next(attacker, targ, deathtype);
//}

var float(entity to, float f) rm_buffs_item_give_factor_next;
float(entity to, float f) rm_buffs_item_give_factor {
	if(Buffs_Present(to, BUFF_SUPPLY))
		f *= g_buffs_supply_pickup_multiplier;

	return rm_buffs_item_give_factor_next(to, f);
}

var float(entity plr, entity viewer, float a) rm_buffs_player_alpha_mod_next;
float(entity plr, entity viewer, float a) rm_buffs_player_alpha_mod {
    if (Buffs_Present(plr, BUFF_STEALTH))
        a *= (1 - (1 - g_buffs_stealth_alpha) * bound(0, (time - plr.buff_stealth_time) / g_buffs_stealth_regaintime, 1));

	return rm_buffs_player_alpha_mod_next(plr, viewer, a);
}

var float(float secondary, float attacktime) rm_buffs_WeaponPrepareAttack_next;
float rm_buffs_WeaponPrepareAttack(float secondary, float attacktime) {
	self.buff_stealth_time = time;
	return rm_buffs_WeaponPrepareAttack_next(secondary, attacktime);
}

var void() rm_buffs_player_health_armor_mods_set_next;
void() rm_buffs_player_health_armor_mods_set {
	rm_buffs_player_health_armor_mods_set_next();
	if not(Buffs_Present(self, BUFF_GUARD)) return;
	plugin_player_health_armor_rot_regen = FALSE;
	float limith = g_balance_health_limit * plugin_player_armor_health_limit_mod;
	float maxh = g_buffs_guard_health * plugin_player_health_max_mod;
	float minh = g_buffs_guard_health * plugin_player_health_max_mod;
	self.health = player_calc_rot_regen(self.health, minh, g_buffs_guard_armor_regen, g_balance_health_regenlinear, plugin_player_regen_mod * frametime * (time > self.pauseregen_finished), maxh, g_balance_health_rot, g_balance_health_rotlinear, plugin_player_rot_mod * frametime * (time > self.pauserothealth_finished), limith);
	// if player rotted to death...  die!
	if (self.health < 1)
		self.event_damage(self, self, 1, DEATH_ROT, self.origin, '0 0 0');

	float limita = g_balance_armor_limit * plugin_player_armor_health_limit_mod;
	self.armorvalue = player_calc_rot_regen(self.armorvalue, g_buffs_guard_armor, g_buffs_guard_armor_regen, g_balance_armor_regenlinear, plugin_player_regen_mod * frametime * (time > self.pauseregen_finished), max(g_balance_armor_rotstable, g_buffs_guard_armor), g_balance_armor_rot, g_balance_armor_rotlinear, plugin_player_rot_mod * frametime * (time > self.pauserotarmor_finished), limita);
}

var void(entity spot) rm_buffs_player_spawn_next;
void(entity spot) rm_buffs_player_spawn {
	Buffs_MEODP_Point_Attach(self, Buffs_MEODP_Death_Player);
}

var float(float f) rm_buffs_weapon_clip_capacity_mod_next;
float(float f) rm_buffs_weapon_clip_capacity_mod {
	if (Buffs_Present(self, BUFF_SUPPLY)) {
		f = floor(f * 1.5);
	}
	return rm_buffs_weapon_clip_capacity_mod_next(f);
}

var void(entity e) rm_buffs_spectator_copy_next;
void(entity e) rm_buffs_spectator_copy {
	self.buffstat = e.buffstat;
	rm_buffs_spectator_copy_next(e);
}

void(void) rm_buffs_init {
    float i, b;
    if not(rm_active) return;
    CVAR_CACHE(g_buffs);
    //if(g_clanarena)
    //    g_buffs = (g_buffs && CVAR(g_clanarena_buffs));
    if(!g_buffs)
        return;

	dlc_require("rm_arc");
	dlc_require(DLC_RM_EFFECTS);
	dlc_require("rm_buffs");
	rm_buffs_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = rm_buffs_player_think;
	rm_buffs_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = rm_buffs_player_clear;
	rm_buffs_physics_max_speed_mod_next = plugin_chain_physics_max_speed_mod;
	plugin_chain_physics_max_speed_mod = rm_buffs_physics_max_speed_mod;
	rm_buffs_weapon_rate_factor_next = plugin_chain_weapon_rate_factor;
	plugin_chain_weapon_rate_factor = rm_buffs_weapon_rate_factor;
	//rm_buffs_damage_mods_set_next = plugin_chain_damage_mods_set;
	//plugin_chain_damage_mods_set = rm_buffs_damage_mods_set;
	rm_buffs_item_give_factor_next = plugin_chain_item_give_factor;
	plugin_chain_item_give_factor = rm_buffs_item_give_factor;
	rm_buffs_player_alpha_mod_next = plugin_chain_player_alpha_mod;
	plugin_chain_player_alpha_mod = rm_buffs_player_alpha_mod;
	rm_buffs_WeaponPrepareAttack_next = plugin_chain_WeaponPrepareAttack;
	plugin_chain_WeaponPrepareAttack = rm_buffs_WeaponPrepareAttack;
	rm_buffs_player_health_armor_mods_set_next = plugin_chain_player_health_armor_mods_set;
	plugin_chain_player_health_armor_mods_set = rm_buffs_player_health_armor_mods_set;
	rm_buffs_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = rm_buffs_player_spawn;
	rm_buffs_weapon_clip_capacity_mod_next = plugin_chain_weapon_clip_capacity_mod;
	plugin_chain_weapon_clip_capacity_mod = rm_buffs_weapon_clip_capacity_mod;
	rm_buffs_spectator_copy_next = plugin_chain_spectator_copy;
	plugin_chain_spectator_copy = rm_buffs_spectator_copy;
	CVAR_CACHE(g_buffs_random_spawns_distant);
	CVAR_CACHE(g_buffs_random_spawns_min);
	CVAR_CACHE(g_buffs_random_spawns_max);
	CVAR_CACHE(g_buffs_randomize_interval_force);
	CVAR_CACHE(g_buffs_conduit_range);
	CVAR_CACHE(g_buffs_supply_grant_ammo);
	CVAR_CACHE(g_buffs_guard_pickup_health);
	CVAR_CACHE(g_buffs_guard_pickup_armor);
	CVAR_CACHE(g_buffs_wrath_hgpower);
	CVAR_CACHE(g_buffs_supply_hg_regenscale);
	CVAR_CACHE(g_buffs_wrath_hgregen);
	CVAR_CACHE(g_buffs_wrath_hgcooldown);
	CVAR_CACHE(g_buffs_wrath_hgregen_damagepause);
	CVAR_CACHE(g_buffs_wrath_hgbonusmultiplier);
	CVAR_CACHE(g_buffs_supply_clip_limit_multiplier);
	CVAR_CACHE(g_buffs_medic_healfactor);
	CVAR_CACHE(g_buffs_medic_selfhealfactor);
	CVAR_CACHE(g_buffs_medic_forcefactor_self);
	CVAR_CACHE(g_buffs_medic_forcefactor_team);
	CVAR_CACHE(g_buffs_medic_maxhealth);
	CVAR_CACHE(g_buffs_medic_pauserot);
	CVAR_CACHE(g_buffs_medic_damagefactor);
	CVAR_CACHE(g_buffs_ignite_damage_fire);
	CVAR_CACHE(g_buffs_ignite_burntime);
	CVAR_CACHE(g_buffs_ignite_damage_base);
	CVAR_CACHE(g_buffs_tenacity_takedamage_self);
	CVAR_CACHE(g_buffs_tenacity_takedamage_aoe);
	CVAR_CACHE(g_buffs_tenacity_takedamage);
	CVAR_CACHE(g_buffs_vampire_time);
	CVAR_CACHE(g_buffs_vampire_factor);
	CVAR_CACHE(g_buffs_vampire_limit);
	CVAR_CACHE(g_buffs_vampire_pauserot);
	CVAR_CACHE(g_buffs_wrath_hgregen_fromdamage);
	CVAR_CACHE(g_buffs_arc_multiplier_hg);
	CVAR_CACHE(g_buffs_arc_multiplier);
	CVAR_CACHE(g_buffs_arc_range);
	CVAR_CACHE(g_buffs_arc_pushback);
	CVAR_CACHE(g_buffs_conduit_factor_heal_to_heal);
	CVAR_CACHE(g_buffs_conduit_factor_damage_to_heal);
	CVAR_CACHE(g_buffs_conduit_factor_damage_to_damage);
	CVAR_CACHE(g_buffs_conduit_factor_heal_to_damage);
	CVAR_CACHE(g_buffs_endurance_damage_dot_duration);
	CVAR_CACHE(g_buffs_endurance_damage_direct);
	CVAR_CACHE(g_buffs_endurance_damage_dot);
	CVAR_CACHE(g_buffs_reaper_buff_banmask);
	CVAR_CACHE(g_buffs_meodp_selfdamage);
	CVAR_CACHE(g_buffs_meodp_selfdamage_min);
	CVAR_CACHE(g_buffs_meodp_healthfactor);
	CVAR_CACHE(g_buffs_meodp_armorfactor);
	CVAR_CACHE(g_buffs_activate_delay);
	CVAR_CACHE(g_buffs_activate_delay_dual);
	CVAR_CACHE(g_buffs_reactivate_delay);
	CVAR_CACHE(g_buffs_reactivate_delay_dual);
	CVAR_CACHE(g_buffs_team_swap);
	CVAR_CACHE(g_buffs_haste_refire_rate);
	CVAR_CACHE(g_buffs_haste_move_rate);
	CVAR_CACHE(g_buffs_supply_pickup_multiplier);
	CVAR_CACHE(g_buffs_stealth_alpha);
	CVAR_CACHE(g_buffs_stealth_regaintime);
	CVAR_CACHE(g_buffs_guard_health);
	CVAR_CACHE(g_buffs_guard_armor);
	CVAR_CACHE(g_buffs_guard_health_regen);
	CVAR_CACHE(g_buffs_guard_armor_regen);
    CVAR_CACHE(g_buffs_team_only);
    CVAR_CACHE(g_buffs_stack);
    CVAR_CACHE(g_buffs_replace);
    CVAR_CACHE(g_buffs_noteam);
    CVAR_CACHE(g_buffs_randomize);
    CVAR_CACHE(g_buffs_randomize_dual);
    CVAR_CACHE(g_buffs_randomize_byinstance);
    CVAR_CACHE(g_buffs_randomize_chaos);
    CVAR_CACHE(g_buffs_randomize_interval);
    CVAR_CACHE(g_buffs_spawn_on_powerups);
    CVAR_CACHE(g_buffs_random_spawns);
    CVAR_CACHE(g_buffs_lockon);
	CVAR_CACHE(g_buffs_supply_hg_extra_regen_limit);

    if(g_buffs_stack)
        g_buffs_replace = FALSE;

    //if(g_clanarena)
    //    g_buffs_team_only = CVAR(g_clanarena_buffs_team_only);
    precache_sound("misc/strength_respawn.wav");
    precache_sound("misc/shield_respawn.wav");
    dlc_precache_sound("misc/arc1.wav");
    precache_sound("kh/capture.wav");
    precache_model("models/runematch/rune.mdl");
    addstat(STAT_RM_BUFFS, STAT_INT, buffstat);
    
    float enabled = 0;
    for(i = 0, b = 1; i < BUFF_COUNT; ++i, b *= 2) {
        if(b == BUFF_MEDIC || b == BUFF_CONDUIT)
        if(!team_mode)
            continue;
        
        if(b == BUFF_WRATH || b == BUFF_ADEPT)
		if(!cvar("g_nadgets"))
			continue;
        
        if(cvar(strcat("g_buffs_", Buffs_TypeToName(b)))) {
            g_buffs_enabled |= b;
            ++enabled;
        }
        
        if(cvar(strcat("g_buffs_", Buffs_TypeToName(b), "_baseline")))
            g_buffs_baseline |= b;
    }
    
    if(enabled < 2)
        g_buffs_randomize_dual = 0;
    
    g_buffs_meodp = ((g_buffs_enabled & BUFF_MEODP) || (g_buffs_baseline & BUFF_MEODP));

    float havebuffs = (g_buffs_enabled | g_buffs_baseline);
    
    if(havebuffs & BUFF_ENDURANCE)
        addstat(STAT_RM_DMGINCOMING, STAT_INT, buff_endur_dmgpool);

    if(havebuffs & BUFF_VAMPIRE)
        addstat(STAT_RM_HEALINCOMING, STAT_INT, buff_vamp_healthpool);

    entity_initialize(NULL, Buffs_Init_Delayed, INITPRIO_LAST);
}

void Buffs_Randomize_Reset(void) {
    float i;
    
    for(i = 0; i < BUFF_COUNT; ++i) {
        g_buffs_replacements[i] = 0;
        g_buffs_used[i] = 0;
        g_buffs_used_dual[i] = 0;
        g_buffs_randomize_ulevel = 0;
        g_buffs_randomize_ulevel_dual = 0;
    }
}

float Buffs_Randomize_Yield(void) {
    float found = 0, sub, choosen, j, b;
    random_selection_init();
    
    while(!found) {
        for(j = 0, b = 1; j < BUFF_COUNT; ++j, b *= 2)
            if((g_buffs_enabled & b) && (g_buffs_used[j] < g_buffs_randomize_ulevel || g_buffs_randomize_chaos)) {
                random_selection_add(NULL, j, NULL, cvar(strcat("g_buffs_", Buffs_TypeToName(b), "_randomspawn_weight")), 1);
                ++found;
            }
        
        if(!found)
            ++g_buffs_randomize_ulevel;
    }
    
    choosen = random_selection_chosen_float;
    g_buffs_used[choosen] = g_buffs_randomize_ulevel;
    sub = pow(2, choosen);
    
    if(g_buffs_randomize_dual >= 1 || random() < g_buffs_randomize_dual) {
        random_selection_init();
        found = 0;
        
        while(!found) {
            for(j = 0, b = 1; j < BUFF_COUNT; ++j, b *= 2)
                if((g_buffs_enabled & b) && j != choosen && (g_buffs_used_dual[j] < g_buffs_randomize_ulevel_dual || g_buffs_randomize_chaos)) {
                    random_selection_add(NULL, j, NULL, cvar(strcat("g_buffs_", Buffs_TypeToName(b), "_randomspawn_weight")), 1);
                    ++found;
                }
            
            if(!found)
                ++g_buffs_randomize_ulevel_dual;
        }
        
        g_buffs_used_dual[random_selection_chosen_float] = g_buffs_randomize_ulevel_dual;
        sub = (sub | pow(2, random_selection_chosen_float));
    }
    
    return sub;
}

void Buffs_Randomize(entity blist, float force) {
    float i, j;
    entity b;
    
    if(g_buffs_randomize >= 2)
        force = TRUE;
    
    Buffs_Randomize_Reset();
    
    if(force && g_buffs_randomize_byinstance <= 1) for(i = 0; i < BUFF_COUNT; ++i)
        g_buffs_replacements[i] = Buffs_Randomize_Yield();
    
    if(!blist)
        blist = findchain(classname, "item_buff");
    
    for(b = blist; b; b = b.chain) {
        if(b.origbuffs == BUFF_RANDOM || g_buffs_randomize_byinstance > 1 || (g_buffs_randomize_byinstance && !b.team))
            b.buffs = Buffs_Randomize_Yield();
        else if(force) {
            i = Buffs_TypeToIndex(b.origbuffs);
            j = g_buffs_replacements[i];
            if(j) b.buffs = j;
        }
        //FIXME
        //if(roundstate != ROUNDSTATE_GAME || roundstate == ROUNDSTATE_INITIAL_WARMUP)
        //    Buffs_BuffPickup_SetInitialCooldown(b);
    }
}

//FIXME
//#define BUFFS_RANDOMIZER_NEXTTHINK (time + max3(game_starttime - time, next_round_starttime - time, 0) + g_buffs_randomize_interval)
#define BUFFS_RANDOMIZER_NEXTTHINK (time + g_buffs_randomize_interval)

void Buffs_Randomizer_Think(void) {
	//FIXME
    //if(roundstate == ROUNDSTATE_GAME || roundstate == ROUNDSTATE_INITIAL_WARMUP)
        Buffs_Randomize(NULL, TRUE);
    self.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
}

void Buffs_Randomizer_Reset(void) {
    self.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
    Buffs_Randomize_Reset();
}

float buff_teamfound[4];
void Buffs_Init_Delayed(void) {
    entity blist = NULL, b, o;
    float idx, teams_found = FALSE, teams_total, bcnt = g_buffs_count, j;
    
	if(g_buffs_random_spawns)
    if((g_buffs_random_spawns == 2 && !bcnt) || g_buffs_random_spawns < 2 || g_buffs_random_spawns > 2) {
        float mi = g_buffs_random_spawns_min;
        float ma = g_buffs_random_spawns_max;
        float bcount = rint(random() * (ma - mi) + mi);

        Buffs_Random_Spawn_Init();
		for(j = 0; j < bcount; ++j)
			Buffs_Random_Spawn();
        Buffs_Random_Spawn_Cleanup();
	} 

    if(g_buffs_spawn_on_powerups && !g_buffs_team_only) {
        o = self;
        for(b = findchain(classname, "buff_placeholder"); b; b = b.chain) {
            if(bcnt) {
                b.nextthink = time;
                b.think = stdproc_remove;
            } else {
                self = b;
                self.buffs = BUFF_RANDOM;
                Buffs_BuffPickup_Setup();
                if(self.owner && !wasfreed(self.owner)) {
                    remove(self.owner);
                    self.owner = NULL;
                }
            }
        }
        self = o;
    }

    if(team_mode) {
        teams_total = team_teams;

        blist = findchain(classname, "item_buff");
        for(b = blist; b; b = b.chain) if(b.team) {
            idx = team_index(b.team);
            if(!buff_teamfound[idx]) {
                buff_teamfound[idx] = TRUE;
                ++teams_found;
            }
            
            if((b.team == COLOR_TEAM3 && teams_total < 3) || (b.team == COLOR_TEAM4 && teams_total < 4)) {
                b.think = Buffs_BuffPickup_Remove;
                b.nextthink = time;
            }
        }
        
        if(teams_total > teams_found)
        for(b = blist; b; b = b.chain) if(b.team) {
            b.think = Buffs_BuffPickup_Remove;
            b.nextthink = time;
        }
    }
    
    Buffs_Randomize(blist, g_buffs_randomize);
    
    if(g_buffs_randomize)
    if(g_buffs_randomize_interval)
    if(g_buffs_randomize_interval_force/* || !EndRound_Allowed()*/) { //FIXME
        entity e = spawn();
        e.classname = "buff_randomizer";
        e.reset = Buffs_Randomizer_Reset;
        e.think = Buffs_Randomizer_Think;
        e.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
    }
}

string Buffs_Description(float bfs) {
    if(bfs & (bfs - 1)) {
        string result = "";

		float b;
        for(b = BUFF_FIRST; b <= BUFF_LAST; b *= 2) {
            if(bfs & b) {
                string s = Buffs_Description(b);
                if(result)
                    result = strcat(result, " ", s);
                else
                    result = s;
            }
        }

        return result;
    } else {
        string d = cvar_string(strcat("g_buffs_", Buffs_TypeToName(bfs), "_description"));
        return strcat(rgb_to_hexcolor(0.5 * Buffs_TypeToColor(bfs) + '0.5 0.5 0.5'), d);
    }
}

void Buffs_Notify(entity plr, float bfs, float tm) {
    string bname = strcat(Buffs_TypeToExpandedName(bfs, "^7 + ", 1), "^7 Buff!");
    string tn;
	if (tm)
		tn = strcat(team_color_code(tm), strtoupper(team_color_name(tm)), " ");
	else
		tn = "";

    bprint("^3", plr.netname, " ^7got the ", tn, bname, "\n");
    rm_bigprint_spec(plr, strcat("You got the ", bname), Buffs_Description(bfs), 4);
    sound(plr, CHAN_TRIGGER, "misc/shield_respawn.wav", VOL_BASE, ATTN_NORM);
}

float Buffs_Give(entity plr, float bfs, float tm) {
    bfs &= ~plr.buffs;

    if(!bfs)
        return 0;

    plr.buffs |= bfs;
    Buffs_Notify(plr, bfs, tm);

    return bfs;
}

float Buffs_Model_Send(entity to, float sf) {
    entity o = self.owner;

    if(self.flags & FL_ITEM)
        o = NULL;
    else if(o)
        sf &= ~(2 | 16);

    net_write_byte(MSG_ENTITY, NET_CSQC_RM_BUFFMODEL);
    net_write_byte(MSG_ENTITY, sf);

    if(sf & 1) {
		if (to == o)
			net_write_byte(MSG_ENTITY, num_for_edict(o));
		else
			net_write_byte(MSG_ENTITY, num_for_edict(o.body.body));
    }

    if(sf & 2) {
        net_write_byte(MSG_ENTITY, self.buff_active);
    }

    if(sf & 4) {
        net_write_coord(MSG_ENTITY, self.buffs);
    }

    if(sf & 8) {
        net_write_coord(MSG_ENTITY, self.origin_x);
        net_write_coord(MSG_ENTITY, self.origin_y);
        net_write_coord(MSG_ENTITY, self.origin_z);
    }

    if(sf & 16) {
        net_write_byte(MSG_ENTITY, self.team);
    }

    return TRUE;
}

void Buffs_Model_Update(entity e) {
    if(e.buff_active != e.buff_active_old) {
        e.buff_active_old = e.buff_active;
        e.SendFlags |= 2;
    }

    if(e.buffs != e.oldbuffs) {
        e.oldbuffs = e.buffs;
        e.SendFlags |= 4;
    }

    if(e.origin != e.oldorigin) {
        e.oldorigin = e.origin;
        e.SendFlags |= 8;
    }

    if(e.oldteam != e.team) {
        e.oldteam = e.team;
        e.SendFlags |= 16;
    }
} 

float Buffs_Model_Overhead_Customize(void) {
    if(!other.iscreature)
        return TRUE;
    
    if(self.owner.hg_stealth)
    if(team_is_different_teams(self.owner, other))
        return FALSE;

    if(player_alpha(self.owner, other) < 0.15)
        return FALSE;

    return TRUE;
}

float Buffs_TeamWaypoint_VisibleForPlayer(entity plr) {
    if(plr == self.owner)
        return FALSE;
    return WaypointSprite_visible_for_player(plr);
}

void Buffs_SetTeamWaypoint(entity plr, string txt, vector clr, float btype) {
    entity wp = plr.buff_teamwp;
    
    if(!wp) {
        wp = WaypointSprite_Spawn(txt, 0, 0, plr, '0 0 120', NULL, plr.team, plr, buff_teamwp, TRUE);
        wp.waypointsprite_visible_for_player = Buffs_TeamWaypoint_VisibleForPlayer;
    } else
        WaypointSprite_UpdateSprites(wp, txt, "", "");
    
    WaypointSprite_UpdateTeamRadar(wp, RADARICON_GENERATOR, clr);
    //WaypointSprite_UpdateTextColors(wp, clr, '0 0 0', '0 0 0');
    wp.buffs = btype;
}

void Buffs_RemoveTeamWaypoint(entity plr) {
    WaypointSprite_Disown(plr.buff_teamwp, 0.5);
}

void Buffs_ApplyConduit(void) {
    if(time < self.buff_conduit_next)
        return;

    float heal_h = self.buff_conduit_hpool;
    float heal_a = self.buff_conduit_apool;
    float _damage = self.buff_conduit_dpool;

    float doheal = (heal_h || heal_a);

    if(!doheal && !_damage)
        return;

    if(!Buffs_Present(self, BUFF_CONDUIT)) {
        self.buff_conduit_hpool = self.buff_conduit_apool = self.buff_conduit_dpool = 0;
        return;
    }

    vector buff_org = self.origin + BUFFMODEL_OVERHEAD_OFFSET;
    float healed = 0, damaged = 0;
	entity plr;
    FOR_EACH_PLAYER(plr) if(self != plr && !PLAYER_DEAD(plr)) {
        float sameteam = !team_is_different_teams(self, plr);

        if((sameteam && !doheal) || (!sameteam && !_damage))
            continue;

        vector o = warpzone_find_nearest_origin(buff_org, plr.origin + plr.view_ofs, 2);

        if(warpzone_find_nearest_origin_length < 0 || warpzone_find_nearest_origin_length > g_buffs_conduit_range)
            continue;

        if(sameteam) {
            arc_effect(buff_org, o, FALSE/*, 0*/); //FIXME
            //FIXME
            rm_heal(plr, self, self, heal_h, heal_a, 0, 0, DEATH_RM_CONDUIT, 0, 0, o, '0 0 0');
            healed = TRUE;
        } else {
            arc_effect(buff_org, o, FALSE/*, self.team*/); //FIXME
            damage(plr, self, self, _damage, DEATH_RM_CONDUIT, plr.origin + plr.view_ofs, '0 0 0');
            damaged = TRUE;
        }
    }

    if(healed || damaged) {
        if(healed)
            sound(self, CHAN_AUTO, "kh/capture.wav", 0.4, ATTN_NORM);
        if(damaged)
            sound(self, CHAN_AUTO, "misc/arc1.wav", 0.4, ATTN_NORM);
        self.buff_conduit_next = time + 0.5;
    }

    self.buff_conduit_hpool = self.buff_conduit_apool = self.buff_conduit_dpool = 0;
}

void Buffs_ApplyVampire(void) {
    if(self.buff_vamp_ticks > 0 && time > self.buff_vamp_nexttick) {
        float heal = self.buff_vamp_healthpool / self.buff_vamp_ticks;
        rm_heal(self, NULL, self, heal, 0, g_buffs_vampire_limit, 0, DEATH_RM_VAMPIRE, g_buffs_vampire_pauserot, 0, '0 0 0', '0 0 0');
        self.buff_vamp_healthpool -= heal;
        self.buff_vamp_ticks -= 1;
        self.buff_vamp_nexttick = time + 1;
    }
}

void(float killed) rm_buffs_player_clear {
	if (self.buff_model) {
		remove(self.buff_model);
		self.buff_model = NULL;
	}
	if (self.buff_teamwp)
		Buffs_RemoveTeamWaypoint(self);

	self.effective_buffs = 0;
	self.buffs = 0;
	rm_buffs_player_clear_next(killed);
	Buffs_MEODP_Point_Detach(self);
}

void(void) rm_buffs_player_think {
	rm_buffs_player_think_next();
    self.buffstat = (self.buffs & (g_buffs_enabled | g_buffs_baseline));
    if(self.hg_linker)
        self.buffstat |= self.hg_linker.buffs;

    if(self.nobuffs) {
        self.effective_buffs = 0;
    } else {
        self.effective_buffs = (self.buffstat | g_buffs_baseline);
    }
    if(self.buffs != self.oldbuffs) {
		ON_BUFF_ADDED(BUFF_SUPPLY) {
			//FIXME: not the best solution
			float i;
			self.ammoclipmax = floor(self.ammoclipmax * g_buffs_supply_clip_limit_multiplier);
			if (self.items & IT_UNLIMITED_WEAPON_AMMO)
			if (self.ammoclip > 0 && self.ammoclipmax > 0) {
				WEAPON_INFO_FOR_EACH_ID(i) {
					weapon_action(i, WEAPON_REQUEST_RESETPLAYER);
				}
			}
            if(g_use_ammunition) {
                float a = g_buffs_supply_grant_ammo;
                self.ammo_cells += a;
                self.ammo_shells += a;
                self.ammo_rockets += a;
                self.ammo_nails += a;
            }
        }

        ON_BUFF_REMOVED(BUFF_SUPPLY) {
            //W_Clip_ResetAll(FALSE); //FIXME
        }

        ON_BUFF_ADDED(BUFF_GUARD) {
            //if(g_clanarena)
            //    self.health = max(min(CVAR(g_clanarena_heal_limit), CVAR(g_buffs_guard_pickup_health)), self.health);
            //else {
                self.health = max(g_buffs_guard_pickup_health, self.health);
                self.armorvalue = max(g_buffs_guard_pickup_armor, self.armorvalue);
            //}
        }

        ON_BUFF_REMOVED(BUFF_VAMPIRE) {
            self.buff_vamp_ticks = self.buff_vamp_healthpool = self.buff_vamp_nexttick = 0;
        }

        ON_BUFF_ADDED(BUFF_VAMPIRE) {
            self.buff_vamp_ticks = self.buff_vamp_healthpool = self.buff_vamp_nexttick = 0;
        }

        ON_BUFF_REMOVED(BUFF_ADEPT) {
            self.hg_stealth_saved = 0;
        }

        ON_BUFF_ADDED(BUFF_STEALTH) {
            self.buff_stealth_time = -1000;
        }

        ON_BUFF_REMOVED(BUFF_CONDUIT) {
            self.buff_conduit_hpool = 0;
            self.buff_conduit_apool = 0;
        }

        ON_BUFF_REMOVED(BUFF_ENDURANCE) {
            self.buff_endur_dmgpool = 0;
        }

        self.oldbuffs = self.buffs;
    }

    if(self.buffstat) {
        if(!self.buff_model) {
            entity m = spawn();
            float bi = Buffs_TypeToIndex(self.buffstat);
            setsize(m, '0 0 -40', '0 0 40');
            m.owner = self;
            m.customizeentityforclient = Buffs_Model_Overhead_Customize;
            net_link_entity(m, FALSE, 0, Buffs_Model_Send);
            self.buff_model = m;
        }
        
        self.buff_model.buffs = self.buffstat;
        setorigin(self.buff_model, self.origin + BUFFMODEL_OVERHEAD_OFFSET);
        Buffs_Model_Update(self.buff_model);

    } else if(self.buff_model) {
        remove(self.buff_model);
        self.buff_model = NULL;
    }

    Buffs_ApplyVampire();
    Buffs_ApplyConduit();

    if(!self.buff_teamwp) {
        if(Buffs_Present(self, BUFF_MEDIC))
            Buffs_SetTeamWaypoint(self, "HEALER", Buffs_TypeToColor(BUFF_MEDIC), BUFF_MEDIC);
    } else if(!Buffs_Present(self, self.buff_teamwp.buffs))
        Buffs_RemoveTeamWaypoint(self);
    
    if(self.buff_endur_dmgpool < 0)
        self.buff_endur_dmgpool = 0;
}

#undef ON_BUFF_ADDED
#undef ON_BUFF_REMOVED

float Buffs_NadgetPower(entity plr) {
	return (Buffs_Present(plr, BUFF_WRATH) ? g_buffs_wrath_hgpower : 1);
}

float Buffs_NadgetRegen(entity plr) {
    float rscale = 1;

    if(Buffs_Present(plr, BUFF_SUPPLY))
        rscale *= g_buffs_supply_hg_regenscale;

    if(Buffs_Present(plr, BUFF_WRATH))
        rscale *= g_buffs_wrath_hgregen;

    return rscale;
}

float Buffs_NadgetCooldown(entity plr) {
    return (Buffs_Present(plr, BUFF_WRATH) ? g_buffs_wrath_hgcooldown : 1);
}

float Buffs_NadgetRegenDmgPause(entity plr) {
    return (Buffs_Present(plr, BUFF_WRATH) ? g_buffs_wrath_hgregen_damagepause : 1);
}

float Buffs_NadgetBonusMultiplier(entity plr) {
    return (Buffs_Present(plr, BUFF_WRATH) ? g_buffs_wrath_hgbonusmultiplier : 1);
}

//float Buffs_ClipLimitMultiplier(entity plr) {
//    return (Buffs_Present(plr, BUFF_SUPPLY) ? g_buffs_supply_clip_limit_multiplier : 1);
//}

float Buffs_MedicDamage(entity targ, entity attacker, entity inflictor, float damage, float deathtype, vector hitloc, vector force) {
    if(!targ.iscreature || deathtype == DEATH_RM_ENDURANCE || (DEATH_ISSPECIAL(deathtype) && !DEATH_RM_ISPROJECTED(deathtype)))
        return damage;

    if(!Buffs_Present(attacker, BUFF_MEDIC))
        return damage;

    if((team_mode && attacker.team == targ.team) || attacker == targ) {
        float heal;

        if(DEATH_RM_ISPROJECTED(deathtype))
            // arc and ignite scale off the original heal, so leave it as is
            heal = damage;
        else {
            heal = damage * g_buffs_medic_healfactor;

            if(attacker == targ)
                heal *= g_buffs_medic_selfhealfactor;

            //W_RegisterHitForHitstreak(attacker, deathtype); //FIXME

			//FIXME
            //if(damage_headshotbonus)
            //if(CVAR(g_buffs_medic_headshot))
            //if(IsHeadshot(targ, attacker, hitloc)) {
            //    heal *= 1 + damage_headshotbonus;
            //    deathtype |= HITTYPE_HEADSHOT;
            //    headshot = TRUE;
            //}
        }

        if(attacker == targ)
            force = force * g_buffs_medic_forcefactor_self;
        else
            force = force * g_buffs_medic_forcefactor_team;

        heal = Buffs_IgniteDamage(targ, attacker, inflictor, heal, deathtype);
        heal = rm_heal(targ, inflictor, attacker, heal, 0, g_buffs_medic_maxhealth, 0, deathtype, g_buffs_medic_pauserot, 0, hitloc, force);

		//FIXME
        //targ.hg_plasmalock = 0;

        if(attacker != targ)
            Buffs_VampireDamage(attacker, attacker, heal * g_buffs_medic_selfhealfactor, deathtype);

        if(!DEATH_RM_ISPROJECTED(deathtype))
            Buffs_ArcDamage(targ, attacker, heal, deathtype);

        return -1;
    } else/* if(!g_clanarena)*/ if(!attacker.hg_shield) if(!DEATH_RM_ISPROJECTED(deathtype))
        damage = damage * g_buffs_medic_damagefactor;

    return damage;
}

float Buffs_IgniteDamage(entity targ, entity attacker, entity inflictor, float damage, float deathtype) {
	float diffteam;
    if(damage)
    if(targ != attacker)
    if(targ != inflictor)
    if(attacker.classname == "player")
    if(DEATH_NADGETTYPE(deathtype) != NADGET_TRANSLOC)
    if(!DEATH_ISSPECIAL(deathtype) || deathtype == DEATH_RM_ARC)
    if(Buffs_Present(attacker, BUFF_IGNITE))
    if((diffteam = team_is_different_teams(attacker, targ)) || Buffs_Present(attacker, BUFF_MEDIC)) {
        float fdamage = damage * g_buffs_ignite_damage_fire;

        if(!diffteam || Buffs_TenacityDamage(targ, attacker, fdamage, DEATH_RM_IGNITE))
            fire_add_damage(targ, attacker, fdamage, g_buffs_ignite_burntime, DEATH_RM_IGNITE);

        damage = damage * g_buffs_ignite_damage_base;
    }
    
    return damage;
}

float Buffs_TenacityDamage(entity targ, entity attacker, float damage, float deathtype) {
    if(!Buffs_Present(targ, BUFF_TENACITY))
        return damage;
    
    // do not use DEATH_ISPROJECTED here, we don't want to mitigate DEATH_ENDURANCE
    if(DEATH_ISSPECIAL(deathtype) && deathtype != DEATH_RM_ARC && deathtype != DEATH_RM_IGNITE)
        return damage;
    
    if(targ == attacker)
        return damage * g_buffs_tenacity_takedamage_self;
    
    if(DEATH_ISNADGET(deathtype) || (deathtype & HITTYPE_SPLASH) || deathtype == DEATH_RM_ARC || deathtype == DEATH_RM_IGNITE)
        return damage * g_buffs_tenacity_takedamage_aoe;
    
    return damage * g_buffs_tenacity_takedamage;
}

void Buffs_VampireDamage(entity targ, entity a, float damage, float deathtype) {
    if(damage <= 0 || !Buffs_Present(a, BUFF_VAMPIRE))
        return;
    
    // paranoid sanity check, should not happen
    if((!a.buff_vamp_ticks  &&  a.buff_vamp_healthpool) ||
        (a.buff_vamp_ticks  && !a.buff_vamp_healthpool))
        a.buff_vamp_ticks = a.buff_vamp_healthpool = 0;
    
    float ticks = g_buffs_vampire_time;
    float factor = g_buffs_vampire_factor;
    
    if(ticks > 0) {
        // refresh duration, extend the pool
        a.buff_vamp_ticks = ticks;
        a.buff_vamp_healthpool += damage * factor;
    } else {
        // instant-healing mode, don't use the buffer, just heal
        rm_heal(a, NULL, a, damage * factor, 0, g_buffs_vampire_limit, 0, DEATH_RM_VAMPIRE, g_buffs_vampire_pauserot, 0, '0 0 0', '0 0 0');
    }
}

void Buffs_WrathDamage(entity targ, entity attacker, float damage, float deathtype) {
    float wrath = Buffs_Present(attacker, BUFF_WRATH) * g_buffs_wrath_hgregen_fromdamage;

    if(!wrath)
        return;

    NADGET_DO_IN_ALL_CONTEXTS({
        nadget_AdvanceRegen(attacker, damage * wrath, nadget_StorageLimit(attacker));
    }, self.hg_type2)
}

void Buffs_ArcDamage(entity targ, entity attacker, float damage, float deathtype) {
    if(!Buffs_Present(attacker, BUFF_ARC))
        return;

    float mul;

    if(DEATH_ISNADGET(deathtype))
        mul = g_buffs_arc_multiplier_hg;
    else
        mul = g_buffs_arc_multiplier;

    if(mul <= 0)
        return;

    arc_damage(targ, attacker, damage, DEATH_RM_ARC,
        g_buffs_arc_range, mul,
        g_buffs_arc_pushback, COLOR_TEAM2, buffs_arc_hit
    );
}

void Buffs_ConduitDamage(entity targ, entity attacker, float hdamage, float adamage, float deathtype, float is_heal) {
    if(!(hdamage + adamage))
        return;

    if(!Buffs_Present(targ, BUFF_CONDUIT))
        return;

    if(deathtype == DEATH_RM_CONDUIT || DEATH_NADGETTYPE(deathtype) == NADGET_LINKER)
        return;

    float f_heal = (
        is_heal ? g_buffs_conduit_factor_heal_to_heal : g_buffs_conduit_factor_damage_to_heal);

    float f_dmg = (
			is_heal ?
			g_buffs_conduit_factor_heal_to_damage :
			g_buffs_conduit_factor_damage_to_damage
			);
    targ.buff_conduit_hpool += hdamage * f_heal;
    targ.buff_conduit_apool += adamage * f_heal;
    targ.buff_conduit_dpool += (hdamage + adamage) * f_dmg;
}

float(entity e) Buffs_Endurance_GetDOT_Filter {
	return e.owner == other && e.enemy == self && e.classname == "buff_endur_dot";
}

void Buffs_Endurance_DOT_Think(void) {
	float ticks = self.buff_endur_ticks;
	entity targ = self.enemy;

	if(PLAYER_DEAD(targ)) {
		remove(self);
		return;
	}

	float _damage = min(self.buff_endur_dmgpool / self.buff_endur_ticks, targ.buff_endur_dmgpool);

	if(_damage <= 0) {
		remove(self);
		return;
	}

	damage(targ, self, self.owner, _damage, DEATH_RM_ENDURANCE, targ.origin, '0 0 0');

	targ.buff_endur_dmgpool -= _damage;
	self.buff_endur_dmgpool -= _damage;
	self.buff_endur_ticks -= 1;

	if(!self.buff_endur_ticks) {
		remove(self);
		return;
	}

	self.nextthink = time + 1;
}

entity Buffs_Endurance_GetDOT(entity targ, entity attacker) {
	entity oldself = self;
	entity oldother = other;
	self = targ;
	other = attacker;
	entity dot = rm_findfilter(NULL, Buffs_Endurance_GetDOT_Filter);
	self = oldself;
	other = oldother;

	if(dot)
		return dot;

	entity e = spawn();
	e.classname = "buff_endur_dot";
	e.owner = attacker;
	e.enemy = targ;
	e.reset = stdproc_remove;
	e.think = Buffs_Endurance_DOT_Think;
	e.nextthink = time + 1;
	return e;
}

entity Buffs_Endurance_ApplyDOT(entity targ, entity attacker, float ticks, float damage) {
    targ.buff_endur_dmgpool += damage;

    entity dot = Buffs_Endurance_GetDOT(targ, attacker);
    dot.buff_endur_dmgpool += damage;
    dot.buff_endur_ticks = ticks;

    return dot;
}

float Buffs_EnduranceDamage(entity targ, entity attacker, float damage, float deathtype) {
    if(deathtype == DEATH_RM_ENDURANCE || damage <= 0 || !Buffs_Present(targ, BUFF_ENDURANCE))
        return damage;

    float ticks = g_buffs_endurance_damage_dot_duration;
    float direct = damage * g_buffs_endurance_damage_direct;
    float dot = damage * g_buffs_endurance_damage_dot;
    
    if(dot > 0)
        Buffs_Endurance_ApplyDOT(targ, attacker, ticks, dot);

    return direct;
}

void Buffs_ReaperFrag(entity targ, entity attacker) {
    if(!Buffs_Present(attacker, BUFF_REAPER) && !Buffs_Present(targ, BUFF_REAPER))
        return;

    float newbuffs = targ.buffs;
    newbuffs &= ~(BUFF_REAPER | g_buffs_reaper_buff_banmask);
    Buffs_Give(attacker, newbuffs, 0);
}

#define meodp_rand1 health
#define meodp_rand2 armorvalue
#define meodp_rand3 cnt
#define meodp_rand4 armortype

void Buffs_MEODP_Point_Think(void) {
    if(!self.owner || wasfreed(self.owner)) {
		antilag_remove(self);
        remove(self);
        return;
    }

    entity ref = self.owner;
    while(ref.meodp_point_ref)
        ref = ref.meodp_point_ref;

    if(ref.iscreature)
        makevectors('0 0 0');
    else
        makevectors(ref.angles + ref.meodp_point_angleoffs);

    float dst = vlen(ref.maxs_x * '1 0 0' + ref.maxs_y * '0 1 0' - ref.mins_x * '1 0 0' - ref.mins_y * '0 1 0');
    dst = max(20, dst);

    float t1 = self.meodp_rand3 * time + self.meodp_rand1;
    float t2 = self.meodp_rand4 * time * 1.521 + self.meodp_rand2;

    vector o = ref.meodp_point_offs + (ref.absmax + ref.absmin) * 0.5;
    vector t = o + (v_forward * sin(t1) + v_right * cos(t1)) * dst * (1 + 0.05 * sin(t2));

    trace_box(o, self.mins, self.maxs, t, TRACE_MOVE_WORLDONLY, self);
    setorigin(self, trace_endpos);
    
    self.nextthink = time;
}

float Buffs_MEODP_Point_VisibleForPlayer(entity p, entity plr) {
    if(!Buffs_Present(plr, BUFF_MEODP))
        return FALSE;
    
	if (p.owner.iscreature)
	if (p.owner.deadflag != DEAD_FREEZE && !team_is_different_teams(p.owner, plr))
			return FALSE;

    return TRUE;
}

float Buffs_MEODP_Point_Customize(void) {
	if (other.classname == "spectator")
		return Buffs_MEODP_Point_VisibleForPlayer(self, other);

	return Buffs_MEODP_Point_VisibleForPlayer(self, other);
}

void Buffs_MEODP_TriggerDeath(entity targ, entity attacker, entity inflictor) {
    float oh = max(0, targ.health);
    float oa = max(0, targ.armorvalue);
    vector point_org = targ.meodp_point.origin;

	entity oldself = self;
	self = targ;
	targ.meodp_point.solid = SOLID_NOT;
	targ.meodp_point.enemy = attacker;
	//FIXME
	//te_meodp(targ.meodp_point.origin);
	targ.meodp_death(attacker, inflictor);
	if(targ.meodp_point && !wasfreed(targ.meodp_point))
		targ.meodp_point.enemy = NULL;

    self = oldself;
    float nh = bound(0, targ.health, oh);
    float na = bound(0, targ.armorvalue, oa);
    float sdmg = max(((oh - nh) + (oa - na)) * g_buffs_meodp_selfdamage, g_buffs_meodp_selfdamage_min);
    if(sdmg) {
        damage(attacker, inflictor, attacker, sdmg, DEATH_RM_MEODP, attacker.origin, '0 0 0');
        trailparticles(attacker, particleeffectnum("blood"), point_org, attacker.origin + attacker.view_ofs);
    }
}

float buffs_meodp_triggermultiple_running;

void Buffs_MEODP_TriggerDeath_Multiple(entity attacker, entity inflictor, float(entity, entity) filter, entity pass) {
    if(buffs_meodp_triggermultiple_running) {
        backtrace("Buffs_MEODP_TriggerDeath_Multiple called recursively");
        return;
    }

    buffs_meodp_triggermultiple_running = TRUE;

    entity p = NULL;
    for(;(p = find(p, classname, "meodp_point"));)
        if(filter(p.owner, pass))
            Buffs_MEODP_TriggerDeath(p.owner, attacker, inflictor);

    buffs_meodp_triggermultiple_running = FALSE;
}

float Buffs_MEODP_Filter_NearbyRelated(entity ent, entity pass) {
    if(ent.owner != pass.owner)
        return FALSE;
    
    if(ent.classname != pass.classname)
        return FALSE;

    if(vlen(ent.meodp_point.origin - pass.meodp_point.origin) > 200)
        return FALSE;

    return TRUE;
}

void Buffs_MEODP_Point_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
    if(self.solid == SOLID_NOT || damage_radius_running)
        return; // hitscan only
    
    if(!damage)
        return;
    
    if(!Buffs_MEODP_Point_VisibleForPlayer(self, attacker))
        return;
    
    Buffs_MEODP_TriggerDeath(self.owner, attacker, inflictor);
}

void Buffs_MEODP_Point_Attach(entity e, meodp_death_f death) {
    if(!g_buffs_meodp)
        return;
    
    if(e.meodp_point)
        return;
    
    entity p = spawn();
    p.classname = "meodp_point";
    p.owner = e;
    p.customizeentityforclient = Buffs_MEODP_Point_Customize;
    p.think = Buffs_MEODP_Point_Think;
    p.nextthink = time;
    p.solid = SOLID_NOT;
    p.colormod = '-10 -10 -10';
    p.glow_size = 256;
    p.glow_trail = 1;
    p.glow_color = 251;
    p.meodp_rand1 = random() * MATH_PI * 2;
    p.meodp_rand2 = random() * MATH_PI * 2;
    p.meodp_rand3 = ((random() < 0.5) ? 1 : -1);
    p.meodp_rand4 = ((random() < 0.5) ? 1 : -1);
    p.takedamage = DAMAGE_NO;
    p.event_damage = Buffs_MEODP_Point_Damage;
    setmodel(p, "models/runematch/rune.mdl");
    setsize(p, '-8 -8 -8', '8 8 8');
	antilag_add(p);
    e.meodp_point = p;
    e.meodp_death = death;
}

void Buffs_MEODP_Point_Detach(entity e) {
    if(!e.meodp_point)
        return;

	antilag_remove(e.meodp_point);
    remove(e.meodp_point);
    e.meodp_point = NULL;
    e.meodp_death = NULL;
}

.entity meodp_chain;

entity Buffs_MEODP_Hitscan_Begin(entity plr) {
    if(!Buffs_Present(akimbo_owner(plr), BUFF_MEODP))
        return NULL;
    
    entity p, pts = findchain_tofield(classname, "meodp_point", meodp_chain);
    
    for(p = pts; p; p = p.meodp_chain) {
        p.solid = SOLID_CORPSE;
        p.takedamage = DAMAGE_AIM;
    }
        
    return pts;
}

void Buffs_MEODP_Hitscan_End(entity pts) {
    entity p; for(p = pts; p; p = p.meodp_chain) {
        p.solid = SOLID_NOT;
        p.takedamage = DAMAGE_NO;
    }
}

void Buffs_MEODP_Death_Player(entity attacker, entity inflictor) {
    float d = self.health * g_buffs_meodp_healthfactor + self.armorvalue * g_buffs_meodp_armorfactor;
    damage(self, inflictor, attacker, d, DEATH_RM_MEODP, self.meodp_point.origin, '0 0 0');
}

void Buffs_MEODP_Death_Remove(entity attacker, entity inflictor) {
    remove(self);
}

void Buffs_MEODP_Death_Use(entity attacker, entity inflictor) {
    self.use();
}

void Buffs_MEODP_Death_Remove_Multiple(entity attacker, entity inflictor) {
    if(buffs_meodp_triggermultiple_running) {
        Buffs_MEODP_Death_Remove(attacker, inflictor);
        return;
    }

    Buffs_MEODP_TriggerDeath_Multiple(attacker, inflictor,
                                      Buffs_MEODP_Filter_NearbyRelated, self);
}

void Buffs_MEODP_Death_Use_Multiple(entity attacker, entity inflictor) {
    if(buffs_meodp_triggermultiple_running) {
        Buffs_MEODP_Death_Use(attacker, inflictor);
        return;
    }

    Buffs_MEODP_TriggerDeath_Multiple(attacker, inflictor,
                                      Buffs_MEODP_Filter_NearbyRelated, self);
}

float Buffs_BuffPickup_PickupAllowed(entity buff, entity plr) {
    float allowReplace = g_buffs_replace;

    if(allowReplace > 1)
        allowReplace = plr.BUTTON_USE;

    return (((plr.buffs & buff.buffs) != buff.buffs) && (!plr.buffs || g_buffs_stack || allowReplace));
}

float Buffs_BuffPickup_Waypoint_VisibleForPlayer(entity plr) {
    if((!self.owner.buff_active && !self.owner.buff_activetime) || !Buffs_BuffPickup_PickupAllowed(self.owner, plr))
        return FALSE;
    return WaypointSprite_visible_for_player(plr);
}

void Buffs_BuffPickup_SpawnWaypoint(entity e) {
    vector c = Buffs_TypeToColor(e.buffs);
    str_unzone_ifneeded(e.netname);
    e.netname = str_zone_ifneeded(Buffs_TypeToExpandedName(e.buffs, "+", 0));
    WaypointSprite_Spawn(e.netname, 0, 0, e, '0 0 40', NULL, e.team, e, buff_waypoint, TRUE);
    //WaypointSprite_UpdateTextColors(e.buff_waypoint,c, '0 0 0', '0 0 0');
    WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_FLAG, c);
    e.buff_waypoint.waypointsprite_visible_for_player = Buffs_BuffPickup_Waypoint_VisibleForPlayer;
    
    if(e.buff_activetime/* && (roundstate == ROUNDSTATE_GAME || roundstate == ROUNDSTATE_INITIAL_WARMUP)*/)
        WaypointSprite_UpdateBuildFinished(e.buff_waypoint, time + e.buff_activetime);
}

void Buffs_BuffPickup_SetCooldown(entity buff, float cd) {
    cd = max(0, cd);
    
    if(!buff.buff_waypoint)
        Buffs_BuffPickup_SpawnWaypoint(buff);
    
    WaypointSprite_UpdateBuildFinished(buff.buff_waypoint, time + cd);
    buff.buff_activetime = cd;
    buff.buff_active = !cd;
}

float Buffs_BuffPickup_GetShortestCooldown(void) {
    return min(
			g_buffs_activate_delay, min(
			g_buffs_activate_delay_dual, min(
			g_buffs_reactivate_delay,
			g_buffs_reactivate_delay_dual)));
}

void Buffs_BuffPickup_SetInitialCooldown(entity buff) {
    Buffs_BuffPickup_SetCooldown(buff,
        //if(roundstate == ROUNDSTATE_INITIAL_WARMUP)
        //    Buffs_BuffPickup_GetShortestCooldown()
        //else
        (buff.buffs & (buff.buffs - 1)) ? g_buffs_activate_delay_dual : g_buffs_activate_delay);
}

void Buffs_BuffPickup_SetReactivateCooldown(entity buff) {
    Buffs_BuffPickup_SetCooldown(buff, (
        //if(roundstate == ROUNDSTATE_INITIAL_WARMUP)
        //    Buffs_BuffPickup_GetShortestCooldown()
        //else
        (buff.buffs & (buff.buffs - 1)) ? g_buffs_reactivate_delay_dual : g_buffs_reactivate_delay) + frametime);
}

void Buffs_BuffPickup_Think(void) {
    if(time < 1)
        return;
    
    if(self.buff_lockon)
    if(time > self.buff_lockon_updatetime)
        self.buff_lockon = NULL;
    
    //if(roundstate == ROUNDSTATE_GAME || roundstate == ROUNDSTATE_INITIAL_WARMUP)
    if(!self.buff_activetime_updated) {
        Buffs_BuffPickup_SetCooldown(self, self.buff_activetime);
        self.buff_activetime_updated = TRUE;
    }
    
    if(self.buffs != self.oldbuffs) {
        if(self.buff_waypoint) {
            WaypointSprite_Disown(self.buff_waypoint, 1);
            Buffs_BuffPickup_SpawnWaypoint(self);
        }
        
        self.SendFlags |= 4;
        self.oldbuffs = self.buffs;
    }
    
    if(!self.buff_active && !self.buff_activetime)
    if(/*roundstate == ROUNDSTATE_INITIAL_WARMUP ||*/!((self.owner.buffs & self.buffs) == self.buffs) || PLAYER_DEAD(self.owner)) {
        if(self.owner.buff_cdoverride) {
            Buffs_BuffPickup_SetCooldown(self, max(0, self.owner.buff_cdoverride) + frametime);
            self.owner.buff_cdoverride = 0;
        } else
            Buffs_BuffPickup_SetReactivateCooldown(self);
        self.owner = NULL;
    }
    
    if(self.buff_activetime) {
        /*if(roundstate == ROUNDSTATE_GAME || roundstate == ROUNDSTATE_INITIAL_WARMUP)*/{
            self.buff_activetime = max(0, self.buff_activetime - frametime);
            
            if(!self.buff_activetime) {
                self.buff_active = TRUE;
                sound(self, CHAN_TRIGGER, "misc/strength_respawn.wav", VOL_BASE, ATTN_NORM); 
            }
        }
    }
    
    if(self.buff_active && !self.buff_waypoint)
        Buffs_BuffPickup_SpawnWaypoint(self);

    self.nextthink = time;
    self.angles_y = time * 110.1;

    Buffs_Model_Update(self);
}

void Buffs_BuffPickup_ResetWaypoint(void) {
    if(self.buff_waypoint)
        WaypointSprite_Kill(self.buff_waypoint);
    
    if(self.buff_activetime)
        Buffs_BuffPickup_SpawnWaypoint(self);
}

void Buffs_BuffPickup_Reset(void) {
    self.owner = NULL;
    Buffs_BuffPickup_SetInitialCooldown(self);
    Buffs_BuffPickup_ResetWaypoint();
    self.buff_activetime_updated = FALSE;
    Buffs_Model_Update(self);
}

void Buffs_BuffPickup_GiveTo(entity plr) {
    if(self.owner || !Buffs_BuffPickup_PickupAllowed(self, plr))
        return;
    
    self.owner = plr;
    self.buff_active = FALSE;
    
    if(g_buffs_replace)
        plr.buffs = 0;

    Buffs_Give(plr, self.buffs, self.team);
}

void Buffs_BuffPickup_Touch(void) {
    if(self.team && other.team != self.team)
        return;
    
    if(other.classname != "player")
        return;
    
    if(PLAYER_DEAD(other))
        return;

    if(!self.buff_active) {
        if(g_buffs_lockon && (!self.buff_lockon || self.buff_lockon == other)) {
            self.buff_lockon = other;
            self.buff_lockon_updatetime = time + 0.5;
        }
        return;
    }
    
    if(self.buff_lockon && self.buff_lockon != other)
        return;
    
    Buffs_BuffPickup_GiveTo(other);
    self.buff_lockon = NULL;
}

void Buffs_BuffPickup_TeamSwap(void) {
    self.team = team_next(self.team);
    if(self.buff_waypoint)
        self.buff_waypoint.team = self.team;
}

void Buffs_BuffPickup_Setup(void) {
    if(!g_buffs || (self.team && !team_mode) || (g_buffs_team_only && !self.team)) {
        remove(self);
        return;
    }
    
    if(g_buffs_random_spawns == 1 && self.classname != "item_buff_randomspawn") {
        remove(self);
        return;
    }

    if not(g_buffs_randomize)
    if((g_buffs_enabled & self.buffs) != self.buffs && self.buffs != BUFF_RANDOM) {
        remove(self);
        return;
    }
    
    if(g_buffs_noteam)
        self.team = 0;
        
    if(g_buffs_team_swap)
        self.team = team_next(self.team);
    
    self.origbuffs = self.buffs;
    
    if(time > 1)
    if(self.buffs == BUFF_RANDOM)
        self.buffs = Buffs_Randomize_Yield();
    
    self.classname = "item_buff";
    self.flags = FL_ITEM;
    self.solid = SOLID_TRIGGER;
    self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
    self.movetype = MOVETYPE_TOSS;
    self.think = Buffs_BuffPickup_Think;
    self.touch = Buffs_BuffPickup_Touch;
    self.reset = Buffs_BuffPickup_Reset;
    self.teamswap = Buffs_BuffPickup_TeamSwap;
    self.nextthink = time;
    Buffs_BuffPickup_SetInitialCooldown(self);
    self.buff_active = !self.buff_activetime;
    self.gravity = 100;
    
    setsize(self, '-15 -15 -40', '15 15 40');
    
    entity_move_out_of_solid_with_type(self, TRACE_MOVE_WORLDONLY);
	builtin_droptofloor();
    net_link_entity(self, FALSE, 0, Buffs_Model_Send);

    ++g_buffs_count;
}

void Buffs_BuffPickup_Remove(void) {
    if(self.buff_waypoint)
        WaypointSprite_Kill(self.buff_waypoint);
    remove(self);
}

void Buffs_BuffPickup_Placeholder(void) {
    if(!g_buffs || !g_buffs_spawn_on_powerups || g_buffs_team_only)
        return;
    
    entity e = spawn();
    setorigin(e, self.origin);
    e.owner = self;
    e.classname = "buff_placeholder";
}

void Buffs_BuffPickup_SetupQ3TACompat(string rune) {
    if(self.spawnflags & 2)
        self.team = COLOR_TEAM1;
    else if(self.spawnflags & 4)
        self.team = COLOR_TEAM2;
    
    if not((self.buffs = Buffs_NameToType(cvar_string(strcat("g_buffs_q3ta_", rune))))) {
        remove(self);
        return;
    }
    
    Buffs_BuffPickup_Setup();
}

#define BUFF_SPAWNFUNC(e,b,t) void spawnfunc_item_buff_##e() { self.buffs = b; self.team = t; Buffs_BuffPickup_Setup(); }
#define BUFF_SPAWNFUNC_Q3TA_COMPAT(o,r) void spawnfunc_##o() { Buffs_BuffPickup_SetupQ3TACompat(r); }
#define BUFF_SPAWNFUNCS(e,b)                         \
        BUFF_SPAWNFUNC(e,           b,  0)           \
        BUFF_SPAWNFUNC(e##_team1,   b,  COLOR_TEAM1) \
        BUFF_SPAWNFUNC(e##_team2,   b,  COLOR_TEAM2) \
        BUFF_SPAWNFUNC(e##_team3,   b,  COLOR_TEAM3) \
        BUFF_SPAWNFUNC(e##_team4,   b,  COLOR_TEAM4) 

#define BUFFDEF(id,shortname,longname,color) \
        BUFF_SPAWNFUNCS(shortname, id)

BUFFDEFS

#undef BUFFDEF

BUFF_SPAWNFUNCS(random,     BUFF_RANDOM)

// older RM compatibility
BUFF_SPAWNFUNCS(bash,       BUFF_IGNITE)
BUFF_SPAWNFUNCS(focus,      BUFF_CONDUIT)

// q3ta compatibility
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_doubler,    "doubler")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_guard,      "guard")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_scout,      "scout")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_ammoregen,  "ammoregen")


//
// Some advanced entities for mappers
//

enum {
    TBUFFS_AND,
    TBUFFS_OR,
    TBUFFS_NOT,
};

void(void) target_buffs_use {
	if(PLAYER_DEAD(activator))
		return;

	float cbuffs = activator.buffs;
	float mbuffs = self.buffs;

	if(self.cnt)
		mbuffs = rm_randombits(mbuffs, self.cnt, FALSE);

	if(self.spawnflags & TBUFFS_NOT)
		mbuffs = ~mbuffs;

	if(self.spawnflags & TBUFFS_AND) {
		cbuffs = cbuffs & mbuffs;
	} else if(self.spawnflags & TBUFFS_OR) {
		cbuffs = cbuffs | mbuffs;
	} else {
		activator.buffs = 0;
		cbuffs = mbuffs;
	}

	Buffs_Give(activator, cbuffs, 0);
	activator.buffs = cbuffs;
}

void spawnfunc_target_buffs(void) {
    self.classname = "target_buffs";

    if(self.netname)
        self.buffs = (Buffs_ParseList(self.netname) & g_buffs_enabled);
    else
        self.buffs = g_buffs_enabled;

    self.cnt = floor(max(0, self.cnt));

    self.use = target_buffs_use;
}
