string sv_player_hat;
string sv_player_hat_attachment;
float sv_player_hat_scale;
vector sv_player_hat_origin, sv_player_hat_angles;
.entity hat;
var float(void) hat_custom_callback;

void(entity plr) hat_remove {
	if (self.hat) {
		str_unzone_ifneeded(plr.hat.netname);
		remove(plr.hat);
		plr.hat = NULL;
	}
}

void(entity plr) hat_attach {
	if not(plr.hat) return;
	if not(plr.body) return;
	if (plr.body.exteriorweaponentity) {
		setattachment(plr.hat, plr.body.exteriorweaponentity, ""); //quake 3 model
	} else {
		setattachment(plr.hat, plr.body, plr.hat.netname);
	}
}

var void(float killed) hat_player_clear_next;
void(float killed) hat_player_clear {
	if (!killed || PLAYER_REALLY_DEAD(self)) {
		hat_remove(self);
	}
	hat_player_clear_next(killed);
}

void(entity plr, string m, float s, string at, vector o, vector a) hat_add {
	if (plr.body)
	if not(plr.hat) {
		print("adding hat\n");
		plr.hat = spawn();
		setmodel(plr.hat, m);
		plr.hat.owner = plr;
		plr.hat.scale = s;
		plr.hat.angles = a;
		plr.hat.netname = str_zone_ifneeded(at);
		hat_attach(plr);
		setorigin(plr.hat, o);
		plr.hat.customizeentityforclient = weapon_model_exterior_customize;
	}
}

var void(entity spot) hat_player_spawn_next;
void(entity spot) hat_player_spawn {
	if (hat_custom_callback && hat_custom_callback()) {
	} else if (sv_player_hat != "")
		hat_add(self, sv_player_hat, sv_player_hat_scale, sv_player_hat_attachment, sv_player_hat_origin, sv_player_hat_angles);

	hat_player_spawn_next(spot);
}

float hat_init_common_done;
void(void) hat_init_common {
	if (hat_init_common_done) return;
	hat_init_common_done = TRUE;
	hat_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = hat_player_clear;
	hat_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = hat_player_spawn;
}

void(void) hat_init {
	CVAR_CACHE_STR(sv_player_hat);
	if (sv_player_hat != "") {
		CVAR_CACHE_STR(sv_player_hat_attachment);
		CVAR_CACHE(sv_player_hat_scale);
		CVAR_CACHE_VEC(sv_player_hat_origin);
		CVAR_CACHE_VEC(sv_player_hat_angles);
		precache_model(sv_player_hat);
		hat_init_common();
	}
}

void(float(void) cb) hat_init_custom {
	hat_custom_callback = cb;
	hat_init_common();
}
