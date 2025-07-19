string g_handover_model;

entity handover_player;
entity handover_controller;

var string(string m) handover_player_body_model_list_allowed_mod_next;
string(string m) handover_player_body_model_list_allowed_mod {
	if (self == handover_player) {
		return g_handover_model;
	}
	return handover_player_body_model_list_allowed_mod_next(m);
};

void(void) handover_controller_think {
	entity e;
	if (clienttype(handover_player) == CLIENTTYPE_DISCONNECTED
			|| (handover_player.classname != "player" &&
			!(handover_player.classname == "observer" && handover_player.team > 0)))
		handover_player = NULL;

	if not(handover_player) {
		random_selection_init();
		PLAYER_FOR_EACH(e) {
			random_selection_add(e, 0, NULL, 1, 1);
		}
		if (random_selection_chosen_ent) {
			handover_player = random_selection_chosen_ent;
			print_all(PRINT_INFO, "{1}^7 get special model", handover_player.netname, "", "");
		}
	}
	self.nextthink = time + 1;
}

var float(entity attacker, entity targ, float f) handover_score_give_frag_mod_save;
float(entity attacker, entity targ, float f) handover_score_give_frag_mod {
	if (targ == handover_player)
	if (attacker.classname == "player") {
		print_all(PRINT_INFO, "{1}^7 steal special model from {2}", attacker.netname, handover_player.netname, "");
		handover_player = attacker;
		handover_player.playermodel = g_handover_model;
	}
	return handover_score_give_frag_mod_save(attacker, targ, f);
}

void(void) handover_init {
	CVAR_CACHE_STR(g_handover_model);
	if (g_handover_model == "")
		return;

	player_body_precache(g_handover_model);
	handover_player_body_model_list_allowed_mod_next = plugin_chain_player_body_model_list_allowed_mod;
	plugin_chain_player_body_model_list_allowed_mod = handover_player_body_model_list_allowed_mod;
	handover_controller = spawn();
	handover_controller.classname = "handover_controller";
	handover_controller.think = handover_controller_think;
	handover_controller.nextthink = time + 5;
	handover_score_give_frag_mod_save = plugin_score_give_frag_mod; //hack, use plugin as plugin_chain
	plugin_score_give_frag_mod = handover_score_give_frag_mod;
}
