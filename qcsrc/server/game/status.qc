entity game_status;

#define gamestatus_send GameStatus_SendEntity
float(entity to, float sf) game_status_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_GAMESTATUS);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		net_write_string(MSG_ENTITY, self.message);
		net_write_string(MSG_ENTITY, self.target);
		net_write_string(MSG_ENTITY, self.target2);
		net_write_string(MSG_ENTITY, self.target3);
	}
	if (sf & 2)
		net_write_byte(MSG_ENTITY, self.alpha * 10);

	return TRUE;
}

#define game_status_think GameStatus_Think
void(void) game_status_think {
	str_unzone_ifneeded(self.message);
	remove(self);
	game_status = NULL;
}

void(string status, float _delay, string arg1, string arg2, string arg3) game_status_set {
	RM({
		if (!game_status || game_status.message != status || game_status.nextthink + 1 < time + _delay || game_status.target != arg1 || game_status.target2 != arg2) {
			float split = strstrofs(status, "\n", 0);
			status = print_text_prepare(status, arg1, arg2, arg3);
			rm_bigprint_all(" ", " ", _delay);
			if (split >= 0) {
				rm_bigprint_all(substring(status, 0, split), substring(status, split + 1, -1), _delay);
			} else
				rm_bigprint_all(status, "", _delay);

			if not(game_status) game_status = spawn();
			str_unzone_ifneeded(game_status.message);
			game_status.message = str_zone_ifneeded(status);
			str_unzone_ifneeded(game_status.target);
			str_unzone_ifneeded(game_status.target2);
			str_unzone_ifneeded(game_status.target3);
			game_status.target = str_zone_ifneeded(arg1);
			game_status.target2 = str_zone_ifneeded(arg2);
			game_status.target3 = str_zone_ifneeded(arg3);
			game_status.nextthink = time + _delay;
			game_status.think = game_status_think;
		}
		return;
	})
	if not(game_status) {
		game_status = spawn();
		net_link_entity(game_status, FALSE, 0, game_status_send);
	}
	if (game_status.message != status || game_status.target != arg1 || game_status.target2 != arg2) {
		str_unzone_ifneeded(game_status.message);
		game_status.message = str_zone_ifneeded(status);
		str_unzone_ifneeded(game_status.target);
		str_unzone_ifneeded(game_status.target2);
		str_unzone_ifneeded(game_status.target3);
		game_status.target = str_zone_ifneeded(arg1);
		game_status.target2 = str_zone_ifneeded(arg2);
		game_status.target3 = str_zone_ifneeded(arg3);
		game_status.SendFlags |= 1;
	}
	game_status.alpha = _delay + 1;
	game_status.nextthink = time + _delay + 1;
	game_status.think = game_status_think;
	game_status.SendFlags |= 2;
}
