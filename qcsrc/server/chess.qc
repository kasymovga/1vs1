float g_chess_timecontrol_addition;

string chess_bishop_model;
string chess_knight_model;
string chess_rook_model;
string chess_pawn_model;
string chess_king_model;
string chess_queen_model;
entity chess_promotion;
entity chess_promotion_menu;
float chess_promotion_started;
float chess_turn;
float chess_move_number;
float chess_win;
float chess_cell_width;
float chess_cell_height;
float chess_board_width;
float chess_board_height;
float chess_board_initialized;
vector chess_board_pos;
entity chess_board_pointer;

float chess_timer_white;
float chess_timer_black;

entity chess_pieces;
entity chess_piece_pointed;
entity chess_piece_picked;
entity chess_en_passant;
entity chess_info;

enum {
	CHESS_PAWN,
	CHESS_BISHOP,
	CHESS_KNIGHT,
	CHESS_ROOK,
	CHESS_KING,
	CHESS_QUEEN,
};

string(float t) chess_piece_name {
	switch (t) {
	case CHESS_PAWN: return "Pawn";
	case CHESS_BISHOP: return "Bishop";
	case CHESS_KNIGHT: return "Knight";
	case CHESS_ROOK: return "Rook";
	case CHESS_KING: return "King";
	case CHESS_QUEEN: return "Queen";
	}
	return "Unknown";
}

float(entity piece, float x, float y, float checkforcheck) chess_move_is_legal;
float(float x, float y, float ft) chess_cell_is_under_attack;

void(void) spawnfunc_chess_piece {
	if (self.netname == "bishop")
		chess_bishop_model = self.model;
	else if (self.netname == "knight")
		chess_knight_model = self.model;
	else if (self.netname == "rook")
		chess_rook_model = self.model;
	else if (self.netname == "pawn")
		chess_pawn_model = self.model;
	else if (self.netname == "king")
		chess_king_model = self.model;
	else if (self.netname == "queen")
		chess_queen_model = self.model;
	else
		error(strcat("chess piece have incorrect netname: ", self.netname));

	precache_model(self.model);
	remove(self);
}

void(void) spawnfunc_chess_board {
	self.solid = SOLID_BSP;
	model_setup();
	chess_board_width = self.maxs_x - self.mins_x;
	chess_board_height = self.maxs_y - self.mins_y;
	chess_board_pos_x = self.absmin_x;
	chess_board_pos_y = self.absmin_y;
	chess_board_pos_z = self.absmax_z;
	chess_cell_width = chess_board_width / 8;
	chess_cell_height = chess_board_height / 8;
	chess_board_initialized = 1;
}

float(float t) chess_position_is_check {
	entity e;
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.cnt == CHESS_KING && e.team == t && e.pos1_x >= 0 && e.pos1_y >= 0)
			return chess_cell_is_under_attack(e.pos1_x, e.pos1_y, t);
	}
	return FALSE;
}

string(float x, float y) chess_cell_name {
	string s = substring("abcdefgh", x, 1);
	return strcat(s, ftos(y + 1));
}

float(float t) chess_position_is_stale {
	float x, y;
	entity e;
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.team == t && e.pos1_x >= 0 && e.pos1_y >= 0) {
			for (x = 0; x < 8; x++)
				for (y = 0; y < 8; y++) {
					if (e.pos1_x != x && e.pos1_y != y && chess_move_is_legal(e, x, y, TRUE)) {
						return FALSE;
					}
				}
		}
	}
	return TRUE;
}

entity(float x, float y) chess_piece_find {
	entity e;
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.pos1_x == x && e.pos1_y == y) {
			return e;
		}
	}
	return NULL;
}

float(entity piece, float x, float y) chess_path_is_empty {
	float px = piece.pos1_x;
	float py = piece.pos1_y;
	for (;;) {
		if (px < x) px++;
		else if (px > x) px--;
		if (py < y) py++;
		else if (py > y) py--;
		if (px == x && py == y) break;
		if (chess_piece_find(px, py)) {
			return FALSE;
		}
	}
	return TRUE;
}

float(float x, float y, float ft) chess_cell_is_under_attack {
	entity e;
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.team != ft && e.pos1_x >= 0 && e.pos2_y >= 0)
			if (chess_move_is_legal(e, x, y, FALSE))
				return TRUE;
	}
	return FALSE;
}

float(entity piece, float x, float y, float _checkforcheck) chess_move_is_legal {
	entity e;
	entity capture;
	if ((e = chess_piece_find(x, y)) && e.team == piece.team) return FALSE;
	capture = e;
	switch (piece.cnt) {
	case CHESS_PAWN:
		if (piece.team == COLOR_TEAM1) { //"white"
			if (piece.pos1_y == 1) {
				if (x == piece.pos1_x && ((y == 2 && !chess_piece_find(x, y)) || (y == 3 && !chess_piece_find(x, y - 1) && !chess_piece_find(x, y))))
					goto checkforcheck;

			} else {
				if (x == piece.pos1_x && ((y == piece.pos1_y + 1 && !chess_piece_find(x, y))))
					goto checkforcheck;
			}
			if (fabs(x - piece.pos1_x) == 1 && y - 1 == piece.pos1_y &&
					(capture ||
					(chess_en_passant && chess_en_passant.pos1_x == x && chess_en_passant.pos1_y == piece.pos1_y))
					)
				goto checkforcheck;
		} else {
			if (piece.pos1_y == 6) { //"black"
				if (x == piece.pos1_x && ((y == 5 && !chess_piece_find(x, y)) || (y == 4 && !chess_piece_find(x, y + 1) && !chess_piece_find(x, y))))
					goto checkforcheck;
			} else {
				if (x == piece.pos1_x && ((y == piece.pos1_y - 1 && !chess_piece_find(x, y))))
					goto checkforcheck;
			}
			if (fabs(x - piece.pos1_x) == 1 && y + 1 == piece.pos1_y &&
					(capture ||
					(chess_en_passant && chess_en_passant.pos1_x == x && chess_en_passant.pos1_y == piece.pos1_y))
					)
				goto checkforcheck;
		}
		break;
	case CHESS_BISHOP:
		if (fabs(x - piece.pos1_x) == fabs(y - piece.pos1_y) && chess_path_is_empty(piece, x, y)) {
			goto checkforcheck;
		}
		break;
	case CHESS_KNIGHT:
		if (fabs(x - piece.pos1_x) == 2 && fabs(y - piece.pos1_y) == 1)
			goto checkforcheck;

		if (fabs(x - piece.pos1_x) == 1 && fabs(y - piece.pos1_y) == 2)
			goto checkforcheck;

		break;
	case CHESS_ROOK:
		if ((x == piece.pos1_x || y == piece.pos1_y) && chess_path_is_empty(piece, x, y)) {
			goto checkforcheck;
		}
		break;
	case CHESS_KING:
		if (fabs(x - piece.pos1_x) <= 1 && fabs(y - piece.pos1_y) <= 1) {
			goto checkforcheck;
		}
		//short castling
		if (!piece.dmg && x == 6
				&& (e = chess_piece_find(7, piece.pos1_y)) && e.cnt == CHESS_ROOK && !e.dmg
				&& chess_path_is_empty(piece, 7, piece.pos1_y)
				&& !chess_cell_is_under_attack(piece.pos1_x, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(5, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(6, piece.pos1_y, piece.team)
				) {
			return TRUE;
		}
		//long castling
		if (!piece.dmg && x == 2
				&& (e = chess_piece_find(0, piece.pos1_y)) && e.cnt == CHESS_ROOK && !e.dmg
				&& chess_path_is_empty(piece, 0, piece.pos1_y)
				&& !chess_cell_is_under_attack(piece.pos1_x, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(3, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(2, piece.pos1_y, piece.team)
				) {
			return TRUE;
		}
		break;
	case CHESS_QUEEN:
		if ((fabs(x - piece.pos1_x) == fabs(y - piece.pos1_y) || (x == piece.pos1_x || y == piece.pos1_y)) && chess_path_is_empty(piece, x, y)) {
			goto checkforcheck;
		}
		break;
	}
	return FALSE;
:checkforcheck
	float ischeck = FALSE;
	if (_checkforcheck) {
		vector v1, v2 = '0 0 0';
		if (capture) {
			v2 = capture.pos1;
			capture.pos1 = '-1 -1 0';
		}
		v1 = piece.pos1;
		piece.pos1_x = x;
		piece.pos1_y = y;
		ischeck = chess_position_is_check(piece.team);
		piece.pos1 = v1;
		if (capture)
			capture.pos1 = v2;
	}
	return !ischeck;
}

void(entity piece, float cellx, float celly, float _print) chess_piece_move {
	if (_print) {
		bprint(strcat("\{3}", strcat("* ", ftos(chess_move_number), ". ", (chess_turn ? "^4" : "^1"), chess_piece_name(piece.cnt), " "),
				strcat(chess_cell_name(piece.pos1_x, piece.pos1_y), " -> ", chess_cell_name(cellx, celly), "\n")));
	}
	setorigin(piece, chess_board_pos + chess_cell_width * (cellx + 0.5) * '1 0 0' + chess_cell_height * (celly + 0.5) * '0 1 0');
	piece.pos1_x = cellx;
	piece.pos1_y = celly;
}

void(void) chess_piece_remove {
	if (self == chess_pieces) {
		chess_pieces = chess_pieces.enemy;
		return;
	}
	entity e2;
	for (e2 = chess_pieces; e2.enemy; e2 = e2.enemy) {
		if (e2.enemy == self) {
			e2.enemy = self.enemy;
		}
	}
}

entity(float t, float cellx, float celly, float wb) chess_piece_spawn {
	entity e = spawn();
	e.classname = "chess_piece";
	switch (t) {
	case CHESS_PAWN: setmodel(e, chess_pawn_model); break;
	case CHESS_BISHOP: setmodel(e, chess_bishop_model); break;
	case CHESS_KNIGHT: setmodel(e, chess_knight_model); break;
	case CHESS_ROOK: setmodel(e, chess_rook_model); break;
	case CHESS_KING: setmodel(e, chess_king_model); break;
	case CHESS_QUEEN: setmodel(e, chess_queen_model); break;
	default: error("unknown piece type");
	}
	if (wb)
		e.angles = '0 180 0';

	e.solid = SOLID_BSP;
	chess_piece_move(e, cellx, celly, FALSE);
	e.team = (wb ? COLOR_TEAM2 : COLOR_TEAM1);
	e.colormod = team_colormod(e.team);
	e.cnt = t;
	e.enemy = chess_pieces;
	chess_pieces = e;
	e.entremove = chess_piece_remove;
	return e;
}

void(void) chess_board_init {
	float i;
	chess_piece_spawn(CHESS_PAWN, 0, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 1, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 2, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 3, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 4, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 5, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 6, 1, 0);
	chess_piece_spawn(CHESS_PAWN, 7, 1, 0);
	chess_piece_spawn(CHESS_ROOK, 0, 0, 0);
	chess_piece_spawn(CHESS_KNIGHT, 1, 0, 0);
	chess_piece_spawn(CHESS_BISHOP, 2, 0, 0);
	chess_piece_spawn(CHESS_QUEEN, 3, 0, 0);
	chess_piece_spawn(CHESS_KING, 4, 0, 0);
	chess_piece_spawn(CHESS_BISHOP, 5, 0, 0);
	chess_piece_spawn(CHESS_KNIGHT, 6, 0, 0);
	chess_piece_spawn(CHESS_ROOK, 7, 0, 0);
	chess_piece_spawn(CHESS_PAWN, 0, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 1, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 2, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 3, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 4, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 5, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 6, 6, 1);
	chess_piece_spawn(CHESS_PAWN, 7, 6, 1);
	chess_piece_spawn(CHESS_ROOK, 0, 7, 1);
	chess_piece_spawn(CHESS_KNIGHT, 1, 7, 1);
	chess_piece_spawn(CHESS_BISHOP, 2, 7, 1);
	chess_piece_spawn(CHESS_QUEEN, 3, 7, 1);
	chess_piece_spawn(CHESS_KING, 4, 7, 1);
	chess_piece_spawn(CHESS_BISHOP, 5, 7, 1);
	chess_piece_spawn(CHESS_KNIGHT, 6, 7, 1);
	chess_piece_spawn(CHESS_ROOK, 7, 7, 1);
}

float(entity to, float f) chess_info_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_CHESS_INFO);
	f &= 3;
	if (chess_turn)
		f |= 4;

	net_write_byte(MSG_ENTITY, f);
	if (f & 1)
		net_write_coord(MSG_ENTITY, chess_timer_white);

	if (f & 2)
		net_write_coord(MSG_ENTITY, chess_timer_black);

	return TRUE;
}

void(void) chess_init_delayed {
	if not(chess_board_initialized)
		error("no chess_board entity on this map!");

	chess_timer_white = chess_timer_black = cvar("g_chess_timecontrol_start") * 60;
	CVAR_CACHE(g_chess_timecontrol_addition);
	chess_board_init();
	if not(chess_info) {
		chess_info = spawn();
		net_link_entity(chess_info, FALSE, 0, chess_info_send);
	}
	chess_info.SendFlags = 255;
}

void(entity piece) chess_piece_pick {
	if (chess_piece_picked)
		setorigin(chess_piece_picked, chess_piece_picked.origin_x * '1 0 0' + chess_piece_picked.origin_y * '0 1 0' + chess_board_pos_z * '0 0 1');

	chess_piece_picked = piece;
	if (chess_piece_picked) {
		setorigin(chess_piece_picked, chess_piece_picked.origin_x * '1 0 0' + chess_piece_picked.origin_y * '0 1 0' + (chess_board_pos_z + chess_cell_width * 0.5) * '0 0 1');
	}
}

void(entity e) chess_piece_point {
	if (e == chess_piece_pointed) return;
	if (chess_piece_pointed) {
		chess_piece_pointed.effects = 0;
		chess_piece_pointed.colormod = team_colormod(chess_piece_pointed.team);
		chess_piece_pointed = NULL;
	}
	chess_piece_pointed = e;
	if (chess_piece_pointed) {
		chess_piece_pointed.effects = (EFFECT_ADDITIVE | EFFECT_STARDUST);
		chess_piece_pointed.colormod = team_colormod(chess_piece_pointed.team) * 2;
	}
}

void(float sel) chess_promotion_select {
	if (sel < 0 || sel > 3) return;
	float x = chess_promotion.pos1_x;
	float y = chess_promotion.pos1_y;
	stdproc_remove_entity(chess_promotion);
	chess_promotion = NULL;
	switch (sel) {
	case 0: //queen
		chess_piece_spawn(CHESS_QUEEN, x, y, chess_turn);
		break;
	case 1: //rook
		chess_piece_spawn(CHESS_ROOK, x, y, chess_turn);
		break;
	case 2: //bishop
		chess_piece_spawn(CHESS_BISHOP, x, y, chess_turn);
		break;
	case 3: //knight
		chess_piece_spawn(CHESS_KNIGHT, x, y, chess_turn);
		break;
	}
	chess_turn = !chess_turn;
	chess_info.SendFlags |= 4;
	menu_remove(chess_promotion_menu);
	chess_promotion_menu = NULL;
}

void(void) chess_physics_frame_begin_hook {
	if (self.classname != "player") return;
	if (chess_turn) {
		if (self.team != COLOR_TEAM2) return;
	} else {
		if (self.team != COLOR_TEAM1) return;
	}
	if (chess_promotion)
		return;

	vector o = self.origin + self.view_ofs;
	makevectors(self.v_angle);
	trace_line(o, o + 1024 * v_forward, TRACE_MOVE_NORMAL, self);
	float chess_board_pointerx = -1;
	float chess_board_pointery = -1;
	float click = (self.BUTTON_ATCK && !(self.buttons_old & 1));
	if (self.BUTTON_ATCK2 && chess_piece_picked) {
		chess_piece_pick(NULL);
	}
	chess_piece_point(NULL);
	entity e = NULL;
	if (trace_ent) {
		if (trace_ent.classname == "chess_board" || trace_ent.classname == "chess_piece") {
			if (trace_ent.classname == "chess_piece") {
				if (trace_ent.team == self.team)
					chess_piece_point(trace_ent);
				else {
					chess_board_pointerx = trace_ent.pos1_x;
					chess_board_pointery = trace_ent.pos1_y;
				}
			} else {
				chess_board_pointerx = floor((trace_endpos_x - chess_board_pos_x) / chess_cell_width);
				chess_board_pointery = floor((trace_endpos_y - chess_board_pos_y) / chess_cell_height);
				if ((e = chess_piece_find(chess_board_pointerx, chess_board_pointery)) && e.team == self.team) {
					chess_piece_point(e);
					chess_board_pointerx = -1;
					chess_board_pointery = -1;
				}
			}
		}
		if (click && chess_piece_pointed && chess_piece_pointed != chess_piece_picked) {
			chess_piece_pick(chess_piece_pointed);
		}
		if (click && chess_piece_picked && chess_board_pointerx >= 0 && chess_board_pointerx < 8 &&
				chess_board_pointery >= 0 && chess_board_pointery < 8) {
			if (chess_move_is_legal(chess_piece_picked, chess_board_pointerx, chess_board_pointery, TRUE)) {
				float iscastling = 0;
				e = chess_piece_find(chess_board_pointerx, chess_board_pointery);
				if not(chess_turn) {
					cvar_set("timelimit", "0");
					chess_move_number++;
				}
				if (chess_piece_picked.cnt == CHESS_KING && !chess_piece_picked.dmg && (chess_board_pointerx == 6 || chess_board_pointerx == 2))
					iscastling = 1;

				if (chess_piece_picked.cnt == CHESS_PAWN && chess_en_passant && !e && chess_piece_picked.pos1_x != chess_board_pointerx) { //en passant
					e = chess_en_passant;
				}
				chess_piece_move(chess_piece_picked, chess_board_pointerx, chess_board_pointery, TRUE);
				chess_en_passant = NULL;
				if (chess_piece_picked.cnt == CHESS_PAWN && !chess_piece_picked.dmg && (chess_board_pointery == 3 || chess_board_pointery == 4))
					chess_en_passant = chess_piece_picked;

				chess_piece_picked.dmg = 1;
				if (iscastling) {
					if (chess_board_pointerx == 6) { //short castling
						chess_piece_move((e = chess_piece_find(7, chess_board_pointery)), 5, chess_board_pointery, FALSE);
						e.dmg = 1;
						e = NULL;
					} else if (chess_board_pointerx == 2) { //long castling
						chess_piece_move((e = chess_piece_find(0, chess_board_pointery)), 3, chess_board_pointery, FALSE);
						e.dmg = 1;
						e = NULL;
					}
				}
				if (e) {
					score_player_add(self, SP_KILLS, 1);
					score_player_team_add_score(self, 1);
					centerprint(self, strcat("You capture a ", chess_piece_name(e.cnt)));
					pointparticles(particleeffectnum("rocket_explode"), e.origin + '0 0 1', '0 0 0', 1);
					sound(chess_piece_picked, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
					stdproc_remove_entity(e);
					e = NULL;
				} else
					sound(chess_piece_picked, CHAN_PROJECTILE, "misc/menu1.wav", VOL_BASE, ATTN_NORM);

				if (chess_piece_picked.cnt == CHESS_PAWN && (chess_board_pointery == 0 || chess_board_pointery == 7)) {
					chess_promotion = chess_piece_picked;
					chess_promotion_menu = menu_prepare(self, "chess_promotion", "Promote pawn to", 0, chess_promotion_select);
					chess_promotion_started = time;
					menu_add_item(chess_promotion_menu, "Queen");
					menu_add_item(chess_promotion_menu, "Rook");
					menu_add_item(chess_promotion_menu, "Bishop");
					menu_add_item(chess_promotion_menu, "Knight");
				}
				chess_board_pointerx = -1;
				chess_board_pointery = -1;
				chess_piece_pick(NULL);
				if not(chess_promotion) {
					chess_turn = !chess_turn;
					chess_info.SendFlags |= 4;
					if (chess_position_is_stale((chess_turn ? COLOR_TEAM2 : COLOR_TEAM1))) {
						if (chess_position_is_check((chess_turn ? COLOR_TEAM2 : COLOR_TEAM1))) { //checkmate, win
							bprint("\{3}* Checkmate\n");
							chess_win = (chess_turn ? COLOR_TEAM1 : COLOR_TEAM2);
							score_player_add(self, SP_KILLS, 10);
							score_player_team_add_score(self, 10);
						} else { //stalemate, draw
							bprint("\{3}* Stalemate\n");
							chess_win = -1;
						}
					}
				}
			} else {
				sound(chess_piece_picked, CHAN_PROJECTILE, "misc/typehit.wav", VOL_BASE, ATTN_NORM);
			}
		}
	}
	if (chess_board_pointerx >= 0 && chess_board_pointerx < 8 &&
			chess_board_pointery >= 0 && chess_board_pointery < 8 && chess_piece_picked && !((e = chess_piece_find(chess_board_pointerx, chess_board_pointery)) && e.team == self.team)) {
		if not(chess_board_pointer) {
			chess_board_pointer = spawn();
			setmodel(chess_board_pointer, "models/laser_dot.mdl");
			chess_board_pointer.angles = '90 0 0';
			chess_board_pointer.scale = (chess_cell_width / chess_board_pointer.maxs_x);
		}
		chess_board_pointer.origin_z = chess_board_pos_z - chess_board_pointer.scale * chess_board_pointer.maxs_y * 0.8;
		chess_piece_move(chess_board_pointer, chess_board_pointerx, chess_board_pointery, FALSE);
		chess_board_pointer.origin_z = chess_board_pos_z - chess_board_pointer.scale * chess_board_pointer.maxs_y * 1.8;
		setorigin(chess_board_pointer, chess_board_pointer.origin);
	} else {
		if (chess_board_pointer) {
			remove(chess_board_pointer);
			chess_board_pointer = NULL;
		}
	}
	if (e && e.team == self.team) chess_piece_point(e);
}

var void(void) chess_player_think_next;
void(void) chess_player_think {
	self.BUTTON_ATCK = FALSE;
	self.BUTTON_ATCK2 = FALSE;
	chess_player_think_next();
}

float(float t) chess_can_mate {
	entity e;
	float c = 0;
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.team == t || !t) {
			if (e.cnt == CHESS_PAWN) return TRUE;
			if (e.cnt == CHESS_KNIGHT || e.cnt == CHESS_BISHOP) c++;
			if (e.cnt == CHESS_ROOK || e.cnt == CHESS_QUEEN) c++;
			if (c > 1) return TRUE;
		}
	}
	return FALSE;
}

float(float ignore1, float ignore2) chess_winning_condition {
	if (chess_win) {
		score_winning_condition_helper_winnerteam = chess_win;
		float t = (chess_turn ? COLOR_TEAM1 : COLOR_TEAM2);
		return TRUE;
	} else if (chess_move_number) {
		float c = 0;
		if not(chess_can_mate(0)) {
			bprint("\{3}* Draw\n");
			chess_win = -1;
			return TRUE;
		}
		if (chess_turn) { //"black"
			chess_timer_black -= frametime;
			chess_info.SendFlags |= 2;
			if (chess_timer_black < 0) {
				bprint("\{3}* No time left for blue team\n");
				if (chess_can_mate(COLOR_TEAM1)) {
					bprint("\{3}* Red team won by time\n");
					chess_win = COLOR_TEAM1;
				} else {
					chess_win = -1;
					bprint("\{3}* Draw, red team don't have enough material\n");
				}
				return TRUE;
			}
		} else { //"white"
			chess_timer_white -= frametime;
			chess_info.SendFlags |= 1;
			if (chess_timer_white < 0) {
				bprint("\{3}* No time left for white\n");
				if (chess_can_mate(COLOR_TEAM2)) {
					bprint("\{3}* Blue team won by time\n");
					chess_win = COLOR_TEAM2;
				} else {
					chess_win = -1;
					bprint("\{3}* Draw, blue team don't have enough material\n");
				}
				return TRUE;
			}
		}
	}
	return FALSE;
}

float(void) chess_WarmupAllowed {
	return FALSE;
}

void(void) chess_init {
	team_teams_set_count(2);
	score_basics(0, 0, TRUE);
	entity_initialize(NULL, chess_init_delayed, INITPRIO_LAST);
	plugin_physics_frame_begin_hook = chess_physics_frame_begin_hook;
	plugin_winning_condition = chess_winning_condition;
	chess_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = chess_player_think;
	plugin_WarmupAllowed = chess_WarmupAllowed;
	precache_model("models/laser_dot.mdl");
	precache_sound("weapons/rocket_impact.wav");
	precache_sound("misc/menu1.wav");
	precache_sound("misc/typehit.wav");
}
