float g_warfog;
float g_warfog_r;
float g_warfog_g;
float g_warfog_b;
float g_warfog_alpha;
float g_warfog_fade_distance;

var float(entity plr, entity viewer, float dalpha) warfog_player_alpha_mod_next;
float(entity plr, entity viewer, float dalpha) warfog_player_alpha_mod {
	if (dalpha > 0) {
		float d = vlen(plr.origin - viewer.origin);
		float fade_start = g_warfog - g_warfog_fade_distance;
		float fog_alpha;
		if (d > fade_start) {
			fog_alpha = 1 - min((d - fade_start) / g_warfog_fade_distance, 1);
			if ((team_mode && plr.team == viewer.team) || gamehook_player_is_carrier(plr))
				fog_alpha = 0.5 + 0.5 * fog_alpha;

			dalpha = dalpha * fog_alpha;
		}
	}
	return warfog_player_alpha_mod_next(plr, viewer, dalpha);
}

void(void) warfog_init {
	CVAR_CACHE(g_warfog);
	if (g_warfog <= 0)
		return;

	CVAR_CACHE(g_warfog_fade_distance);
	CVAR_CACHE(g_warfog_r);
	CVAR_CACHE(g_warfog_g);
	CVAR_CACHE(g_warfog_b);
	CVAR_CACHE(g_warfog_alpha);
	g_warfog_fade_distance = max(1, g_warfog_fade_distance);
	warfog_player_alpha_mod_next = gamehook_chain_player_alpha_mod;
	gamehook_chain_player_alpha_mod = warfog_player_alpha_mod;
	string fog_str = strcat(ftos(g_warfog_r), " ", ftos(g_warfog_g), " ", ftos(g_warfog_b), " ", ftos(g_warfog_alpha));
	client_fog = strzone(strcat("0.5 ", fog_str, " ", ftos(g_warfog)));
}
