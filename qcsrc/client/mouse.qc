float mouse_centered;
vector mouse_pos;
string mouse_cursor;
//vector mouse_cursor_size;
float mouse_disabling;
float mouse_enabled;

void(void) mouse_relative {
	mouse_pos = mouse_pos + getmousepos();
	mouse_pos_x = bound(0, mouse_pos_x, CVAR(vid_conwidth));
	mouse_pos_y = bound(0, mouse_pos_y, CVAR(vid_conheight));
}

vector(void) mouse_position {
	if (mouse_enabled)
			mouse_relative();

	return mouse_pos;
}

void(void) mouse_draw {
	if (mouse_enabled) {
		mouse_relative();
		if (mouse_cursor == "")
			drawpic(mouse_pos, strcat("gfx/menu/", cvar_string("menu_skin"), "/cursor"), '32 32 0', '1 1 1', 1, DRAWFLAG_NORMAL);
		else {
			drawpic(mouse_pos - '16 16 0', mouse_cursor, '32 32 0', '1 1 1', 1, DRAWFLAG_NORMAL);
		}
		mouse_enabled = FALSE;
		mouse_disabling = TRUE;
	} else if (mouse_disabling) {
		mouse_disabling = FALSE;
		mouse_centered = FALSE;
		setcursormode(0);
	}
}

void(string cursor) mouse_enable {
	if (mouse_cursor != cursor) {
		mouse_cursor = cursor;
		//if (mouse_cursor != "")
		//	mouse_cursor_size = drawgetimagesize(mouse_cursor);
	}
	if not(mouse_enabled)
	if (CVAR(_menu_alpha) <= 0) {
		mouse_enabled = TRUE;
		if not(mouse_centered) {
			mouse_pos = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
			mouse_centered = TRUE;
		}
	}
	view_fixangle = TRUE;
	if not(mouse_disabling)
		view_fixed_angles = view_angles;
}
