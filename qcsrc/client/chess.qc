float chess_timer_white;
float chess_timer_black;
float chess_turn;
entity chess_pieces;
float chess_unicode;

void(void) chess_hud_reset {
}

void() chess_draw2d {
	//2d board
	entity e;
	//♚♛♜♝♞♟
	string pieces;
	if (cvar("utf8_enable"))
		pieces = "♚♛♜♝♞♟";
	else
		pieces = "KQRBNP";

	string piece = "?";
	float i, j, bw = 0;
	for (i = 0; i < 8; i++) {
		bw = !bw;
		for (j = 0; j < 8; j++) {
			bw = !bw;
			drawfill('100 300 0' + '20 0 0' * i - '0 20 0' * j, '20 20 0', bw ? '1 1 1' : '0 0 0', 0.5, DRAWFLAG_NORMAL);
		}
	}
	if (team_my == COLOR_TEAM2) {
		for (i = 0; i < 8; i++) {
			drawstring('260 164 0' + i * '0 20 0', ftos(i + 1), '10 10 0', '0.5 0.5 0.5', 1, DRAWFLAG_NORMAL);
			drawstring('248 148 0' - i * '20 0 0', substring("abcdefgh", i, 1), '10 10 0', '0.5 0.5 0.5', 1, DRAWFLAG_NORMAL);
		}
	} else {
		for (i = 0; i < 8; i++) {
			drawstring('92 304 0' - i * '0 20 0', ftos(i + 1), '10 10 0', '0.5 0.5 0.5', 1, DRAWFLAG_NORMAL);
			drawstring('108 320 0' + i * '20 0 0', substring("abcdefgh", i, 1), '10 10 0', '0.5 0.5 0.5', 1, DRAWFLAG_NORMAL);
		}
	}
	for (e = chess_pieces; e; e = e.enemy) {
		switch (e.skin) {
		case 'p':
			piece = substring(pieces, 5, 1);
			break;
		case 'n':
			piece = substring(pieces, 4, 1);
			break;
		case 'b':
			piece = substring(pieces, 3, 1);
			break;
		case 'r':
			piece = substring(pieces, 2, 1);
			break;
		case 'q':
			piece = substring(pieces, 1, 1);
			break;
		case 'k':
			piece = substring(pieces, 0, 1);
			break;
		}
		if (team_my == COLOR_TEAM2) {
			i = 7 - e.origin_x;
			j = 7 - e.origin_y;
		} else {
			i = e.origin_x;
			j = e.origin_y;
		}
		drawstring('101 302 0' + i * '20 0 0' - j * '0 20 0', piece, '20 20 0', ((e.team == 14) ? '0 0 1' : '1 0 0'), 1, DRAWFLAG_NORMAL);
	}
}

void(vector pos, vector gameinfo_size, float gameinfo_scale) chess_hud {
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '108 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	vector p;
	p = pos +'100 24 0' * gameinfo_scale;
	float mins = floor(chess_timer_white / 60);
	float secs = floor(chess_timer_white - mins * 60);
	float tens = floor((chess_timer_white - floor(chess_timer_white)) * 10);
	string s = strcat(ftos(mins), ":", ((secs < 10) ? "0" : ""), ftos(secs), ".", ftos(tens));
	if (!chess_turn) s = strcat("* ", s);
	draw_string_right(p, s, '20 20 0' * gameinfo_scale, '1 0.5 0.5', 1, DRAWFLAG_NORMAL);
	p += '0 20 0';
	mins = floor(chess_timer_black / 60);
	secs = floor(chess_timer_black - mins * 60);
	tens = floor((chess_timer_black - floor(chess_timer_black)) * 10);
	s = strcat(ftos(mins), ":", ((secs < 10) ? "0" : ""), ftos(secs), ".", ftos(tens));
	if (chess_turn) s = strcat("* ", s);
	draw_string_right(p, s, '20 20 0' * gameinfo_scale, '0.5 0.5 1', 1, DRAWFLAG_NORMAL);
}

void(float isnew) chess_info_read {
	float f = net_read_byte();
	if (f & 1)
		chess_timer_white = net_read_coord();

	if (f & 2)
		chess_timer_black = net_read_coord();

	chess_turn = (f & 4);
	if (f & 8) {
		self.draw2d = chess_draw2d;
		self.draw2dflag = 1;
		entity e, e2;
		for (e = chess_pieces; e; e = e2) {
			e2 = e.enemy;
			remove(e);
		}
		chess_pieces = NULL;
		float t, x, y;
		while ((t = net_read_byte())) {
			e = spawn();
			e.skin = t;
			e.origin_x = net_read_byte();
			e.origin_y = net_read_byte();
			e.team = net_read_byte();
			e.enemy = chess_pieces;
			chess_pieces = e;
		}
	}
}
