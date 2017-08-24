void SetConWidthHeight() {
	float width = cvar("vid_width"), height = cvar("vid_height");
	if (width < 1 || height < 1)
		return;

	float ratio = width / height;
	if (ratio < 1.33) {
		float conwidth = 800;
		cvar_set("vid_conwidth", ftos(conwidth));
		cvar_set("vid_conheight", ftos(conwidth / ratio));
	} else {
		float conheight = 600;
		cvar_set("vid_conheight", ftos(conheight));
		cvar_set("vid_conwidth", ftos(conheight * ratio));
	}
}
