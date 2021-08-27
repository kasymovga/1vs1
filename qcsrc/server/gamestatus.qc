entity game_status;

#define gamestatus_send GameStatus_SendEntity
float(entity to, float sf) gamestatus_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_GAMESTATUS);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1)
		net_write_string(MSG_ENTITY, self.message);

	if (sf & 2)
		net_write_byte(MSG_ENTITY, self.alpha * 100);

	return TRUE;
}

#define gamestatus_think GameStatus_Think
void(void) gamestatus_think {
	self.alpha = self.alpha - frametime;
	self.nextthink = time;
	if (self.alpha <= 0) {
		str_unzone_ifneeded(self.message);
		remove(self);
		game_status = world;
	} else
		self.SendFlags |= 2;
}

void(string status, float _delay) gamestatus_set {
	if not(game_status) {
		game_status = spawn();
		net_link_entity(game_status, FALSE, 0, gamestatus_send);
	}
	if (game_status.message != status) {
		str_unzone_ifneeded(game_status.message);
		game_status.message = str_zone_ifneeded(status);
		game_status.SendFlags |= 1;
	}
	if (game_status.alpha != 1) {
		game_status.alpha = 1;
		game_status.SendFlags |= 2;
	}
	game_status.nextthink = time + _delay;
	game_status.think = gamestatus_think;
}
