#define RM_SKIN_FREE(x) { str_unzone_ifneeded(x); x = NULL; }
void(void) rm_skin_unload {
	RM_SKIN_FREE(rm_skin_image_border_left);
	RM_SKIN_FREE(rm_skin_image_border_right);
	RM_SKIN_FREE(rm_skin_image_line_fill);
	RM_SKIN_FREE(rm_skin_image_sector_fill_left);
	RM_SKIN_FREE(rm_skin_image_sector_fill_center);
	RM_SKIN_FREE(rm_skin_image_sector_fill_right);
	RM_SKIN_FREE(rm_skin_image_progress_head);
	rm_skin_size_border_left = '0 0 0';
	rm_skin_size_border_right = '0 0 0';
	rm_skin_offset_border_left = '0 0 0';
	rm_skin_offset_border_right = '0 0 0';
	rm_skin_scale_border_left = 0;
	rm_skin_scale_border_right = 0;
	rm_skin_border_simple = 0;
	rm_skin_width_border_left = 0;
	rm_skin_width_border_right = 0;
	rm_skin_border_teamcolor = RM_SKIN_TC_NEVER;
	rm_skin_sector_teamcolor = RM_SKIN_TC_NEVER;
	rm_skin_line_teamcolor = RM_SKIN_TC_NEVER;
	rm_skin_border_teamcolor_brightness = 0;
	rm_skin_sector_teamcolor_brightness = 0;
	rm_skin_line_teamcolor_brightness = 0;
	rm_skin_sector_color = '0 0 0';
	rm_skin_border_color = '0 0 0';
	rm_skin_sector_alpha = 0;
	rm_skin_border_alpha = 0;
	rm_skin_line_color = '0 0 0';
	rm_skin_line_alpha = 0;
	rm_skin_flash_alphamod = 0;
	rm_skin_flash_intmod = 0;
	rm_skin_border_drawflag = DRAWFLAG_NORMAL;
	rm_skin_sector_gap = '8 12 0';
	rm_skin_sector_gap_screen = 8;
	rm_skin_sector_gap_fract = '0 0 0';
	rm_skin_sector_gap_screen_fract = 0;
	rm_skin_sector_gap_alt = '8 12 0';
	rm_skin_sector_gap_screen_alt = 8;
	rm_skin_sector_gap_fract_alt = '0 0 0';
	rm_skin_sector_gap_screen_fract_alt = 0;
	rm_skin_sector_padding_left = 0;
	rm_skin_sector_padding_right = 0;
	rm_skin_sector_padding_top = 0;
	rm_skin_sector_padding_bottom = 0;
	rm_skin_sector_teamcolor_mod = '0 0 0';
	rm_skin_sector_teamcolor_mod_red = '0 0 0';
	rm_skin_sector_teamcolor_mod_blue = '0 0 0';
	rm_skin_sector_teamcolor_mod_yellow = '0 0 0';
	rm_skin_sector_teamcolor_mod_pink = '0 0 0';
	rm_skin_border_teamcolor_mod = '0 0 0';
	rm_skin_border_teamcolor_mod_red = '0 0 0';
	rm_skin_border_teamcolor_mod_blue = '0 0 0';
	rm_skin_border_teamcolor_mod_yellow = '0 0 0';
	rm_skin_border_teamcolor_mod_pink = '0 0 0';
	rm_skin_line_teamcolor_mod = '0 0 0';
	rm_skin_line_teamcolor_mod_red = '0 0 0';
	rm_skin_line_teamcolor_mod_blue = '0 0 0';
	rm_skin_line_teamcolor_mod_yellow = '0 0 0';
	rm_skin_line_teamcolor_mod_pink = '0 0 0';
	rm_skin_line_full = FALSE;
	rm_skin_flash_line_imod = 0;
	rm_skin_flash_line_amod = 0;
	rm_skin_flash_sector_imod = 0;
	rm_skin_flash_sector_amod = 0;
	rm_skin_flash_border_imod = 0;
	rm_skin_flash_border_amod = 0;
	rm_skin_line_fill = RM_SKIN_FILL_COLOR;
	rm_skin_size_line_fill = '0 0 0';
	rm_skin_sector_fill = RM_SKIN_FILL_COLOR;
	rm_skin_size_sector_fill_center = '0 0 0';
	rm_skin_size_sector_fill_left = '0 0 0';
	rm_skin_size_sector_fill_right = '0 0 0';
	rm_skin_line_padding = '0 0 0';
	rm_skin_progress_bgalpha = 0;
	rm_skin_progress_sector_colormode = 0;
	rm_skin_progress_sector_color = '0 0 0';
	rm_skin_progress_sector_alpha = 0;
	rm_skin_progress_sector_teamcolor_mod = '0 0 0';
	rm_skin_progress_sector_teamcolor_minalpha = 0;
	rm_skin_progress_sector_overcharge_colormod = '0 0 0';
	rm_skin_progress_sector_overcharge_colormul = 0;
	rm_skin_progress_sector_overcharge_alpha = 0;
	rm_skin_progress_border_colormode = 0;
	rm_skin_progress_border_color = '0 0 0';
	rm_skin_progress_border_alpha = 0;
	rm_skin_progress_border_teamcolor_mod = '0 0 0';
	rm_skin_progress_border_teamcolor_minalpha = 0;
	rm_skin_progress_border_overcharge_colormod = '0 0 0';
	rm_skin_progress_border_overcharge_colormul = 0;
	rm_skin_progress_border_overcharge_alpha = 0;
	rm_skin_progress_head_color = '0 0 0';
	rm_skin_progress_head_alpha = 0;
	rm_skin_progress_head_teamcolor = 0;
	print("Unloaded HUD skin\n");
	RM_SKIN_FREE(rm_skin_name);
	rm_skin_loaded = FALSE;
	cvar_set("cl_rm_skin", "");
	updateNexuizSkinList();
	updateNexuizHudList();
}

float(void) rm_skin_read_team_color {
	switch (argv(1)) {
	case "none": case "never":
		return RM_SKIN_TC_NEVER;
	case "all": case "always":
		return RM_SKIN_TC_ALWAYS;
	case "some":
		return RM_SKIN_TC_SOME;
	}
	return RM_SKIN_TC_WTF;
}

vector(void) rm_skin_read_color {
	vector v;
	v_x = stof(argv(1));
	v_y = stof(argv(2));
	v_z = stof(argv(3));
	return v;
}

float(void) rm_skin_read_draw_flag {
	switch (argv(1)) {
	case "normal":
		return DRAWFLAG_NORMAL;
	case "additive":
		return DRAWFLAG_ADDITIVE;
	}
	return -1;
}

float(void) rm_skin_read_bool {
	switch (argv(1)) {
	case "true": case "yes": case "1":
		return TRUE;
	case "false": case "no": case "0":
		return FALSE;
	}
	return (stof(argv(1)) ? TRUE : FALSE);
}

float(void) rm_skin_read_fill_mode {
	switch (argv(1)) {
	case "color":
		return RM_SKIN_FILL_COLOR;
	case "tile":
		return RM_SKIN_FILL_TILE;
	case "stretch":
		return RM_SKIN_FILL_STRETCH;
	default:
		return RM_SKIN_FILL_WTF;
	}
}

float(string cmd) rm_skin_eval {
	float n = tokenize_console(cmd);
	switch (argv(0)) {
	case "border_left_scale":
		rm_skin_scale_border_left = stof(argv(1));
		return 0;
	case "border_right_scale":
		rm_skin_scale_border_right = stof(argv(1));
		return 0;
	case "border_left_offset":
		rm_skin_offset_border_left_x = stof(argv(1));
		rm_skin_offset_border_left_y = stof(argv(2));
		return 0;
	case "border_right_offset":
		rm_skin_offset_border_right_x = stof(argv(1));
		rm_skin_offset_border_right_y = stof(argv(2));
		return 0;
	case "border_simple":
		rm_skin_border_simple = stof(argv(1));
		return 0;
	case "border_left_width":
		rm_skin_width_border_left = stof(argv(1));
		return 0;
	case "border_right_width":
		rm_skin_width_border_right = stof(argv(1));
		return 0;
	case "border_teamcolor":
		rm_skin_border_teamcolor = rm_skin_read_team_color();
		if (rm_skin_border_teamcolor == RM_SKIN_TC_WTF) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_border_teamcolor = RM_SKIN_TC_NEVER;
			return 1;
		}
		return 0;
	case "sector_teamcolor":
		rm_skin_sector_teamcolor = rm_skin_read_team_color();
		if (rm_skin_sector_teamcolor == RM_SKIN_TC_WTF) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_sector_teamcolor = RM_SKIN_TC_NEVER;
			return 1;
		}
		return 0;
	case "line_teamcolor":
		rm_skin_line_teamcolor = rm_skin_read_team_color();
		if (rm_skin_line_teamcolor == RM_SKIN_TC_WTF) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_line_teamcolor = RM_SKIN_TC_NEVER;
			return 1;
		}
		return 0;
	case "border_teamcolor_brightness":
		rm_skin_border_teamcolor_brightness = stof(argv(1));
		return 0;
	case "sector_teamcolor_brightness":
		rm_skin_sector_teamcolor_brightness = stof(argv(1));
		return 0;
	case "line_teamcolor_brightness":
		rm_skin_line_teamcolor_brightness = stof(argv(1));
		return 0;
	case "sector_color":
		rm_skin_sector_color = rm_skin_read_color();
		return 0;
	case "border_color":
		rm_skin_border_color = rm_skin_read_color();
		return 0;
	case "sector_alpha":
		rm_skin_sector_alpha = stof(argv(1));
		return 0;
	case "border_alpha":
		rm_skin_border_alpha = stof(argv(1));
		return 0;
	case "line_color":
		rm_skin_line_color = rm_skin_read_color();
		return 0;
	case "line_alpha":
		rm_skin_line_alpha = stof(argv(1));
		return 0;
	case "flash_alphamod":
		rm_skin_flash_alphamod = stof(argv(1));
		return 0;
	case "flash_intmod":
		rm_skin_flash_intmod = stof(argv(1));
		return 0;
	case "border_drawmode":
		rm_skin_border_drawflag = rm_skin_read_draw_flag();
		if (rm_skin_border_drawflag == -1) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_border_drawflag = DRAWFLAG_NORMAL;
			return 1;
		}
		return 0;
	case "sector_padding":
		rm_skin_sector_padding_left = stof(argv(1));
		rm_skin_sector_padding_right = stof(argv(2));
		rm_skin_sector_padding_top = stof(argv(3));
		rm_skin_sector_padding_bottom = stof(argv(4));
		return 0;
	case "sector_teamcolor_mod":
		rm_skin_sector_teamcolor_mod = rm_skin_read_color();
		return 0;
	case "sector_teamcolor_mod_red":
		rm_skin_sector_teamcolor_mod_red = rm_skin_read_color();
		return 0;
	case "sector_teamcolor_mod_blue":
		rm_skin_sector_teamcolor_mod_blue = rm_skin_read_color();
		return 0;
	case "sector_teamcolor_mod_yellow":
		rm_skin_sector_teamcolor_mod_yellow = rm_skin_read_color();
		return 0;
	case "sector_teamcolor_mod_pink":
		rm_skin_sector_teamcolor_mod_pink = rm_skin_read_color();
		return 0;
	case "border_teamcolor_mod":
		rm_skin_border_teamcolor_mod = rm_skin_read_color();
		return 0;
	case "border_teamcolor_mod_red":
		rm_skin_border_teamcolor_mod_red = rm_skin_read_color();
		return 0;
	case "border_teamcolor_mod_blue":
		rm_skin_border_teamcolor_mod_blue = rm_skin_read_color();
		return 0;
	case "border_teamcolor_mod_yellow":
		rm_skin_border_teamcolor_mod_yellow = rm_skin_read_color();
		return 0;
	case "border_teamcolor_mod_pink":
		rm_skin_border_teamcolor_mod_pink = rm_skin_read_color();
		return 0;
	case "line_teamcolor_mod":
		rm_skin_line_teamcolor_mod = rm_skin_read_color();
		return 0;
	case "line_teamcolor_mod_red":
		rm_skin_line_teamcolor_mod_red = rm_skin_read_color();
		return 0;
	case "line_teamcolor_mod_blue":
		rm_skin_line_teamcolor_mod_blue = rm_skin_read_color();
		return 0;
	case "line_teamcolor_mod_yellow":
		rm_skin_line_teamcolor_mod_yellow = rm_skin_read_color();
		return 0;
	case "line_teamcolor_mod_pink":
		rm_skin_line_teamcolor_mod_pink = rm_skin_read_color();
		return 0;
	case "line_full":
		rm_skin_line_full = rm_skin_read_bool();
		return 0;
	case "flash_line_imod":
		rm_skin_flash_line_imod = stof(argv(1));
		return 0;
	case "flash_line_amod":
		rm_skin_flash_line_amod = stof(argv(1));
		return 0;
	case "flash_sector_imod":
		rm_skin_flash_sector_imod = stof(argv(1));
		return 0;
	case "flash_sector_amod":
		rm_skin_flash_sector_amod = stof(argv(1));
		return 0;
	case "flash_border_imod":
		rm_skin_flash_border_imod = stof(argv(1));
		return 0;
	case "flash_border_amod":
		rm_skin_flash_border_amod = stof(argv(1));
		return 0;
	case "extern_image_border_left":
		RM_SKIN_FREE(rm_skin_image_border_left);
		rm_skin_image_border_left = str_zone_ifneeded(argv(1));
		rm_skin_size_border_left = drawgetimagesize(rm_skin_image_border_left);
		return 0;
	case "extern_image_border_right":
		RM_SKIN_FREE(rm_skin_image_border_right);
		rm_skin_image_border_right = str_zone_ifneeded(argv(1));
		rm_skin_size_border_right = drawgetimagesize(rm_skin_image_border_right);
		return 0;
	case "line_fill":
		rm_skin_line_fill = rm_skin_read_fill_mode();
		if (rm_skin_line_fill == RM_SKIN_FILL_WTF) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_line_fill = RM_SKIN_FILL_COLOR;
			return 1;
		}
		return 0;
	case "extern_image_line_fill":
		RM_SKIN_FREE(rm_skin_image_line_fill);
		rm_skin_image_line_fill = str_zone_ifneeded(argv(1));
		return 0;
	case "extern_image_sector_fill_left":
		RM_SKIN_FREE(rm_skin_image_sector_fill_left);
		rm_skin_image_sector_fill_left = str_zone_ifneeded(argv(1));
		rm_skin_size_sector_fill_left = drawgetimagesize(rm_skin_image_sector_fill_left);
		return 0;
	case "extern_image_sector_fill_right":
		RM_SKIN_FREE(rm_skin_image_sector_fill_right);
		rm_skin_image_sector_fill_right = str_zone_ifneeded(argv(1));
		rm_skin_size_sector_fill_right = drawgetimagesize(rm_skin_image_sector_fill_left);
		return 0;
	case "extern_image_sector_fill_center":
		RM_SKIN_FREE(rm_skin_image_sector_fill_center);
		rm_skin_image_sector_fill_center = str_zone_ifneeded(argv(1));
		rm_skin_size_sector_fill_center = drawgetimagesize(rm_skin_image_sector_fill_left);
		return 0;
	case "extern_image_progress_head":
		RM_SKIN_FREE(rm_skin_image_progress_head);
		rm_skin_image_progress_head = str_zone_ifneeded(argv(1));
		rm_skin_size_progress_head = drawgetimagesize(rm_skin_image_progress_head);
		return 0;
	case "sector_fill":
		rm_skin_sector_fill = rm_skin_read_fill_mode();
		if (rm_skin_line_fill == RM_SKIN_FILL_WTF) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_sector_fill = RM_SKIN_FILL_COLOR;
			return 1;
		}
		return 0;
	case "line_padding":
		rm_skin_line_padding_x = stof(argv(1));
		rm_skin_line_padding_y = stof(argv(2));
		return 0;
	case "progress_bgalpha":
		rm_skin_progress_bgalpha = stof(argv(1));
		return 0;
	case "progress_mode":
		rm_skin_progress_mode = stof(argv(1));
		if (rm_skin_progress_mode < 0 || rm_skin_progress_mode > 4) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_progress_mode = 0;
			return 1;
		}
		return 0;
	case "progress_sector_colormode":
		rm_skin_progress_sector_colormode = stof(argv(1));
		if (rm_skin_progress_sector_colormode < 0 || rm_skin_progress_sector_colormode > 2) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_progress_sector_colormode = 0;
			return 1;
		}
		return 0;
	case "progress_border_colormode":
		rm_skin_progress_border_colormode = stof(argv(1));
		if (rm_skin_progress_border_colormode < 0 || rm_skin_progress_border_colormode > 2) {
			print("rm_skin_eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
			rm_skin_progress_border_colormode = 0;
			return 1;
		}
		return 0;
	case "progress_sector_color":
		rm_skin_progress_sector_color = rm_skin_read_color();
		return 0;
	case "progress_border_color":
		rm_skin_progress_border_color = rm_skin_read_color();
		return 0;
	case "progress_sector_alpha":
		rm_skin_progress_sector_alpha = stof(argv(1));
		return 0;
	case "progress_border_alpha":
		rm_skin_progress_border_alpha = stof(argv(1));
		return 0;
	case "progress_head_alpha":
		rm_skin_progress_head_alpha = stof(argv(1));
		return 0;
	case "progress_head_color":
		rm_skin_progress_head_color = rm_skin_read_color();
		return 0;
	case "progress_head_teamcolor":
		rm_skin_progress_head_teamcolor = stof(argv(1));
		return 0;
	case "progress_sector_teamcolor_mod":
		rm_skin_progress_sector_teamcolor_mod = rm_skin_read_color();
		//missed return is intended
	case "progress_sector_teamcolor_minalpha":
		rm_skin_progress_sector_teamcolor_minalpha = stof(argv(1));
		return 0;
	case "progress_border_teamcolor_mod":
		rm_skin_progress_border_teamcolor_mod = rm_skin_read_color();
		//missed return is intended
	case "progress_border_teamcolor_minalpha":
		rm_skin_progress_border_teamcolor_minalpha = stof(argv(1));
		return 0;
	case "progress_sector_overcharge_alpha":
		rm_skin_progress_sector_overcharge_alpha = stof(argv(1));
		return 0;
	case "progress_sector_overcharge_colormul":
		rm_skin_progress_sector_overcharge_colormul = stof(argv(1));
		return 0;
	case "progress_sector_overcharge_colormod":
		rm_skin_progress_sector_overcharge_colormod = rm_skin_read_color();
		return 0;
	case "progress_border_overcharge_alpha":
		rm_skin_progress_border_overcharge_alpha = stof(argv(1));
		return 0;
	case "progress_border_overcharge_colormul":
		rm_skin_progress_border_overcharge_colormul = stof(argv(1));
		return 0;
	case "progress_border_overcharge_colormod":
		rm_skin_progress_border_overcharge_colormod = rm_skin_read_color();
		return 0;
	case "sector_gap":
		rm_skin_sector_gap_x = stof(argv(1));
		rm_skin_sector_gap_y = stof(argv(2));
		rm_skin_sector_gap_fract_x = stof(argv(3));
		rm_skin_sector_gap_fract_y = stof(argv(4));
		return 0;
	case "sector_gap_screen":
		rm_skin_sector_gap_screen = stof(argv(1));
		rm_skin_sector_gap_screen_fract = stof(argv(2));
		return 0;
	case "sector_gap_alt":
		rm_skin_sector_gap_alt_x = stof(argv(1));
		rm_skin_sector_gap_alt_y = stof(argv(2));
		rm_skin_sector_gap_fract_alt_x = stof(argv(3));
		rm_skin_sector_gap_fract_alt_y = stof(argv(4));
		return 0;
	case "sector_gap_screen_alt":
		rm_skin_sector_gap_screen_alt = stof(argv(1));
		rm_skin_sector_gap_screen_fract_alt = stof(argv(2));
		return 0;
	case "source":
		string fname = strcat("gfx/hud/skins/", argv(1), "/skininfo");
		float fh = fopen(fname, FILE_READ);
		if (fh < 0) {
			print("rm_skin_eval: source: failed to open ", fname, "\n");
			return 1;
		}
		if (fgets(fh) != "#version " RM_SKIN_VERSION) {
			print("rm_skin_eval: source: version mismatch in ", fname, "\n");
			fclose(fh);
			return 1;
		}
		float errs = 0;
		string s;
		while ((s = fgets(fh)))
			errs += rm_skin_eval(s);

		if (errs)
			print("rm_skin_eval: source: ", ftos(errs), " errors in included file ", fname, "\n");

		fclose(fh);
		return errs;
	}
	print("rm_skin_eval: Invalid key ", argv(0), "\n");
	return 1;
}

void(void) rm_skin_load_fallback {
	// This matches the "classic" skin
	rm_skin_border_simple = 2;
	//rm_skin_sector_teamcolor = TC_SOME;
	rm_skin_sector_teamcolor_brightness = 0.2;
	rm_skin_sector_color = '0.2 0.2 0.2';
	rm_skin_border_color = '0 0 0';
	rm_skin_sector_alpha = 0.5;
	rm_skin_border_alpha = 0.8;
	rm_skin_line_color = '0.5 0.5 0.5';
	rm_skin_line_alpha = 0.2;
	rm_skin_flash_alphamod = 1;
	rm_skin_flash_intmod = 1;
	rm_skin_border_drawflag = DRAWFLAG_NORMAL;
	rm_skin_flash_line_imod = 1;
	rm_skin_flash_line_amod = 1;
	rm_skin_flash_sector_imod = 2;
	rm_skin_flash_sector_amod = 0;
	rm_skin_flash_border_imod = 0;
	rm_skin_flash_border_amod = 0;
	rm_skin_progress_bgalpha = 1;
	rm_skin_progress_sector_colormode = 1;
	rm_skin_progress_sector_alpha = 0;
	rm_skin_progress_sector_color = '1 0.5 0';
	rm_skin_progress_mode = 2;
	rm_skin_progress_sector_teamcolor_minalpha = 0;
	rm_skin_progress_sector_teamcolor_mod = '0 0 0';
}

float(string skin_name, string errstr) rm_skin_load_error {
	if (skin_name == RM_SKIN_DEFAULT) {
		print("Failed to load skininfo for the default HUD skin '", skin_name, "': ", errstr, ". Loading builtin fallback.\n");
		rm_skin_load_fallback();
		return FALSE;
	} else {
		print("Failed to load skininfo for HUD skin '", skin_name, "': ", errstr, ". Falling back to '", RM_SKIN_DEFAULT, "'.\n");
		rm_skin_load(RM_SKIN_DEFAULT);
		return FALSE;
	}
}

float(string skin_name) rm_skin_load {
#define RM_SKIN_IMAGE(i) str_zone_ifneeded(strcat("gfx/hud/skins/", skin_name, "/" i))
	dlc_load("rm_skins", FALSE);
	dlc_recheck_all();
	rm_skin_unload();
	if (skin_name == "_builtin_") {
		rm_skin_load_fallback();
		return TRUE;
	}
	float fh, err = 0;
	string s;
	fh = fopen(strcat("gfx/hud/skins/", skin_name, "/skininfo"), FILE_READ);
	if (fh < 0)
		return rm_skin_load_error(skin_name, "fopen failed");

	if (fgets(fh) != "#version " RM_SKIN_VERSION) {
		fclose(fh);
		return rm_skin_load_error(skin_name, "version mismatch");
	}
	precache_pic((rm_skin_image_border_left = RM_SKIN_IMAGE("border_left")));
	precache_pic((rm_skin_image_border_right = RM_SKIN_IMAGE("border_right")));
	precache_pic((rm_skin_image_line_fill = RM_SKIN_IMAGE("line_fill")));
	precache_pic((rm_skin_image_sector_fill_left = RM_SKIN_IMAGE("sector_fill_left")));
	precache_pic((rm_skin_image_sector_fill_center = RM_SKIN_IMAGE("sector_fill_center")));
	precache_pic((rm_skin_image_sector_fill_right = RM_SKIN_IMAGE("sector_fill_right")));
	precache_pic((rm_skin_image_progress_head = RM_SKIN_IMAGE("progress_head")));
	while ((s = fgets(fh)))
		err += rm_skin_eval(s);

	if (err)
		print(ftos(err), " errors in skininfo\n");

	fclose(fh);
	rm_skin_size_border_left = drawgetimagesize(rm_skin_image_border_left);
	rm_skin_size_border_right = drawgetimagesize(rm_skin_image_border_right);
	rm_skin_size_line_fill = drawgetimagesize(rm_skin_image_line_fill);
	rm_skin_size_sector_fill_center = drawgetimagesize(rm_skin_image_sector_fill_center);
	rm_skin_size_sector_fill_left = drawgetimagesize(rm_skin_image_sector_fill_left);
	rm_skin_size_sector_fill_right = drawgetimagesize(rm_skin_image_sector_fill_right);
	rm_skin_size_progress_head = drawgetimagesize(rm_skin_image_progress_head);
	print("Loaded HUD skin '", skin_name, "'\n");
	rm_skin_name = str_zone_ifneeded(skin_name);
	rm_skin_loaded = TRUE;
	cvar_set("cl_rm_skin", skin_name);
	updateNexuizSkinList();
	updateNexuizHudList();
	return TRUE;
#undef RM_SKIN_IMAGE
}

float(float border) rm_skin_get_border_width {
	if (rm_skin_border_simple)
		return rm_skin_border_simple;

	if (border == RM_SKIN_BORDER_LEFT)
		return rm_skin_width_border_left;

	return rm_skin_width_border_right;
}

vector(float colour) rm_skin_get_team_color_mod_sector {
	switch (colour) {
	case COLOR_TEAM1: return rm_skin_sector_teamcolor_mod_red;
	case COLOR_TEAM2: return rm_skin_sector_teamcolor_mod_blue;
	case COLOR_TEAM3: return rm_skin_sector_teamcolor_mod_yellow;
	case COLOR_TEAM4: return rm_skin_sector_teamcolor_mod_pink;
	}
	return '0 0 0';
}

vector(float colour) rm_skin_get_team_color_mod_border {
	switch (colour) {
	case COLOR_TEAM1: return rm_skin_border_teamcolor_mod_red;
	case COLOR_TEAM2: return rm_skin_border_teamcolor_mod_blue;
	case COLOR_TEAM3: return rm_skin_border_teamcolor_mod_yellow;
	case COLOR_TEAM4: return rm_skin_border_teamcolor_mod_pink;
	}
	return '0 0 0';
}

vector(float colour) rm_skin_get_team_color_mod_line {
	switch (colour) {
	case COLOR_TEAM1: return rm_skin_line_teamcolor_mod_red;
	case COLOR_TEAM2: return rm_skin_line_teamcolor_mod_blue;
	case COLOR_TEAM3: return rm_skin_line_teamcolor_mod_yellow;
	case COLOR_TEAM4: return rm_skin_line_teamcolor_mod_pink;
	}
	return '0 0 0';
}

vector rm_skin_sector_border_left_pos;
vector rm_skin_sector_border_left_size;
vector rm_skin_sector_border_right_pos;
vector rm_skin_sector_border_right_size;

void(vector sectorpos, vector sectorsize) rm_skin_get_sector_border_values {
	vector pos_left, pos_right, size_left, size_right;
	float offset_right, offset_left;
	size_left = rm_skin_size_border_left * rm_skin_scale_border_left;
	offset_left = (sectorsize_y - size_left_y) / 2;
	pos_left = sectorpos;
	pos_left_y += offset_left;
	pos_left = pos_left + rm_skin_offset_border_left;
	size_right = rm_skin_size_border_right * rm_skin_scale_border_right;
	offset_right = (sectorsize_y - size_right_y) / 2;
	pos_right = sectorpos + '1 0 0' * sectorsize_x;
	pos_right_x -= size_right_x;
	pos_right_y += offset_right;
	pos_right = pos_right + rm_skin_offset_border_right;
	rm_skin_sector_border_left_pos   = pos_left;
	rm_skin_sector_border_left_size  = size_left;
	rm_skin_sector_border_right_pos  = pos_right;
	rm_skin_sector_border_right_size = size_right;
}

void(vector sectorpos, vector sectorsize, float borderalpha, vector bordercolor) rm_skin_draw_borders {
	if (rm_skin_border_simple)
		draw_borderlines(rm_skin_border_simple, sectorpos, sectorsize, bordercolor, borderalpha, rm_skin_border_drawflag);
	else {
		rm_skin_get_sector_border_values(sectorpos, sectorsize);
		if (rm_skin_size_border_left_x)
			drawpic(rm_skin_sector_border_left_pos, rm_skin_image_border_left, rm_skin_sector_border_left_size, bordercolor, borderalpha, rm_skin_border_drawflag);

		if (rm_skin_size_border_right_x)
			drawpic(rm_skin_sector_border_right_pos, rm_skin_image_border_right, rm_skin_sector_border_right_size, bordercolor, borderalpha, rm_skin_border_drawflag);
	}
}

void(vector sectorpos, vector sectorsize, float basealpha, vector sectorcolor, float drawflag) rm_skin_draw_sector {
	vector fillsize, fillpos;
	fillpos = sectorpos;
	fillsize = sectorsize;
	fillpos_x += rm_skin_sector_padding_left;
	fillsize_x -= rm_skin_sector_padding_left;
	fillsize_x -= rm_skin_sector_padding_right;
	fillpos_y += rm_skin_sector_padding_top;
	fillsize_y -= rm_skin_sector_padding_top;
	fillsize_y -= rm_skin_sector_padding_bottom;
	vector size_left, size_center, size_right;
	float factor;
	switch(rm_skin_sector_fill) {
	case RM_SKIN_FILL_COLOR:
		drawfill(fillpos, fillsize, sectorcolor, basealpha, DRAWFLAG_NORMAL);
		break;
	case RM_SKIN_FILL_TILE: case RM_SKIN_FILL_STRETCH:
		size_left = rm_skin_size_sector_fill_left;
		size_right = rm_skin_size_sector_fill_right;
		size_center = rm_skin_size_sector_fill_center;
		if (rm_skin_sector_fill == RM_SKIN_FILL_STRETCH)
		if (size_left == '0 0 0') if(size_right == '0 0 0') {
			drawpic(fillpos, rm_skin_image_sector_fill_center, fillsize, sectorcolor, basealpha, drawflag);
			break;
		}
		// Autoscaling based on the center area
		if (size_center_y > fillsize_y) {
			factor = fillsize_y / size_center_y;
			size_center = size_center * factor;
			size_left = size_left * factor;
			size_right = size_right * factor;
		}
		vector part_left, part_center, part_right;
		part_left = size_left;
		part_right = size_right;
		part_center = size_center;
		part_center_x = fillsize_x;
		vector origin_left, origin_center, origin_right;
		origin_left = origin_center = origin_right = fillpos;
		origin_center_x = origin_left_x + part_left_x;
		part_center_x -= part_left_x;
		origin_right_x = origin_right_x + fillsize_x - part_right_x;
		part_center_x -= part_right_x;
		if (rm_skin_image_sector_fill_left != "")
			drawpic(origin_left, rm_skin_image_sector_fill_left, size_left, sectorcolor, basealpha, drawflag);

		if (rm_skin_image_sector_fill_center != "") {
			if (rm_skin_sector_fill == RM_SKIN_FILL_STRETCH)
				drawpic(origin_center, rm_skin_image_sector_fill_center, part_center, sectorcolor, basealpha, drawflag);
			else
				draw_pic_tiled(origin_center, rm_skin_image_sector_fill_center, size_center, part_center, sectorcolor, basealpha, drawflag);
		}
		if (rm_skin_image_sector_fill_right != "")
			drawpic(origin_right, rm_skin_image_sector_fill_right, size_right, sectorcolor, basealpha, drawflag);

		break;
	}
}

void(vector slicepos, vector slicesize, vector slicecolor, float slicealpha) rm_skin_draw_slice {
	vector drawsize;
	float factor;
	if (slicesize_x <= 0)
		return;

	slicepos_y  += rm_skin_line_padding_x;
	slicesize_y -= rm_skin_line_padding_x;
	slicesize_y -= rm_skin_line_padding_y;
	switch(rm_skin_line_fill) {
	case RM_SKIN_FILL_COLOR:
		drawfill(slicepos, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL);
		return;
	case RM_SKIN_FILL_TILE:
		drawsize = slicesize;
		if (drawsize_y > rm_skin_size_line_fill_y) {
			// autoscaling
			factor = rm_skin_size_line_fill_y / drawsize_y;
			drawsize = drawsize * factor;
		}
		if (rm_skin_image_line_fill != "")
			draw_pic_tiled(slicepos, rm_skin_image_line_fill, drawsize, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL);

		return;
	
	case RM_SKIN_FILL_STRETCH:
		if (rm_skin_image_line_fill != "")
			draw_pic_tiled(slicepos, rm_skin_image_line_fill, slicesize, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL);

		return;
	}
}

#undef RM_SKIN_FREE
