float mouse_centered;
vector mouse_pos;
string mouse_cursor;
//vector mouse_cursor_size;
float mouse_disabling;
float mouse_enabled;
float mouse_absolute;

void(void) mouse_relative {
	vector v = getmousepos();
	if (v != '0 0 0') {
		v_x *= (CVAR(vid_conwidth) / view_width); //engine do it for menu, but not for client
		v_y *= (CVAR(vid_conheight) / view_height);
		mouse_pos = mouse_pos + v * bound(0.1, CVAR(menu_mouse_speed), 10);
		mouse_pos_x = bound(0, mouse_pos_x, CVAR(vid_conwidth));
		mouse_pos_y = bound(0, mouse_pos_y, CVAR(vid_conheight));
	}
}

vector(void) mouse_position {
	if (mouse_enabled) {
		if (mouse_absolute)
			mouse_pos = getmousepos();
		else
			mouse_relative();
	}
	return mouse_pos;
}

void(void) mouse_draw {
	if (mouse_enabled) {
		mouse_position();
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
	}
	if not(mouse_enabled) {
		mouse_absolute = (cvar("menu_mouse_absolute") || cvar("vid_touchscreen") || main_isdemo);
		if (CVAR(_menu_alpha) <= 0) {
			mouse_enabled = TRUE;
			if not(mouse_centered) {
				mouse_pos = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
				mouse_centered = TRUE;
			}
			if (mouse_absolute)
				setcursormode(1);
		}
		if (!mouse_absolute && (!view_spectatee_status || view_observer_status)) {
			view_fixangle = 1;
			if not(mouse_disabling)
				view_fixed_angles = view_angles;
		}
	}
}
