string sv_player_hat;
string sv_player_hat_attachment;
float sv_player_hat_scale;
vector sv_player_hat_origin, sv_player_hat_angles;
.entity hat;

var void(float killed) Hat_PlayerClear_NextLink;
void Hat_PlayerClear(float killed) {
	if (self.hat)
	if (!killed || PLAYER_REALLY_DEAD(self)) {
		remove(self.hat);
		self.hat = world;
	}
	Hat_PlayerClear_NextLink(killed);
}

var void(entity spot) Hat_Spawn_NextLink;
void Hat_Spawn(entity spot) {
	self.hat = spawn();
	setmodel(self.hat, sv_player_hat);
	self.hat.scale = sv_player_hat_scale;
	setattachment(self.hat, self, sv_player_hat_attachment);
	self.hat.angles = sv_player_hat_angles;
	setorigin(self.hat, sv_player_hat_origin);
	self.hat.customizeentityforclient = CL_ExterioirWeaponentity_CustomizeEntityForClient;
	Hat_Spawn_NextLink(spot);
}

void Hat_Init() {
	sv_player_hat = cvar_string_zone_ifneeded("sv_player_hat");
	if (sv_player_hat != "") {
		sv_player_hat_attachment = cvar_string_zone_ifneeded("sv_player_hat_attachment");
		sv_player_hat_scale = cvar("sv_player_hat_scale");
		sv_player_hat_origin = stov(cvar_string("sv_player_hat_origin"));
		sv_player_hat_angles = stov(cvar_string("sv_player_hat_angles"));
		precache_model(sv_player_hat);
		Hat_PlayerClear_NextLink = GameHookChain_PlayerClear;
		GameHookChain_PlayerClear = Hat_PlayerClear;
		Hat_Spawn_NextLink = GameHookChain_Spawn;
		GameHookChain_Spawn = Hat_Spawn;
	}
}
