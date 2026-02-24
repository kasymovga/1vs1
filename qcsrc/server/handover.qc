string g_handover_hat;
string g_handover_hat_attachment;
float g_handover_hat_scale;
vector g_handover_hat_origin;
vector g_handover_hat_angles;
float g_handover_hat_q3_scale;
vector g_handover_hat_q3_origin;
vector g_handover_hat_q3_angles;

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
			if (g_handover_model != "") {
				print_all(PRINT_INFO, "{1}^7 got special model", handover_player.netname, "", "");
				player_body_reset(handover_player);
			}
			if (g_handover_hat != "") {
				print_all(PRINT_INFO, "{1}^7 got hat", handover_player.netname, "", "");
				hat_add(handover_player, g_handover_hat, g_handover_hat_scale,
						g_handover_hat_attachment, g_handover_hat_origin, g_handover_hat_angles,
						g_handover_hat_q3_scale, g_handover_hat_q3_origin, g_handover_hat_q3_angles);
			}
		}
	}
	self.nextthink = time + 1;
}

var float(entity attacker, entity targ, float f) handover_score_give_frag_mod_next;
float(entity attacker, entity targ, float f) handover_score_give_frag_mod {
	if (targ == handover_player)
	if (attacker != targ)
	if (attacker.classname == "player") {
		if (g_handover_model != "") {
			print_all(PRINT_INFO, "{1}^7 steal special model from {2}", attacker.netname, targ.netname, "");
			print_to_spec(attacker, PRINT_CENTER, "^7You steal special model from {1}", targ.netname, "", "");
			print_to_spec(targ, PRINT_CENTER, "^7{1}^7 steal special model from you", attacker.netname, "", "");
			player_body_reset(attacker);
			player_body_reset(targ);
		}
		if (g_handover_hat != "") {
			print_all(PRINT_INFO, "{1}^7 steal hat from {2}", attacker.netname, targ.netname, "");
			print_to_spec(attacker, PRINT_CENTER, "^7You steal hat from {1}", targ.netname, "", "");
			print_to_spec(targ, PRINT_CENTER, "^7{1}^7 steal hat from you", attacker.netname, "", "");
			hat_remove(targ);
			hat_add(attacker, g_handover_hat, g_handover_hat_scale,
					g_handover_hat_attachment, g_handover_hat_origin, g_handover_hat_angles,
					g_handover_hat_q3_scale, g_handover_hat_q3_origin, g_handover_hat_q3_angles);
		}
		handover_player = attacker;
	}
	return handover_score_give_frag_mod_next(attacker, targ, f);
}

float(void) handover_hat_callback {
	if (self == handover_player) {
		hat_add(self, g_handover_hat, g_handover_hat_scale,
				g_handover_hat_attachment, g_handover_hat_origin, g_handover_hat_angles,
				g_handover_hat_q3_scale, g_handover_hat_q3_origin, g_handover_hat_q3_angles);
		return TRUE;
	}
	return FALSE;
}

void(void) handover_init {
	CVAR_CACHE_STR(g_handover_hat);
	CVAR_CACHE(g_handover_hat_scale);
	CVAR_CACHE_STR(g_handover_hat_attachment);
	CVAR_CACHE_VEC(g_handover_hat_origin);
	CVAR_CACHE_VEC(g_handover_hat_angles);
	CVAR_CACHE(g_handover_hat_q3_scale);
	CVAR_CACHE_VEC(g_handover_hat_q3_origin);
	CVAR_CACHE_VEC(g_handover_hat_q3_angles);
	CVAR_CACHE_STR(g_handover_model);
	if (g_handover_hat == "")
	if (g_handover_model == "")
		return;

	if (g_handover_model != "") {
		player_body_precache(g_handover_model);
		handover_player_body_model_list_allowed_mod_next = plugin_chain_player_body_model_list_allowed_mod;
		plugin_chain_player_body_model_list_allowed_mod = handover_player_body_model_list_allowed_mod;
	}
	if (g_handover_hat != "") {
		precache_model(g_handover_hat);
		hat_init_custom(handover_hat_callback);
	}
	handover_controller = spawn();
	handover_controller.classname = "handover_controller";
	handover_controller.think = handover_controller_think;
	handover_controller.nextthink = time + 5;
	handover_score_give_frag_mod_next = plugin_chain_score_give_frag_mod;
	plugin_chain_score_give_frag_mod = handover_score_give_frag_mod;
}
