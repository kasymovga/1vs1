#if 0
float pixelalign(float rcount, float vcount, float pixelfactor) {
	return rcount/(floor((rcount/vcount)*pixelfactor)/pixelfactor);
}
#endif

void SetConWidthHeight() {
	float width = cvar("vid_width"), height = cvar("vid_height");
	if (width < 1 || height < 1)
		return;

	float i;
	float ratio = width / height;
#if 0
	registercvar("vid_conpixelalign_factor", "8");
	float alignf = bound(1, cvar("vid_conpixelalign_factor"), 16);
#endif
	if (ratio < 1.33) {
#if 0
		float _conwidth = pixelalign(width, 800, alignf);
		cvar_set("vid_conwidth", ftos(_conwidth));
		cvar_set("vid_conheight", ftos(pixelalign(height, _conwidth / ratio, alignf)));
#endif
		float _conwidth = 800;
		cvar_set("vid_conwidth", ftos(_conwidth));
		cvar_set("vid_conheight", ftos(_conwidth / ratio));
	} else {
#if 0
		float _conheight = pixelalign(height, 600, alignf);
		cvar_set("vid_conheight", ftos(_conheight));
		cvar_set("vid_conwidth", ftos(pixelalign(width, _conheight * ratio, alignf)));
#endif
		float _conheight = 600;
		cvar_set("vid_conheight", ftos(_conheight));
		cvar_set("vid_conwidth", ftos(_conheight * ratio));
	}
}
