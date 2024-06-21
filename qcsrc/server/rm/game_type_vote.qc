string sv_rm_gametypevote;
float rm_game_type_vote_timeout;
float rm_game_type_vote_started;
float rm_game_type_vote_finished;
entity rm_game_type_vote_ent;
float rm_game_type_vote_types[10];
float rm_game_type_vote_votes[10];
string rm_game_type_vote_map;
string rm_game_type_vote_map_pic;

void(void) rm_game_type_vote_picture_send {
	map_info_get_by_name(rm_game_type_vote_map, 0, 0);
	string picture = map_info_map_image;
	if (picture == "")
		return;

	msg_entity = self;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_GAME_TYPE_VOTE_PICTURE);
	net_write_picture(MSG_ONE, picture, 3072);
}

float(entity to, float sf) rm_game_type_vote_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_RM_GAME_TYPE_VOTE);
	sf &= 3;
	net_write_byte(MSG_ENTITY, sf);
	float i;
	if (sf & 1) {
		net_write_coord(MSG_ENTITY, rm_game_type_vote_timeout - time);
		net_write_string(MSG_ENTITY, rm_game_type_vote_map);
		net_write_string(MSG_ENTITY, rm_game_type_vote_map_pic);
		string pakfile = whichpack(strcat(rm_game_type_vote_map_pic, ".tga"));
		if (pakfile == "")
			pakfile = whichpack(strcat(rm_game_type_vote_map_pic, ".jpg"));

		if (pakfile == "")
			pakfile = whichpack(strcat(rm_game_type_vote_map_pic, ".png"));

		float o;
		for (o = strstrofs(pakfile, "/", 0)+1; o > 0; o = strstrofs(pakfile, "/", 0)+1)
			pakfile = substring(pakfile, o, 999);

		net_write_string(MSG_ENTITY, pakfile);
		for (i = 0; i < 10; i++) {
			net_write_byte(MSG_ENTITY, rm_game_type_vote_types[i]);
		}
	}
	if (sf & 2) {
		for (i = 0; i < 10; i++) {
			net_write_byte(MSG_ENTITY, rm_game_type_vote_votes[i]);
		}
	}
	return TRUE;
}

float rm_game_type_vote_init_done;
void(void) rm_game_type_vote_init {
	if (rm_game_type_vote_init_done) return;
	CVAR_CACHE_STR(sv_rm_gametypevote);
	rm_game_type_vote_init_done = 1;
	string head, tail;
	tail = sv_rm_gametypevote;
	float i;
	float t;
	for (i = 0; i < 10; i++) {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "") break;
		t = game_type_from_name(head);
		if (t)
			rm_game_type_vote_types[i] = t;
		else
			i--;
	}
}

float(string nextmap) rm_game_type_vote_start {
	rm_game_type_vote_init();
	rm_game_type_vote_run = TRUE;
	if (!rm_game_type_vote_types[1]) {
		rm_game_type_vote_finished = TRUE;
		return FALSE;
	}
	rm_game_type_vote_timeout = time + cvar("sv_rm_gametypevote_timeout");
	rm_game_type_vote_ent = spawn();
	net_link_entity(rm_game_type_vote_ent, FALSE, 0, rm_game_type_vote_send);
	rm_game_type_vote_map = strzone(nextmap);
	map_info_get_by_name(rm_game_type_vote_map, 0, 0);
	string picture = map_info_map_image;
	if (picture == "")
		picture = "gfx/m_nomap";

	rm_game_type_vote_map_pic = strzone(picture);
	float t, a = 0, i;
	for (i = 0; i < 10; i++) {
		t = rm_game_type_vote_types[i] & 63;
		if not(t) break;
		if (map_info_map_supported_game_types & map_info_type_from_game_type(t)) {
			a++;
		} else
			t |= 64;

		rm_game_type_vote_types[i] = t;
	}
	if (a <= 1) {
		for (i = 0; i < 10; i++) {
			t = rm_game_type_vote_types[i];
			if not(t) break;
			if not(t & 64) {
				rm_game_type_vote_finished = TRUE;
				print("Map support only one game mode (", game_type_name(t), "), vote skipped\n");
				game_type_switch(t);
			}
		}
		return FALSE;
	}
	return TRUE;
}

float(void) rm_game_type_vote_map_info_mask {
	float mask = 0;
	rm_game_type_vote_init();
	float t;
	float i;
	for (i = 0; i < 10; i++) {
		t = rm_game_type_vote_types[i];
		mask |= map_info_type_from_game_type(t);
	}
	if (!mask) return map_info_type_from_game_type(game_type_current());
	return mask;
}

void(void) rm_game_type_vote_impulse {
	if (self.impulse >= 1 && self.impulse <= 10) {
		self.mapvote = self.impulse;
	}
}

float(void) rm_game_type_vote_think {
	float i, n = 0, t;
	if (time > rm_game_type_vote_timeout) {
		float maxvotes = -1;
		for (i = 0; i < 10; i++) {
			t = rm_game_type_vote_types[i];
			if not(t) break;
			n = rm_game_type_vote_votes[i];
			if (n > maxvotes && !(t & 64)) {
				maxvotes = n;
			}
		}
		for (i = 0; i < 10; i++) {
			t = rm_game_type_vote_types[i];
			if not(t) break;
			if (!(t & 64) && rm_game_type_vote_votes[i] == maxvotes) {
				game_type_switch(t);
				break;
			}
		}
		rm_game_type_vote_finished = TRUE;
		return FALSE;
	}
	if (rm_game_type_vote_finished) return FALSE;
	entity e;
	for (i = 0; i < 10; i++) {
		rm_game_type_vote_votes[i] = 0;
	}
	CLIENT_FOR_EACH_REAL(e) {
		n++;
		if (e.mapvote) {
			t = rm_game_type_vote_types[e.mapvote - 1];
			if (t && !(t & 64))
				rm_game_type_vote_votes[e.mapvote - 1]++;
		}
	}
	n *= 0.5;
	for (i = 0; i < 10; i++) {
		t = rm_game_type_vote_types[i];
		if not(t) break;
		if (rm_game_type_vote_votes[i] > n) {
			game_type_switch(t);
			rm_game_type_vote_finished = TRUE;
			return FALSE;
		}
	}
	rm_game_type_vote_ent.SendFlags |= 2;
	return TRUE;
}

float(string nextmap) rm_game_type_vote {
	if not(rm_game_type_vote_started) {
		return rm_game_type_vote_start(nextmap);
	}
	return TRUE;
}
