
void Mouse_Init() {
	mouse_pos = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
}

void Mouse_ReadPos() {
	mouse_pos = mouse_pos + getmousepos();
	mouse_pos_x = bound(0, mouse_pos_x, CVAR(vid_conwidth));
	mouse_pos_y = bound(0, mouse_pos_y, CVAR(vid_conheight));
}

void Mouse_Draw() {
	drawpic(mouse_pos, strcat("gfx/menu/", cvar_string("menu_skin"), "/cursor.tga"), '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}
