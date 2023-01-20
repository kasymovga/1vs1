//Nexball HUD
#define NBPB_SIZE '80 38 0'
#define NBPB_BT 2                   //thickness
#define NBPB_BRGB '1 1 1'
#define NBPB_BALPH 1                //alpha
#define NBPB_BFLAG DRAWFLAG_NORMAL
#define NBPB_IALPH 0.4
#define NBPB_IFLAG DRAWFLAG_NORMAL
#define NBPB_IRGB '0.7 0.1 0'

void(vector pos, vector gameinfo_size, float gameinfo_scale) nb_hud {
	if not((rm_hud_game_info_enabled = (sbar_stat_items & IT_KEYS)))
		return;

	float nb_pb;
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '88 38 0', gameinfo_size)
	nb_pb = getstatf(STAT_NB_METERSTART);
	//Manage the progress bar if any
	if (nb_pb > 0) {
		vector s;
		if (nb_pb > 1)
			nb_pb = 2 - nb_pb;

		s = NBPB_SIZE * gameinfo_scale;
		//Draw the filling
		drawfill(pos, nb_pb * s_x * '1 0 0' + s_y * '0 1 0', NBPB_IRGB, NBPB_IALPH, NBPB_IFLAG);
		drawline(NBPB_BT, pos    , pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos    , pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
	}
	drawpic(pos, "gfx/hud/sb_nexball_carrying", '80 34 0' * gameinfo_scale, '1 1 1', 1, DRAWFLAG_NORMAL);
}

