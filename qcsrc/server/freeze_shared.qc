float FREEZE_SHARED_SCORE_REVIVE;

var void(entity spot) freeze_shared_player_spawn_next;
void(entity spot) freeze_shared_player_spawn {
	roundbased_check_teams();
	freeze_shared_player_spawn_next(spot);
}

float(void) freeze_shared_ice_skip_think {
	return !roundbased_active;
}

void(entity unfrozer) freeze_shared_ice_unfroze {
	score_player_set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		score_player_add(unfrozer, SP_SCORE, 1);
		score_player_add(unfrozer, FREEZE_SHARED_SCORE_REVIVE, 1);
	}
}

void(void) freeze_shared_ice_frozen_status {
	score_player_set(self, SP_STATUS, 1);
}

var void(float killed) freeze_shared_player_clear_next;
void(float killed) freeze_shared_player_clear {
	score_player_set(self, SP_STATUS, 0);
	roundbased_check_teams();
	freeze_shared_player_clear_next(killed);
}

float(entity attacker, entity targ, float f) freeze_shared_score_give_frag_mod {
	score_player_add(attacker, SP_SCORE, f);
	return 0;
}

void(string gt) freeze_shared_init {
	hint_add("You can revive frozen teammates standing close to him");
	roundbased_init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	ice_hook_skip_think = freeze_shared_ice_skip_think;
	ice_hook_skip_death_handle = freeze_shared_ice_skip_think;
	ice_hook_unfroze = freeze_shared_ice_unfroze;
	ice_hook_frozen_status = freeze_shared_ice_frozen_status;
	ice_init();
	freeze_shared_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = freeze_shared_player_spawn;
	freeze_shared_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = freeze_shared_player_clear;
	plugin_score_give_frag_mod = freeze_shared_score_give_frag_mod;
	FREEZE_SHARED_SCORE_REVIVE = score_register("revs", SCORE_FLAG_SORT_PRIO_SECONDARY);
	SP_STATUS = score_register("status", 0);
}
