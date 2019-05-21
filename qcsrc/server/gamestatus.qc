entity game_status;

float GameStatus_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_GAMESTATUS);
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1)
		WriteString(MSG_ENTITY, self.message);

	if (sf & 2)
		WriteByte(MSG_ENTITY, self.alpha * 100);

	return TRUE;
}

void GameStatus_Think() {
	self.alpha = self.alpha - frametime;
	self.nextthink = time;
	if (self.alpha <= 0) {
		unzone_ifneeded(self.message);
		remove(self);
		game_status = world;
	} else
		self.SendFlags |= 2;
}

void GameStatus_Set(string status, float _delay) {
	if not(game_status) {
		game_status = spawn();
		net_link_entity(game_status, FALSE, 0, GameStatus_SendEntity);
	}
	if (game_status.message != status) {
		unzone_ifneeded(game_status.message);
		game_status.message = zone_ifneeded(status);
		game_status.SendFlags |= 1;
	}
	if (game_status.alpha != 1) {
		game_status.alpha = 1;
		game_status.SendFlags |= 2;
	}
	game_status.nextthink = time + _delay;
	game_status.think = GameStatus_Think;
}
