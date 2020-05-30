void(void) ui_con_width_height_set {
	float width = cvar("vid_width"), height = cvar("vid_height");
	if (width < 1 || height < 1)
		return;

	float ratio = width / height;
	if (ratio < 1.33) {
		float _conwidth = 800;
		cvar_set("vid_conwidth", ftos(_conwidth));
		cvar_set("vid_conheight", ftos(_conwidth / ratio));
		cvar_set("menu_vid_conwidth", ftos(_conwidth));
		cvar_set("menu_vid_conheight", ftos(_conwidth / ratio));
	} else {
		float _conheight = 600;
		cvar_set("vid_conheight", ftos(_conheight));
		cvar_set("vid_conwidth", ftos(_conheight * ratio));
		cvar_set("menu_vid_conheight", ftos(_conheight));
		cvar_set("menu_vid_conwidth", ftos(_conheight * ratio));
	}
}
