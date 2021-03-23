float mouse_enabled;
var float mouse_not_centered = TRUE;
vector mouse_pos;
float mouse_absolute;

void(void) mouse_relative {
	mouse_pos = mouse_pos + getmousepos();
	mouse_pos_x = bound(0, mouse_pos_x, CVAR(vid_conwidth));
	mouse_pos_y = bound(0, mouse_pos_y, CVAR(vid_conheight));
}

vector(void) mouse_position {
	if (mouse_enabled) {
		if (mouse_absolute)
			return getmousepos();
		else {
			mouse_relative();
			return mouse_pos;
		}
	} else
		return mouse_pos;
}

void(void) mouse_draw {
	if (mouse_enabled) {
		if (mouse_absolute)
			mouse_pos = getmousepos();
		else
			mouse_relative();

		drawpic(mouse_pos, strcat("gfx/menu/", cvar_string("menu_skin"), "/cursor"), '32 32 0', '1 1 1', 1, DRAWFLAG_NORMAL);
		mouse_not_centered = TRUE;
		mouse_enabled = FALSE;
	} else if (mouse_not_centered) {
		mouse_pos = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
		mouse_not_centered = FALSE;
		setcursormode(0);
	}
}

void(float _absolute) mouse_enable {
	mouse_absolute = _absolute;
	if not(mouse_enabled)
	if (CVAR(_menu_alpha) <= 0) {
		if (_absolute)
			setcursormode(1);

		mouse_enabled = TRUE;
	}
}
