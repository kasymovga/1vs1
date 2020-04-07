string sv_player_hat;
string sv_player_hat_attachment;
float sv_player_hat_scale;
vector sv_player_hat_origin, sv_player_hat_angles;
.entity hat;

var void(float killed) hat_PlayerClear_NextLink;
void(float killed) hat_PlayerClear {
	if (self.hat)
	if (!killed || PLAYER_REALLY_DEAD(self)) {
		remove(self.hat);
		self.hat = world;
	}
	hat_PlayerClear_NextLink(killed);
}

var void(entity spot) hat_Spawn_NextLink;
void(entity spot) hat_Spawn {
	self.hat = spawn();
	setmodel(self.hat, sv_player_hat);
	self.hat.owner = self;
	self.hat.scale = sv_player_hat_scale;
	setattachment(self.hat, self.body, sv_player_hat_attachment);
	self.hat.angles = sv_player_hat_angles;
	setorigin(self.hat, sv_player_hat_origin);
	self.hat.customizeentityforclient = weapon_model_exterior_customize;
	hat_Spawn_NextLink(spot);
}

void(void) hat_init {
	sv_player_hat = cvar_string_zone_ifneeded("sv_player_hat");
	if (sv_player_hat != "") {
		sv_player_hat_attachment = cvar_string_zone_ifneeded("sv_player_hat_attachment");
		sv_player_hat_scale = cvar("sv_player_hat_scale");
		sv_player_hat_origin = stov(cvar_string("sv_player_hat_origin"));
		sv_player_hat_angles = stov(cvar_string("sv_player_hat_angles"));
		precache_model(sv_player_hat);
		hat_PlayerClear_NextLink = gamehook_chain_player_clear;
		gamehook_chain_player_clear = hat_PlayerClear;
		hat_Spawn_NextLink = gamehook_chain_spawn;
		gamehook_chain_spawn = hat_Spawn;
	}
}
