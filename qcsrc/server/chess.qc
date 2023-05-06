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

float chess_last_move_time;

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

float(float t) chess_piece_cost {
	if (t == CHESS_PAWN)
		return 1;
	else if (t == CHESS_BISHOP || t == CHESS_KNIGHT)
		return 3;
	else if (t == CHESS_ROOK)
		return 5;
	else if (t == CHESS_QUEEN)
		return 10;

	return 0;
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
			for (x = 0; x < 8; x++) {
				for (y = 0; y < 8; y++) {
					if ((e.pos1_x != x || e.pos1_y != y) && chess_move_is_legal(e, x, y, TRUE)) {
						//print("have legal move: ", chess_cell_name(e.pos1_x, e.pos1_y), " -> ", chess_cell_name(x, y), "\n");
						return FALSE;
					}
				}
			}
		}
	}
	return TRUE;
}

entity(float x, float y) chess_piece_find {
	entity e;
	float antiloop;
	for (antiloop = 0, e = chess_pieces; e && antiloop < 64; e = e.enemy, antiloop++) {
		if (e.pos1_x == x && e.pos1_y == y) {
			return e;
		}
	}
	if (antiloop == 64)
		backtrace("chess_piece_find: broken chain");

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
			if (chess_move_is_legal(e, x, y, FALSE)) {
				//print("cell ", chess_cell_name(x, y), " under attack from ", chess_cell_name(e.pos1_x, e.pos1_y), "\n");
				return TRUE;
			}
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
		if (!piece.dmg && x == 6 && y == piece.pos1_y
				&& (e = chess_piece_find(7, piece.pos1_y)) && e.cnt == CHESS_ROOK && !e.dmg && e.team == piece.team
				&& chess_path_is_empty(piece, 7, piece.pos1_y)
				&& !chess_cell_is_under_attack(piece.pos1_x, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(5, piece.pos1_y, piece.team)
				&& !chess_cell_is_under_attack(6, piece.pos1_y, piece.team)
				) {
			return TRUE;
		}
		//long castling
		if (!piece.dmg && x == 2 && y == piece.pos1_y
				&& (e = chess_piece_find(0, piece.pos1_y)) && e.cnt == CHESS_ROOK && !e.dmg && e.team == piece.team
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
		//print("check for check after ", chess_cell_name(piece.pos1_x, piece.pos1_y), " -> ", chess_cell_name(x, y), "\n");
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

entity chess_allowed_moves;
void(entity piece) chess_piece_pick {
	entity e;
	while (chess_allowed_moves) {
		e = chess_allowed_moves.enemy;
		remove(chess_allowed_moves);
		chess_allowed_moves = e;
	}
	chess_piece_picked = piece;
	if not(chess_piece_picked)
		return;

	float i, j;
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
			if (chess_move_is_legal(chess_piece_picked, i, j, TRUE) || (i == chess_piece_picked.pos1_x && j == chess_piece_picked.pos1_y)) {
				e = spawn();
				setmodel(e, "models/runematch/rune.mdl");
				if (i == chess_piece_picked.pos1_x && j == chess_piece_picked.pos1_y)
					e.colormod = '0.75 0.75 0.75';
				else
					e.colormod = '1 1 0';

				e.effects = (EFFECT_ADDITIVE | EFFECT_NODEPTHTEST);
				e.scale = chess_cell_width / (self.maxs_x - self.mins_x) * 0.9;
				chess_piece_move(e, i, j, FALSE);
				e.enemy = chess_allowed_moves;
				chess_allowed_moves = e;
			}
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

void(void) chess_turn_switch {
	chess_turn = !chess_turn;
	chess_info.SendFlags |= 4;
	if (chess_position_is_stale((chess_turn ? COLOR_TEAM2 : COLOR_TEAM1))) {
		if (chess_position_is_check((chess_turn ? COLOR_TEAM2 : COLOR_TEAM1))) { //checkmate, win
			bprint("\{3}* Checkmate\n");
			chess_win = (chess_turn ? COLOR_TEAM1 : COLOR_TEAM2);
			score_player_team_add_score(self, 10);
		} else { //stalemate, draw
			bprint("\{3}* Stalemate\n");
			chess_win = -1;
		}
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
	if (chess_promotion_menu) {
		menu_remove(chess_promotion_menu);
		chess_promotion_menu = NULL;
	}
	chess_turn_switch();
}

void(entity piece, float x, float y) chess_move_perform {
	entity e;
	chess_last_move_time = time;
	float iscastling = 0;
	e = chess_piece_find(x, y);
	if not(chess_turn) {
		cvar_set("timelimit", "0");
		chess_move_number++;
	}
	if (piece.cnt == CHESS_KING && !piece.dmg && (x == 6 || x == 2))
		iscastling = 1;

	if (piece.cnt == CHESS_PAWN && chess_en_passant && !e && piece.pos1_x != x) { //en passant
		e = chess_en_passant;
	}
	chess_piece_move(piece, x, y, TRUE);
	chess_en_passant = NULL;
	if (piece.cnt == CHESS_PAWN && !piece.dmg && (y == 3 || y == 4))
		chess_en_passant = piece;

	piece.dmg = 1;
	if (iscastling) {
		if (x == 6) { //short castling
			chess_piece_move((e = chess_piece_find(7, y)), 5, y, FALSE);
			e.dmg = 1;
			e = NULL;
		} else if (x == 2) { //long castling
			chess_piece_move((e = chess_piece_find(0, y)), 3, y, FALSE);
			e.dmg = 1;
			e = NULL;
		}
	}
	if (e) {
		score_player_team_add_score(self, 1);
		centerprint(self, strcat("You capture a ", chess_piece_name(e.cnt)));
		sound(piece, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NONE);
		stdproc_remove_entity(e);
		e = NULL;
	} else {
		if (chess_position_is_check(chess_turn ? COLOR_TEAM1 : COLOR_TEAM2)) {
			bprint("\{3}* Check\n");
			sound(piece, CHAN_PROJECTILE, "domination/claim.wav", VOL_BASE, ATTN_NONE);
		} else
			sound(piece, CHAN_PROJECTILE, "misc/menu1.wav", VOL_BASE, ATTN_NONE);
	}
	if (piece.cnt == CHESS_PAWN && (y == 0 || y == 7)) {
		chess_promotion = piece;
		chess_promotion_menu = menu_prepare(self, "chess_promotion", "Promote pawn to", 0, chess_promotion_select);
		chess_promotion_started = time;
		menu_add_item(chess_promotion_menu, "Queen");
		menu_add_item(chess_promotion_menu, "Rook");
		menu_add_item(chess_promotion_menu, "Bishop");
		menu_add_item(chess_promotion_menu, "Knight");
	}
	chess_piece_pick(NULL);
	if not(chess_promotion) {
		chess_turn_switch();
	}
}

float chess_interacted;
void(void) chess_physics_frame_begin_hook {
	if (self.classname != "player") return;
	if (time < map_starttime) return;
	if (chess_turn) {
		if (self.team != COLOR_TEAM2) return;
	} else {
		if (self.team != COLOR_TEAM1) return;
	}
	if (chess_promotion && time - chess_promotion_started > 10) {
		chess_promotion_select(0);
		return;
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
			chess_interacted = TRUE;
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
		if (click && chess_piece_pointed) {
			if (chess_piece_pointed != chess_piece_picked)
				chess_piece_pick(chess_piece_pointed);
			else
				chess_piece_pick(NULL);
		}
		if (click && chess_piece_picked && chess_board_pointerx >= 0 && chess_board_pointerx < 8 &&
				chess_board_pointery >= 0 && chess_board_pointery < 8) {
			if (chess_move_is_legal(chess_piece_picked, chess_board_pointerx, chess_board_pointery, TRUE)) {
				chess_move_perform(chess_piece_picked, chess_board_pointerx, chess_board_pointery);
				chess_board_pointerx = -1;
				chess_board_pointery = -1;
			} else {
				sound(chess_piece_picked, CHAN_PROJECTILE, "misc/typehit.wav", VOL_BASE, ATTN_NONE);
			}
		}
	}
	if (chess_board_pointerx >= 0 && chess_board_pointerx < 8 &&
			chess_board_pointery >= 0 && chess_board_pointery < 8 && chess_piece_picked && !((e = chess_piece_find(chess_board_pointerx, chess_board_pointery)) && e.team == self.team)
			&& chess_move_is_legal(chess_piece_picked, chess_board_pointerx, chess_board_pointery, TRUE)) {
		if (chess_board_pointer)
			chess_board_pointer.colormod = '1 1 0';

		for (chess_board_pointer = chess_allowed_moves; chess_board_pointer; chess_board_pointer = chess_board_pointer.enemy) {
			if (chess_board_pointer.pos1_x == chess_board_pointerx && chess_board_pointer.pos1_y == chess_board_pointery)
				break;
		}
		chess_board_pointer.colormod = '0 1 1';
	} else {
		if (chess_board_pointer) {
			chess_board_pointer.colormod = '1 1 0';
			chess_board_pointer = NULL;
		}
	}
	if (e && e.team == self.team) chess_piece_point(e);
}

var void(void) chess_player_think_next;
void(void) chess_player_think {
	if (clienttype(self) == CLIENTTYPE_BOT)
		bot_stay(self, 1);

	if (chess_interacted) {
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		chess_interacted = FALSE;
	}
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

float(float t) chess_position_evaluate {
	entity e, e2;
	float score = 0;
	float sign;
	float i, j;
	if (chess_position_is_check((t == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1)) {
		if (chess_position_is_stale((t == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1))
			score += 1000;
		else
			score += 5;
	}
	for (e = chess_pieces; e; e = e.enemy) {
		if (e.pos1_x < 0 || e.pos1_y < 0) continue;
		if (t == e.team)
			sign = 1;
		else
			sign = -1;

		if (chess_cell_is_under_attack(e.pos1_x, e.pos1_y, e.team)) {
			score -= sign * chess_piece_cost(e.cnt) * 5;
			if not(chess_cell_is_under_attack(e.pos1_x, e.pos1_y, ((e.team == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1)))
				score -= sign * chess_piece_cost(e.cnt) * 5;
		}
		if (chess_cell_is_under_attack(e.pos1_x, e.pos1_y, ((e.team == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1))) {
			score += sign * chess_piece_cost(e.cnt) * 5;
			if not(chess_cell_is_under_attack(e.pos1_x, e.pos1_y, e.team))
				score += sign * chess_piece_cost(e.cnt) * 5;
		}
		score += sign * chess_piece_cost(e.cnt);
		for (i = 0; i < 8; i++)
			for (j = 0; j < 8; j++) {
				if ((e.pos1_x != i || e.pos1_y != j) && chess_move_is_legal(e, i, j, TRUE)) {
					score += sign;
					if (e.cnt == CHESS_PAWN && (j == 7 || j == 0))
						score += sign * 20;
				}
			}
	}
	return score;
}

float chess_ai_bestscore;
entity chess_ai_bestpiece;
vector chess_ai_bestmove;
entity chess_ai_current_piece;
void(entity chess_bot) chess_ai_move {
	if (chess_promotion) {
		chess_promotion_select(0);
	}
	if (chess_last_move_time + 1 > time) return;
	float check_amounts = 0;
	float t = chess_bot.team;
	entity e, capture;
	float i, j, type;
	vector v, v2 = '0 0 0';
	if not(chess_ai_bestpiece)
		chess_ai_bestscore = -100000;

	float score, under_attack;
	if not(chess_ai_current_piece) chess_ai_current_piece = chess_pieces;
	while (chess_ai_current_piece && chess_ai_current_piece.team != t) chess_ai_current_piece = chess_ai_current_piece.enemy;
	e = chess_ai_current_piece;
	if (e) {
		under_attack = chess_cell_is_under_attack(e.pos1_x, e.pos1_y, t);
		//print("analyzing piece at ", chess_cell_name(e.pos1_x, e.pos1_y), "\n");
		for (i = 0; i < 8; i++)
			for (j = 0; j < 8; j++) {
				if ((e.pos1_x != i || e.pos1_y != j) && chess_move_is_legal(e, i, j, TRUE)) {
					//print("checking move: ", chess_cell_name(e.pos1_x, e.pos1_y) , " -> ", chess_cell_name(i, j), "\n");
					capture = chess_piece_find(i, j);
					v = e.pos1;
					e.pos1_x = i;
					e.pos1_y = j;
					type = e.cnt;
					if (capture) {
						v2 = capture.pos1;
						capture.pos1 = '-1 -1 0';
					}
					if (e.cnt == CHESS_PAWN && (e.pos1_y == 0 || e.pos1_y == 7))
						e.cnt = CHESS_QUEEN;

					score = chess_position_evaluate(t);
					if (e.cnt == CHESS_KING) {
						if (!e.dmg && (j == 6 || j == 2))
							score += 20;
						else if (chess_move_number < 10)
							score -= 10;
					}
					if (e.cnt == CHESS_PAWN) //pawn push is often good
						score += 5;

					if (chess_move_number < 5 && e.cnt == CHESS_QUEEN && !e.dmg) //defer queen at beginning
						score -= 50;

					if ((e.cnt == CHESS_KNIGHT || e.cnt == CHESS_BISHOP) && !e.dmg) //developing is good
						score += chess_move_number * 2;

					if (capture) {
						score += 10 * chess_piece_cost(capture.cnt);
					}
					if (chess_cell_is_under_attack(i, j, t))
						score -= 30 * chess_piece_cost(e.cnt);
					else {
						if (capture)
							score += 10 * chess_piece_cost(capture.cnt); //free piece

						if (under_attack)
							score += 10 * chess_piece_cost(e.cnt); //escape from attack
					}
					score *= (1 + 0.05 * random());
					if (score > chess_ai_bestscore) {
						chess_ai_bestscore = score;
						chess_ai_bestmove_x = i;
						chess_ai_bestmove_y = j;
						chess_ai_bestpiece = e;
					}
					e.pos1 = v;
					e.cnt = type;
					if (capture) {
						capture.pos1 = v2;
					}
				}
			}
		chess_ai_current_piece = chess_ai_current_piece.enemy;
	}
	if (chess_ai_current_piece) return;
	entity oldself = self;
	self = chess_bot;
	chess_move_perform(chess_ai_bestpiece, chess_ai_bestmove_x, chess_ai_bestmove_y);
	chess_ai_bestpiece = NULL;
	self = oldself;
}

float(float ignore1, float ignore2) chess_winning_condition {
	if (time < map_starttime) return FALSE;
	entity e, wh = NULL, wb = NULL, bh = NULL, bb = NULL;
	FOR_EACH_PLAYER(e) {
		if (clienttype(e) == CLIENTTYPE_BOT) {
			if (e.team == COLOR_TEAM1)
				wb = e;
			else if (e.team == COLOR_TEAM2)
				bb = e;
		} else {
			if (e.team == COLOR_TEAM1)
				wh = e;
			else if (e.team == COLOR_TEAM2)
				bh = e;
		}
		if (wh && wb && bh && bb) break;
	}
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
			if (!bh && bb)
				chess_ai_move(bb);
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
			if (!wh && wb)
				chess_ai_move(wb);
		}
	} else {
		//only bots or white team have only bots
		if ((!wh && !bh && bb && wb && cvar("g_chess_bot_vs_bot")) || (wb && !wh && bh)) {
			if (time > map_starttime + 1 && wb && !chess_turn)
				chess_ai_move(wb);
		}
	}
	return FALSE;
}

float(void) chess_WarmupAllowed {
	return FALSE;
}

void(void) chess_init {
	team_teams_set_count(2);
	score_basics(SCORE_FLAG_SORT_PRIO_PRIMARY, SCORE_FLAG_SORT_PRIO_PRIMARY, TRUE);
	entity_initialize(NULL, chess_init_delayed, INITPRIO_LAST);
	plugin_physics_frame_begin_hook = chess_physics_frame_begin_hook;
	plugin_winning_condition = chess_winning_condition;
	chess_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = chess_player_think;
	plugin_WarmupAllowed = chess_WarmupAllowed;
	precache_sound("weapons/rocket_impact.wav");
	precache_sound("misc/menu1.wav");
	precache_sound("misc/typehit.wav");
	precache_sound("domination/claim.wav");
	precache_model("models/runematch/rune.mdl");
}
