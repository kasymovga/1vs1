float chess_timer_white;
float chess_timer_black;
float chess_turn;

void(void) chess_hud_reset {
}

void(vector pos, vector gameinfo_size, float gameinfo_scale) chess_hud {
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '108 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	vector p;
	p = pos +'100 24 0' * gameinfo_scale;
	float mins = floor(chess_timer_white / 60);
	float secs = floor(chess_timer_white - mins * 60);
	float tens = floor((chess_timer_white - floor(chess_timer_white)) * 10);
	string s = strcat(ftos(mins), ":", ((secs < 10) ? "0" : ""), ftos(secs), ".", ((tens < 10) ? "0" : ""), ftos(tens));
	if (!chess_turn) s = strcat("* ", s);
	draw_string_right(p, s, '20 20 0' * gameinfo_scale, '1 0.5 0.5', 1, DRAWFLAG_NORMAL);
	p += '0 20 0';
	mins = floor(chess_timer_black / 60);
	secs = floor(chess_timer_black - mins * 60);
	tens = floor((chess_timer_black - floor(chess_timer_black)) * 10);
	s = strcat(ftos(mins), ":", ((secs < 10) ? "0" : ""), ftos(secs), ".", ((tens < 10) ? "0" : ""), ftos(tens));
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
}
