#define SECWIDTH_NORMAL 103
#define SECWIDTH_WIDE 206
#define SECWIDTH_HEALTH 217
#define HUDLINE_SLICE(code) code; if (!rm_skin_line_full || !linedrawn) { rm_skin_draw_slice(hudline_pos, hudline, slice_basecolor, slice_basealpha); linedrawn = 1; }
#define HUDLINE_SECTOR(code,bg,bbg,a,ba) code rm_skin_draw_sector(hud_sector_pos, hud_sector + sector_mod, a*sector_alphamod, bg, hud_sector_drawflag); rm_skin_draw_borders(hud_sector_pos, hud_sector + sector_mod, ba*sector_alphamod, bbg);
#define BG_SECTOR ((rm_skin_sector_teamcolor == RM_SKIN_TC_ALWAYS) ? sector_teamcolor : sector_basecolor)
#define BG_SECTOR_TEAM ((rm_skin_sector_teamcolor != RM_SKIN_TC_NEVER) ? sector_teamcolor : sector_basecolor)
#define BG_SECTOR_PROGRESS ((rm_skin_progress_sector_colormode) ? ((rm_skin_progress_sector_colormode == 1) ? sector_teamcolor + rm_skin_progress_sector_teamcolor_mod : rm_skin_progress_sector_color) : BG_SECTOR)
#define BG_BORDER ((rm_skin_border_teamcolor == RM_SKIN_TC_ALWAYS) ? border_teamcolor : border_basecolor)
#define BG_BORDER_TEAM ((rm_skin_border_teamcolor != RM_SKIN_TC_NEVER) ? border_teamcolor : border_basecolor)
#define BG_BORDER_PROGRESS ((rm_skin_progress_border_colormode) ? ((rm_skin_progress_border_colormode == 1) ? border_teamcolor + rm_skin_progress_border_teamcolor_mod : rm_skin_progress_border_color) : BG_BORDER)
#define A_SECTOR ((rm_skin_sector_teamcolor == RM_SKIN_TC_ALWAYS) ? sector_teamalpha : sector_basealpha)
#define A_SECTOR_TEAM ((rm_skin_sector_teamcolor != RM_SKIN_TC_NEVER) ? sector_teamalpha : sector_basealpha)
#define A_SECTOR_PROGRESS ((rm_skin_progress_sector_colormode) ? ((rm_skin_progress_sector_colormode == 1) ? max(A_SECTOR_TEAM, rm_skin_progress_sector_teamcolor_minalpha) : rm_skin_progress_sector_alpha) : A_SECTOR)
#define A_BORDER ((rm_skin_border_teamcolor == RM_SKIN_TC_ALWAYS) ? border_teamalpha : border_basealpha)
#define A_BORDER_TEAM ((rm_skin_border_teamcolor != RM_SKIN_TC_NEVER) ? border_teamalpha : border_basealpha)
#define A_BORDER_PROGRESS ((rm_skin_progress_border_colormode) ? ((rm_skin_progress_border_colormode == 1) ? max(A_BORDER_TEAM, rm_skin_progress_border_teamcolor_minalpha) : rm_skin_progress_border_alpha) : A_BORDER)

float th_state;
float teamhud_enabled;
float th_appeartime;
float th_fadetime;
float th_finalstate;
float th_alpha;
float teamhud_wide;
float pwhud_enabled;
float pw_state;
float pw_appeartime;
float pw_fadetime;
float pw_finalstate;
float pw_alpha;

vector sector_clip_pos, sector_clip_size;
vector sector_border_right_pos, sector_border_left_pos, sector_border_right_size, sector_border_left_size;

void(vector sectorpos, vector sectorsize) rm_hud_get_sector_border_values {
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
	sector_border_left_pos   = pos_left;
	sector_border_left_size  = size_left;
	sector_border_right_pos  = pos_right;
	sector_border_right_size = size_right;
}

void(vector sectorpos, vector sectorsize) rm_hud_get_sector_clip_area {
	sector_clip_pos = sectorpos;
	sector_clip_size = sectorsize;
	sector_clip_pos_x += rm_skin_sector_padding_left - 1;
	sector_clip_size_x -= rm_skin_sector_padding_left - 1;
	sector_clip_size_x -= rm_skin_sector_padding_right;
	sector_clip_pos_y += rm_skin_sector_padding_top;
	sector_clip_size_y -= rm_skin_sector_padding_top;
	sector_clip_size_y -= rm_skin_sector_padding_bottom;
}

void(vector sectorpos, vector sectorsize) rm_hud_get_sector_border_clip_area {
	sector_clip_pos = sectorpos;
	sector_clip_size = sectorsize;
	if (rm_skin_border_simple) {
		sector_clip_pos_x  -= rm_skin_border_simple;
		sector_clip_size_x += rm_skin_border_simple*2;
		sector_clip_pos_y  -= rm_skin_border_simple;
		sector_clip_size_y += rm_skin_border_simple*2;
	} else {
		rm_hud_get_sector_border_values(sectorpos, sectorsize);
		float ol = sector_border_left_pos_y;
		float or = sector_border_right_pos_y;
		float al = ol + sector_border_left_size_y;
		float ar = or + sector_border_right_size_y;
		float h  = max(fabs(ol - ar), fabs(or - al));
		float hd = h - sector_clip_size_y;
		sector_clip_pos_x  = sector_border_left_pos_x - 1;
		sector_clip_size_x = sector_border_right_pos_x - sector_clip_pos_x + sector_border_right_size_x + 1;
		sector_clip_pos_y -= hd/2;
		sector_clip_size_y = h;
	}
}

void(vector sectorpos, vector sectorsize) rm_hud_get_sector_full_clip_area {
	vector p, s;
	vector p1, s1, p2, s2;
	rm_hud_get_sector_clip_area(sectorpos, sectorsize);
	p1 = sector_clip_pos; s1 = sector_clip_size;
	rm_hud_get_sector_border_clip_area(sectorpos, sectorsize);
	p2 = sector_clip_pos; s2 = sector_clip_size;
	s = '1 0 0' * fabs((min(p1_x, p2_x) - max(p1_x + s1_x, p2_x + s2_x))) + '0 1 0' * fabs((min(p1_y, p2_y) - max(p1_y + s1_y, p2_y + s2_y)));
	p = '1 0 0' * min(p1_x, p2_x) + '0 1 0' * min(p1_y, p2_y);
	sector_clip_size = s;
	sector_clip_pos  = p;
}

void(float prog, vector hud_sector_pos, vector hud_sector, vector c_sector, vector c_border, float a_sector, float a_border, vector c_sector_p, vector c_border_p, float a_sector_p, float a_border_p, float sector_alphamod, float hud_sector_drawflag, float transition) rm_hud_draw_progress_bar_sector {
	float invert = 0;
	float overcharge = 0;
	if (prog < 0) {
		prog *= -1;
		invert = 1;
	}
	if (prog > 1) {
		prog = prog - 1;
		overcharge = 1;
	}
	if (prog <= 0.01)
		prog = 0;

	float prog_bgalpha = rm_skin_progress_bgalpha;
	if (transition) {
		float t1 = transition;
		float t2 = (1 - transition);
		c_sector = c_sector * t1 + c_sector_p * t2;
		c_border = c_border * t1 + c_border_p * t2;
		a_sector = a_sector * t1 + a_sector_p * t2;
		a_border = a_border * t1 + a_border_p * t2;
		prog_bgalpha = prog_bgalpha + t2 * (1 - prog_bgalpha);
	}
	switch (rm_skin_progress_mode) {
	case 0: // Use the whole sector as both the background and the bar
		rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector * sector_alphamod * prog_bgalpha, c_sector, hud_sector_drawflag);
		rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod * prog_bgalpha, c_border);
		if (overcharge) {
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);
		}
		rm_hud_get_sector_full_clip_area(hud_sector_pos, hud_sector);
		drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
		if (overcharge) {
			if (rm_skin_progress_sector_overcharge_alpha)
				rm_skin_draw_sector(hud_sector_pos, hud_sector,
						a_sector_p * sector_alphamod * rm_skin_progress_sector_overcharge_alpha,
						c_sector_p * rm_skin_progress_sector_overcharge_colormul + rm_skin_progress_sector_overcharge_colormod,
						hud_sector_drawflag);
			if (rm_skin_progress_border_overcharge_alpha)
				rm_skin_draw_borders(hud_sector_pos, hud_sector,
						a_border_p * sector_alphamod * rm_skin_progress_border_overcharge_alpha,
						c_border_p * rm_skin_progress_border_overcharge_colormul + rm_skin_progress_border_overcharge_colormod);
		} else {
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);
		}
		drawresetcliparea();
		break;
	case 1: // Use the border for progressbar, rest as background
		rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector * sector_alphamod, c_sector, hud_sector_drawflag);
		rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod * prog_bgalpha, c_border);
		if (overcharge)
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);

		rm_hud_get_sector_border_clip_area(hud_sector_pos, hud_sector);
		drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
		if (overcharge) { 
			if (rm_skin_progress_border_overcharge_alpha)
				rm_skin_draw_borders(hud_sector_pos, hud_sector,
								a_border_p * sector_alphamod * rm_skin_progress_border_overcharge_alpha,
								c_border_p * rm_skin_progress_border_overcharge_colormul + rm_skin_progress_border_overcharge_colormod);
		} else
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);

		drawresetcliparea();
		break;
	case 2: // Draw border with full opacity, use the rest as progressbar
		rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector * sector_alphamod * prog_bgalpha, c_sector, hud_sector_drawflag);
		if (overcharge)
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);

		rm_hud_get_sector_clip_area(hud_sector_pos, hud_sector);
		drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
		if (overcharge) {
			if (rm_skin_progress_sector_overcharge_alpha)
				rm_skin_draw_sector(hud_sector_pos, hud_sector,
								a_sector_p * sector_alphamod * rm_skin_progress_sector_overcharge_alpha,
								c_sector_p * rm_skin_progress_sector_overcharge_colormul + rm_skin_progress_sector_overcharge_colormod,
								hud_sector_drawflag);
		} else
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);

		drawresetcliparea();
		rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod, c_border);
		break;
	case 3: // Use the border for the normal progress bar and the sector background for overcharge
		rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector * sector_alphamod, c_sector, hud_sector_drawflag);
		if (overcharge) {
			rm_hud_get_sector_clip_area(hud_sector_pos, hud_sector);
			drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
			if (rm_skin_progress_sector_overcharge_alpha)
				rm_skin_draw_sector(hud_sector_pos, hud_sector,
								a_sector_p * sector_alphamod * rm_skin_progress_sector_overcharge_alpha,
								c_sector_p * rm_skin_progress_sector_overcharge_colormul + rm_skin_progress_sector_overcharge_colormod,
								hud_sector_drawflag);

			drawresetcliparea();
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod * prog_bgalpha, c_border);
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);
		} else {
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod * prog_bgalpha, c_border);
			rm_hud_get_sector_border_clip_area(hud_sector_pos, hud_sector);
			drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border_p * sector_alphamod, c_border_p);
			drawresetcliparea();
		}
		break;
	case 4:// Use the sector background for the normal progress bar and the border for overcharge
		rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector * sector_alphamod, c_sector, hud_sector_drawflag);
		if (overcharge) {
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod, c_border);
			rm_hud_get_sector_border_clip_area(hud_sector_pos, hud_sector);
			drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
			if (rm_skin_progress_border_overcharge_alpha)
				rm_skin_draw_borders(hud_sector_pos, hud_sector,
								a_border_p * sector_alphamod * rm_skin_progress_border_overcharge_alpha,
								c_border_p * rm_skin_progress_border_overcharge_colormul + rm_skin_progress_border_overcharge_colormod);

			drawresetcliparea();
		} else {
			rm_hud_get_sector_clip_area(hud_sector_pos, hud_sector);
			drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
			rm_skin_draw_sector(hud_sector_pos, hud_sector, a_sector_p * sector_alphamod, c_sector_p, hud_sector_drawflag);
			drawresetcliparea();
			rm_skin_draw_borders(hud_sector_pos, hud_sector, a_border * sector_alphamod, c_border);
		}
		break;
	}
	if (rm_skin_image_progress_head == "" || !rm_skin_progress_head_alpha)
		return;

	// TODO: more customization options here
	vector hpos = '0 0 0';
	vector hsize = rm_skin_size_progress_head;
	hsize_y = sector_clip_size_y;
	hsize_x *= 0.5;
	hpos_y = sector_clip_pos_y;
	hpos_x = sector_clip_pos_x + sector_clip_size_x*(invert ? 1 - prog : prog) - hsize_x * 0.5;
	float a = rm_skin_progress_head_alpha;
	if (prog > 0.90)
		a *= (1 - prog) / 0.10;
	else if (prog < 0.10)
		a *= 1 - (0.10 - prog) / 0.10;

	if (a) drawpic(hpos, rm_skin_image_progress_head, hsize, rm_skin_progress_head_color, a, DRAWFLAG_NORMAL);
}

float(float i) rm_hud_get_ammo_stat {
	switch (i) {
	case 0: return STAT_SHELLS;
	case 1: return STAT_NAILS;
	case 2: return STAT_ROCKETS;
	case 3: return STAT_CELLS;
	}
	return -1;
}

float(float i) rm_hud_get_ammo_item_code {
	switch(i) {
	case 0: return IT_SHELLS;
	case 1: return IT_NAILS;
	case 2: return IT_ROCKETS;
	case 3: return IT_CELLS;
	}
	return -1;
}

string(float i) rm_hud_get_ammo_picture {
	switch(i) {
	case 0: return "gfx/hud/sb_shells";
	case 1: return "gfx/hud/sb_bullets";
	case 2: return "gfx/hud/sb_rocket";
	case 3: return "gfx/hud/sb_cells";
	}
	return "";
}

float ammo_progress;
float ammonotifytime;
float hg_nadecount_update;
float hg_nadecount2_update;
float ammo_last;
float hg_maxcd;
float hg_maxcd2;

float armorblockpercent = 0.5; //stub value, incorrect

vector(float x, float y, float x) rm_hud_healtharmor_maxdamage { //stub implementation, incorrect
	vector v;
	v_x = x;
	v_y = y;
	v_z = 0;
	return v;
}

void(vector pos, float hgtype, float hgammo, float regen, float regenrate, float regenmax, float regenpaused, float hgcd, float hgcdmax) rm_hud_draw_nadget_regen_sector {
	string hgicon = nadget_TypeToIcon(hgtype, TRUE, 0);
	vector hgcolor = '1 1 1' - '0.3 0.8 0.8' * regenpaused;
	vector hgsize = '32 32 0';
	if (hgcd > 0) {
		float cdh = hgsize_y * (hgcd / hgcdmax);
		drawsetcliparea(pos_x, pos_y, hgsize_x, cdh);
		drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg * 0.3, DRAWFLAG_NORMAL);
		drawsetcliparea(pos_x, pos_y + cdh, hgsize_x, hgsize_y);
		drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawresetcliparea();
	} else {
		drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
	sbar_draw_num(pos + '26 5 0', hgammo, 3, 0, 24, '1 1 1' - '0 1 1' * (!hgammo), 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
}

float vhealth = 0;
float ammo_progress_weapon;
float ammo_progress_max;
void(void) rm_hud_draw {
	float hgregen = 0;
	float hgregen2 = 0;
	vector slice_basecolor = rm_skin_line_color;
	float slice_basealpha = rm_skin_line_alpha;
	float border_basealpha = rm_skin_border_alpha;
	vector color, hudline = '0 0 0', hudline_pos = '0 0 0', hud_sector = '0 0 0', hud_sector_pos = '0 0 0';
	float linedrawn = 0;
	float sector_gap, sector_vgap, sector_sgap;
	float bw_left, bw_right;
	vector sector_basecolor = rm_skin_sector_color;
	vector border_basecolor = rm_skin_border_color;
	float sector_basealpha = rm_skin_sector_alpha;
	float sector_teamalpha = sector_basealpha;
	float border_teamalpha = border_basealpha;
	float sector_alphamod = 1;
	float hud_sector_drawflag = DRAWFLAG_NORMAL;
	float ammosector_pos = 0, nadesector_pos = 0, nadesector2_pos = 0, next_sector;
	vector scoresector_pos = SBAR_SCORE_POSITION_DEFAULT, scoresector_size = '0 0 0';
	vector powerup_pos, teamhud_pos;
	vector base_teamcolor;
	float hgtype = getstati(STAT_HGTYPE);
	if (hgtype)
		hgregen = sbar_nadget_regen(STAT_HGTYPE, STAT_HGREGEN, STAT_HGREGENMAX);

	float hgtype2 = getstati(STAT_HGTYPE2);
	if (hgtype2)
		hgregen2 = sbar_nadget_regen(STAT_HGTYPE2, STAT_HGREGEN2, STAT_HGREGENMAX2);
	if (team_mode) {
		base_teamcolor = team_rgb(team_my);
	} else {
		base_teamcolor_x = CVAR(sbar_color_bg_r);
		base_teamcolor_y = CVAR(sbar_color_bg_g);
		base_teamcolor_z = CVAR(sbar_color_bg_b);
	}
	vector sector_teamcolor = (base_teamcolor + rm_skin_sector_teamcolor_mod + rm_skin_get_team_color_mod_sector(team_my)) * rm_skin_sector_teamcolor_brightness;
	vector border_teamcolor = (base_teamcolor + rm_skin_border_teamcolor_mod + rm_skin_get_team_color_mod_border(team_my)) * rm_skin_border_teamcolor_brightness;
	vector sector_mod = '0 0 0', vdmg_dmgtakenorigin = '0 0 0';
	bw_left = rm_skin_get_border_width(RM_SKIN_BORDER_LEFT);
	bw_right = rm_skin_get_border_width(RM_SKIN_BORDER_RIGHT);
	if (CVAR(cl_rm_hud_alt)) {
		sector_gap   = rm_skin_sector_gap_alt_x      + rm_skin_sector_gap_fract_alt_x      * CVAR(vid_conwidth);
		sector_vgap  = rm_skin_sector_gap_alt_y      + rm_skin_sector_gap_fract_alt_y      * CVAR(vid_conheight);
		sector_sgap  = rm_skin_sector_gap_screen_alt + rm_skin_sector_gap_screen_fract_alt * CVAR(vid_conwidth);
	} else {
		sector_gap   = rm_skin_sector_gap_x          + rm_skin_sector_gap_fract_x          * CVAR(vid_conwidth);
		sector_vgap  = rm_skin_sector_gap_y          + rm_skin_sector_gap_fract_y          * CVAR(vid_conheight);
		sector_sgap  = rm_skin_sector_gap_screen     + rm_skin_sector_gap_screen_fract     * CVAR(vid_conwidth);
	}
	if (!CVAR(cl_rm_hud_old)) {
		sbar_bottom_y -= 10;
		sbar_bottomleft_y -= 10;
		sbar_bottomright_y -= 10;
	}
	float armor, health;
	armor = getstati(STAT_ARMOR);
	health = getstati(STAT_HEALTH);
	//float stat_items = getstati(STAT_ITEMS);
	float stat_weapons = getstati(STAT_WEAPONS);
	float fade = 3.2 - 2 * (time - sbar_weapons_time);
	fade = bound(0.7, fade, 1);
	vector bg_size; // hud background size
	bg_size = '1600 58 0';
	vector s_health = '0 0 0';
	if (CVAR(cl_rm_hud_old)) {
		if (CVAR(viewsize) <= 100 && CVAR(vid_conwidth) <= 1600) {
			if (team_mode)
				color =  team_rgb(team_my) /* * sbar_color_bg_team */; // hud color = team_my color
			else {
				// allow for custom HUD colors in non-teamgames
				color_x = CVAR(sbar_color_bg_r);
				color_y = CVAR(sbar_color_bg_g);
				color_z = CVAR(sbar_color_bg_b);
			}
			#if 0
			HudFlash_Apply(color, sbar_alpha_bg, TRUE, 2, 1);
			drawpic(bottom - '800 58 0', "gfx/hud/sbar", bg_size, hudflash_resultcolor, hudflash_resultalpha, DRAWFLAG_NORMAL);
			#endif
		}
	} else {
		hudline_y = 15;
		hudline_pos_y = sbar_bottom_y - 24;
		hud_sector_y = 21;
		hud_sector_pos_y = sbar_bottom_y - 27;
		if (teamhud_enabled != th_state) {
			if (teamhud_enabled)
				th_appeartime = time;
			else
				th_fadetime = time;

			th_state = teamhud_enabled;
		}
		if (th_state != th_finalstate) {
			if (th_state) {
				th_alpha = 1 - bound(0, 1 - 4 * (time - th_appeartime), 1);
				if (th_alpha >= 1)
					th_finalstate = th_state;
			} else {
				th_alpha = bound(0, 1 - 4 * (time - th_fadetime), 1);
				if (!th_alpha)
					th_finalstate = th_state;
			}
		}
		// same as above, but for powerups HUD
		if (pwhud_enabled != pw_state) {
			if (pwhud_enabled)
				pw_appeartime = time;
			else
				pw_fadetime = time;

			pw_state = pwhud_enabled;
		}
		if (pw_state != pw_finalstate) {
			if (pw_state) {
				pw_alpha = 1 - bound(0, 1 - 4 * (time - pw_appeartime), 1);
				if (pw_alpha >= 1)
					pw_finalstate = pw_state;
			} else {
				pw_alpha = bound(0, 1 - 4 * (time - pw_fadetime), 1);
				if (!pw_alpha)
					pw_finalstate = pw_state;
			}
		}
		vector mxdmg = rm_hud_healtharmor_maxdamage(getstati(STAT_HEALTH), getstati(STAT_ARMOR), armorblockpercent);
		vhealth += (min(mxdmg_x + 1, /*sv_nicehealth*/200 * 2) - vhealth) * frametime * 10;
		if (CVAR(cl_rm_hud_alt)) {/// RM hud layout
			if (rm_skin_line_full) {
				HUDLINE_SLICE({
					hudline_pos_x = 0;
					hudline_x = sbar_topright_x;
				})
			}
			float thlimit;
			// we_need_to_go_wider.jpg
			teamhud_wide = 0;
			// pre-healtharmor
			HUDLINE_SLICE({
				hudline_x = sector_sgap - bw_left;
			})
			// healtharmor
			{
				hud_sector_x = SECWIDTH_HEALTH;
				hud_sector_pos_x = sector_sgap;
				sector_mod = '0 0 0'; //'-1 0 0';
				s_health = hud_sector_pos;
			}
			vdmg_dmgtakenorigin = '1 0 0' * (hud_sector_pos_x + 0.5 * hud_sector_x) + '0 1 0' * hud_sector_pos_y;
			rm_hud_draw_progress_bar_sector(bound(0.01, vhealth/ /*sv_nicehealth*/ 200, 2), hud_sector_pos, hud_sector,
										BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM,
										BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
										sector_alphamod, hud_sector_drawflag, 0);
			// healtharmor | ammo
			HUDLINE_SLICE({
				hudline_x = sector_gap - bw_right - bw_left;
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
			})
			// ammo
			ammosector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + sector_gap;
			hud_sector_x = SECWIDTH_NORMAL;
			sector_mod = '0 0 0';
			thlimit = hud_sector_pos_x + hud_sector_x + sector_gap;
			if (ammo_progress)
				rm_hud_draw_progress_bar_sector(ammo_progress, hud_sector_pos, hud_sector,
										BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
										BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
										sector_alphamod, hud_sector_drawflag, 0);
			else { HUDLINE_SECTOR({}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER) }
			
			if (hgtype) if (ammosector_pos + (SECWIDTH_NORMAL + sector_gap) * 2 < sbar_bottomright_x - sector_sgap - sector_gap - SECWIDTH_NORMAL * 2) {
				// ammo | nades
				HUDLINE_SLICE({
					hudline_x = sector_gap - bw_right - bw_left;
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				})
				
				// nades
				nadesector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + sector_gap;
				hud_sector_x = SECWIDTH_NORMAL;
				sector_mod = '0 0 0';
				sector_alphamod = 1;

				rm_hud_draw_progress_bar_sector(1-hgregen, hud_sector_pos, hud_sector,
										BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
										BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
										sector_alphamod, hud_sector_drawflag, bound(0, time - hg_nadecount_update, 1));

				if (hgtype2) {
					HUDLINE_SLICE({
						hudline_x = sector_gap - bw_right - bw_left;
						hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					})

					nadesector2_pos = hud_sector_pos_x = hudline_pos_x - bw_right + sector_gap;
					rm_hud_draw_progress_bar_sector(1-hgregen2, hud_sector_pos, hud_sector,
											BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
											BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
											sector_alphamod, hud_sector_drawflag, bound(0, time - hg_nadecount2_update, 1));
				}

				thlimit = hud_sector_pos_x + hud_sector_x + sector_gap;
			}
			
			// separator slice:
			//		ammo/nades | teamhud

			float thwidth = (teamhud_wide ? SECWIDTH_WIDE : SECWIDTH_NORMAL);
			next_sector = sbar_bottom_x - thwidth * 0.5;
			float low = (hud_sector_x + hud_sector_pos_x + sector_gap > next_sector);
			if (low) {
				next_sector = sbar_bottomright_x - SECWIDTH_NORMAL - thwidth - sector_sgap - sector_gap;
				if (next_sector < thlimit) {
					thwidth = SECWIDTH_NORMAL;
					teamhud_wide = 0;
					next_sector = sbar_bottomright_x - SECWIDTH_NORMAL - thwidth - sector_sgap - sector_gap;
				}
			}

			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = sbar_topright_x - hudline_pos_x - (sbar_bottomright_x - next_sector) - bw_left;
			})

			// teamhud
			if (th_alpha)
			{
				HUDLINE_SECTOR({
					hud_sector_x = thwidth;
					hud_sector_pos_x = next_sector;
					sector_mod = '0 0 0';
					sector_alphamod = th_alpha;
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
			}
			sector_alphamod = 1;

			if (!teamhud_enabled || teamhud_enabled != th_finalstate)
			{
				hud_sector_pos_x = next_sector;
				hud_sector_x = -bw_right - bw_left;
			}

			teamhud_pos = hud_sector_pos;
			
			if (!low)
			{
				// teamhud | powerups
				next_sector = sbar_bottomright_x - SECWIDTH_NORMAL * 2 - sector_gap - sector_sgap;
				
				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = sbar_topright_x - hudline_pos_x - (sbar_bottomright_x - 
						((!pwhud_enabled || pwhud_enabled != pw_finalstate) ? sbar_bottomright_x - SECWIDTH_NORMAL - sector_sgap : next_sector)) - bw_left;
				})

				// powerups
				if (pw_alpha)
				{
					HUDLINE_SECTOR({
						hud_sector_x = SECWIDTH_NORMAL;
						hud_sector_pos_x = next_sector;
						powerup_pos = hud_sector_pos;
						sector_mod = '0 0 0';
						sector_alphamod = pw_alpha;
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				}
				sector_alphamod = 1;
				
				// powerups | scores
				if not(!pwhud_enabled || pwhud_enabled != pw_finalstate)
				{
					HUDLINE_SLICE({
						hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
						hudline_x = sector_gap - bw_right - bw_left;
					})
				}
				
				// scores
				HUDLINE_SECTOR({
					hud_sector_x = SECWIDTH_NORMAL;
					scoresector_pos_x = hud_sector_pos_x = next_sector + SECWIDTH_NORMAL + sector_gap;
					scoresector_pos_y = hud_sector_pos_y;
					scoresector_pos_z = 0;
					scoresector_size = hud_sector;
					sector_mod = '0 0 0';
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
			} else { // If we don't have enough space, display powerups above the scores sector
				// teamhud | scores
				next_sector = sbar_bottomright_x - SECWIDTH_NORMAL - sector_sgap;
				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = sbar_topright_x - hudline_pos_x - (sbar_bottomright_x - next_sector) - bw_left;
				})
				// scores
				HUDLINE_SECTOR({
					hud_sector_x = SECWIDTH_NORMAL;
					scoresector_pos_x = hud_sector_pos_x = next_sector;
					scoresector_pos_y = hud_sector_pos_y;
					scoresector_pos_z = 0;
					scoresector_size = hud_sector;
					sector_mod = '0 0 0';
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				if (pw_alpha) {
					// powerups (drawn above scores)
					HUDLINE_SECTOR({
						hud_sector_pos_y = hud_sector_pos_y - hud_sector_y - sector_vgap;
						powerup_pos = hud_sector_pos;
						sector_alphamod = pw_alpha;
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
					sector_alphamod = 1;
				}
			}
			// post-scores
			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = sbar_topright_x;
			})
		} else { /// emulate the nexuiz layout
			float centersector;
			centersector = sbar_bottom_x - SECWIDTH_HEALTH * 0.5;
			if (hgtype2)
				centersector -= (SECWIDTH_NORMAL + sector_gap) * 0.5;

			ammosector_pos = centersector - SECWIDTH_NORMAL - sector_gap;
			nadesector_pos = centersector + SECWIDTH_HEALTH + sector_gap;
			nadesector2_pos = nadesector_pos + SECWIDTH_NORMAL + sector_gap;
			float mindist_right = nadesector_pos + SECWIDTH_NORMAL + sector_gap;
			if (hgtype2)
				mindist_right = nadesector2_pos + SECWIDTH_NORMAL + sector_gap;

			if (rm_skin_line_full) {
				HUDLINE_SLICE({
					hudline_pos_x = 0;
					hudline_x = sbar_topright_x;
				})
			}
			float left_sgap = min(sector_sgap, ammosector_pos - sector_gap - SECWIDTH_NORMAL);
			// we_need_to_go_wider.jpg
			teamhud_wide = 0;
			// pre-teamhud
			HUDLINE_SLICE({
				hudline_x = left_sgap - bw_left;
				next_sector = hudline_x + bw_left;
			})
			// teamhud
			if (th_alpha) {
				HUDLINE_SECTOR({
					if (teamhud_wide)
						hud_sector_x = SECWIDTH_WIDE;
					else
						hud_sector_x = SECWIDTH_NORMAL;

					hud_sector_pos_x = next_sector;
					sector_mod = '0 0 0';
					sector_alphamod = th_alpha;
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
			}
			sector_alphamod = 1;
			if (!teamhud_enabled || teamhud_enabled != th_finalstate) {
				hud_sector_x = -bw_left - bw_right;
				hud_sector_pos_x = next_sector;
			}
			teamhud_pos = hud_sector_pos;
			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = sbar_topright_x - hudline_pos_x - (sbar_bottomright_x - ammosector_pos) - bw_left;
			})
			// ammo
			hud_sector_pos_x = ammosector_pos;
			hud_sector_x = SECWIDTH_NORMAL;
			sector_mod = '0 0 0';
			if (ammo_progress)
				rm_hud_draw_progress_bar_sector(-ammo_progress, hud_sector_pos, hud_sector,
										BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
										BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
										sector_alphamod, hud_sector_drawflag, 0);
			else { HUDLINE_SECTOR({}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER) }
			// ammo | health-armor
			HUDLINE_SLICE({
				hudline_x = sector_gap - bw_left - bw_right;
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
			})
			// health-armor
			{
				hud_sector_x = SECWIDTH_HEALTH;
				hud_sector_pos_x = centersector;
				sector_mod = '0 0 0';
				s_health = hud_sector_pos;
			}
			vdmg_dmgtakenorigin = '1 0 0' * (hud_sector_pos_x + 0.5 * hud_sector_x) + '0 1 0' * hud_sector_pos_y;
			rm_hud_draw_progress_bar_sector(bound(0.01, vhealth/ /* sv_nicehealth */ 200, 2), hud_sector_pos, hud_sector,
										BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM,
										BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
										sector_alphamod, hud_sector_drawflag, 0);
			
			// health-armor | nades
			HUDLINE_SLICE({
				hudline_x = sector_gap - bw_left - bw_right;
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
			})
			if (hgtype) {
				// nades
				hud_sector_pos_x = nadesector_pos;
				hud_sector_x = SECWIDTH_NORMAL;
				sector_mod = '0 0 0';
				sector_alphamod = 1;
				rm_hud_draw_progress_bar_sector(1-hgregen, hud_sector_pos, hud_sector,
						BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
						BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
						sector_alphamod, hud_sector_drawflag, bound(0, time - hg_nadecount_update, 1));
				if (hgtype2) {
					HUDLINE_SLICE({
						hudline_x = sector_gap - bw_left - bw_right;
						hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					})
					hud_sector_pos_x = nadesector2_pos;
					rm_hud_draw_progress_bar_sector(1-hgregen2, hud_sector_pos, hud_sector,
											BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
											BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
											sector_alphamod, hud_sector_drawflag, bound(0, time - hg_nadecount2_update, 1));
				} else
					nadesector2_pos = 0;
			} else {
				nadesector_pos = 0;
				nadesector2_pos = 0;
				mindist_right = centersector + SECWIDTH_HEALTH + sector_gap;
				hud_sector_pos_x = hudline_pos_x - bw_right + sector_gap;
				hud_sector_x = -bw_right - bw_left;
			}
			// separator slice:
			// 		powerups/nades | scores
			next_sector = max(mindist_right, sbar_bottomright_x - SECWIDTH_NORMAL - sector_sgap);
			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = sbar_topright_x - hudline_pos_x - (sbar_bottomright_x - next_sector) - bw_left;
			})
			// scores
			HUDLINE_SECTOR({
				hud_sector_x = SECWIDTH_NORMAL;
				scoresector_pos_x = hud_sector_pos_x = next_sector;
				scoresector_pos_y = hud_sector_pos_y;
				scoresector_pos_z = 0;
				scoresector_size = hud_sector;
				sector_mod = '0 0 0';
			}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
			if (pw_alpha) {
				// powerups (drawn above scores)
				HUDLINE_SECTOR({
					hud_sector_pos_y = hud_sector_pos_y - hud_sector_y - sector_vgap;
					powerup_pos = hud_sector_pos;
					sector_alphamod = pw_alpha;
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				sector_alphamod = 1;
			}
			// post-scores
			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = sbar_topright_x;
			})
		}
	}
	if (CVAR(cl_rm_hud_old) && cvar("sbar_hudselector") == 2) { // combined health and armor display
		vector v;
		v = rm_hud_healtharmor_maxdamage(health, armor, armorblockpercent);
		vector num_pos;
		num_pos = sbar_bottom - '96 28 0';
		float x = floor(v_x + 1);
		if (v_z) { // fully armored
			// here, armorideal > armor
			drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_armor", '20 20 0', '1 1 1', sbar_alpha_fg * armor / v_y, DRAWFLAG_NORMAL);
		} else {
			drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_health", '20 20 0', '1 1 1', sbar_alpha_fg * v_y / armor, DRAWFLAG_NORMAL);
			drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		sbar_draw_num_colored(num_pos, x, 24, sbar_alpha_fg); // draw the combined health and armor
	} else {
		vector health_pos, armor_pos;
		if (CVAR(cl_rm_hud_old)) {
			vdmg_dmgtakenorigin = sbar_bottom - '0 30 0';
			if (cvar("sbar_hudselector") == 0) { // old style layout with armor left of health
				armor_pos = sbar_bottom - '96 28 0';
				health_pos = sbar_bottom - '-14 28 0';
			} else {
				health_pos = sbar_bottom - '96 28 0';
				armor_pos = sbar_bottom - '-14 28 0';
			}
		} else {
			health_pos = s_health + '2 -1 0';
			armor_pos = health_pos + '112 0 0';
		}
		// armor
		float x = armor;
		if (x > 0) {
			if (x > 45) {
				if (CVAR(cl_rm_hud_old)) {
					drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					sbar_draw_num_colored(armor_pos, x, 24, sbar_alpha_fg);
				} else {
					drawpic(armor_pos + '-7 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					sbar_draw_num_colored(armor_pos + '24 0 0', x, 24, sbar_alpha_fg);
				}
			} else {
				if (CVAR(cl_rm_hud_old)) {
					drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
					sbar_draw_num_colored(armor_pos, x, 24, (x+10)/55 * sbar_alpha_fg);
				} else {
					drawpic(armor_pos + '-7 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
					sbar_draw_num_colored(armor_pos + '26 0 0', x, 24, (x+10)/55 * sbar_alpha_fg);
				}
			}
		}
		// health
		x = health;
		if (CVAR(cl_rm_hud_old)) {
			drawpic(health_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			sbar_draw_num_colored(health_pos, x, 24, sbar_alpha_fg);
		} else {
			drawpic(health_pos + '0 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			sbar_draw_num_colored(health_pos + '26 0 0', x, 24, sbar_alpha_fg);
		}
	}
	// weapon icons
	sbar_weapons_draw(SBAR_WEAPONS_POSITION_DEFAULT, 1);
	// ammo
	//float a; // i will be the ammo type (already declared), a will contain how much ammo there is of type i
	float a_offset = 0;
	float a_unused = 0;
	for (float i = 0; i < 4; ++i) {
		float a = getstati(rm_hud_get_ammo_stat(i));
		if (sbar_stat_items & rm_hud_get_ammo_item_code(i) || a <= 0)
			++a_unused;
	}
	a_unused = 4 - a_unused;
	float currweapon_ammo = weapon_info(weapon_current).items;
	ammo_progress = -1;
	vector pos = '0 0 0';
	for (float i = 0; i < 4; ++i) {
		float a = getstati(rm_hud_get_ammo_stat(i)); // how much ammo do we have of type i?
		float isclip = 0;
		float itemcode = rm_hud_get_ammo_item_code(i);
		if (itemcode & currweapon_ammo) {
			/*
			FIXME!!!!
			ammo_progress must be calculated
			*/
			a = getstati(STAT_BULLETS_LOADED);
			isclip = TRUE;
			if (ammo_progress_weapon == weapon_current) {
				ammo_progress_max = max(a, ammo_progress_max);
			} else {
				ammo_progress_weapon = weapon_current;
				ammo_progress_max = a;
			}
			ammo_progress = a / ammo_progress_max;
		}
		if (a <= 0 && !isclip)
			continue;

		if (/*g_minstagib ||*/ CVAR(sbar_showcurrentammo) || CVAR(vid_conwidth) < (800 + 100 * !CVAR(cl_rm_hud_old))) {
			if ((currweapon_ammo | sbar_stat_items) & itemcode) {
				if (ammonotifytime < time)
					ammonotifytime = time + 1;

				else ammonotifytime = 0;
				if (CVAR(cl_rm_hud_old)) {
					pos_x = 206;
					pos_y = 33;
					pos = sbar_bottom - pos;
					if (CVAR(vid_conwidth) >= 800)
						drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '107 29 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

					drawpic(pos + '76 3 0', rm_hud_get_ammo_picture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					if (!a)
						draw_pic_expanding(pos + '76 3 0', rm_hud_get_ammo_picture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL, 1 - bound(0, (ammonotifytime - time)*2, 1));
					
					if (a < 10 && !isclip)
						sbar_draw_num(pos + '5 5 0', a, 3, 0, 24, '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '5 5 0', a, 3, 0, 24, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				} else {
					pos_y = 33;
					pos = sbar_bottom - pos;
					pos_x = ammosector_pos;

					drawpic(pos + '0 5 0', rm_hud_get_ammo_picture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					if (!a)
						draw_pic_expanding(pos + '0 5 0', rm_hud_get_ammo_picture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL, 1 - bound(0, (ammonotifytime - time)*2, 1));

					if (a < 10 && !isclip)
						sbar_draw_num(pos + '26 5 0', a, 3, 0, 24, '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '26 5 0', a, 3, 0, 24, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
			}
		} else {
			if (CVAR(cl_rm_hud_old)) {
				switch (i) {
				case 0: pos_x = 286; pos_y = 48; break; // shells
				case 1: pos_x = 286; pos_y = 26; break; // bullets
				case 2: pos_x = 200; pos_y = 48; break; // rockets
				case 3: pos_x = 200; pos_y = 26; break; // cells
				}
				pos = sbar_bottom - pos;
				if ((currweapon_ammo | sbar_stat_items) & itemcode)
					drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '80 22 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				drawpic(pos + '56 3 0', rm_hud_get_ammo_picture(i), '18 18 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				if (a < 10) {
					if ((currweapon_ammo | sbar_stat_items) & itemcode)
						sbar_draw_num(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
				} else {
					if (sbar_stat_items & itemcode)
						sbar_draw_num(pos + '6 4.5 0', a, 3, 0, 16, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0.7 0.7', 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
				}
			} else {
				pos_y = 33;
				pos = sbar_bottom - pos;
				pos_x = ammosector_pos;
				if (((currweapon_ammo | sbar_stat_items) & itemcode) || ((!CVAR(cl_rm_hud_alt) || CVAR(vid_conwidth) < 950) && a_unused == 4 && i == ammo_last)) {
					ammo_last = i;
					drawpic(pos + '0 5 0', rm_hud_get_ammo_picture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					if (a < 10 && !isclip)
						sbar_draw_num(pos + '26 5 0', a, 3, 0, 24, '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '26 5 0', a, 3, 0, 24, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				} else if (!(sbar_stat_items & IT_UNLIMITED_AMMO)) {
					pos_y -= 10;
					pos_x = ammosector_pos - bw_left + ((SECWIDTH_NORMAL + bw_right)/2) + a_offset - (42/2) * min(a_unused, ((CVAR(cl_rm_hud_alt) && CVAR(vid_conwidth) >= 950) ? 4 : 3));
					drawpic(pos, rm_hud_get_ammo_picture(i), '10 10 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					sbar_draw_num(pos + '9 1 0', a, 3, 0, 10, '0.7 0.7 0.7', 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
					a_offset += 42;
				}
			}
		}
	}
	if (ammo_progress < 0)
		ammo_progress = 0;

	// nades
	vector hgapos = '0 0 0';
	hgapos_y = CVAR(vid_conheight) - CVAR(vid_conheight)/7;
	float hgammo = getstati(STAT_HGAMMO);
	float hgdetons = getstati(STAT_HGDETONABLES);
	float hgcd, hgcd2 = 0;
	if (hgtype) {
		hgcd = getstatf(STAT_HGREFIRE) - servertime;
		if (hgcd > 0) {
			if (hgcd > hg_maxcd) hg_maxcd = hgcd;
		} else hg_maxcd = 0;
		if (hgtype2) {
			hgcd2 = getstatf(STAT_HGREFIRE2) - servertime;
			if (hgcd2 > 0) {
				if (hgcd2 > hg_maxcd2) hg_maxcd2 = hgcd2;
			} else hg_maxcd2 = 0;
		}
		if (nadesector_pos) {
			pos_y = 33;
			pos = sbar_bottom - pos;
			pos_x = nadesector_pos;
			rm_hud_draw_nadget_regen_sector(pos, hgtype, hgammo, getstatf(STAT_HGREGEN), getstatf(STAT_HGREGENRATE), getstatf(STAT_HGREGENMAX), getstati(STAT_HGREGENPAUSED), hgcd, hg_maxcd);
			if (nadesector2_pos) {
				pos_x = nadesector2_pos;
				rm_hud_draw_nadget_regen_sector(pos, getstati(STAT_HGTYPE2), getstati(STAT_HGAMMO2), getstatf(STAT_HGREGEN2), getstatf(STAT_HGREGENRATE2), getstatf(STAT_HGREGENMAX2), getstati(STAT_HGREGENPAUSED2), hgcd2, hg_maxcd2);
			}
		} else {
			// HUD doesn't support the nade sector - fallback to the old display method
			if (hgammo)
				draw_string_colorcoded_center(hgapos, strcat(nadget_TypeToExpandedName(hgtype), "s: ^3", ftos(hgammo)), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			else
				draw_string_colorcoded_center(hgapos, strcat(nadget_TypeToExpandedName(hgtype), "s: ^1", ftos(hgammo)), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			
			if (hgregen && hgregen != 1) {
				vector hgrsize = '70 3 0';
				hgapos_y += 10;
				hgapos_x = (CVAR(vid_conwidth) - hgrsize_x) * 0.5;
				hgrsize_x *= hgregen;
				drawfill(hgapos, hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED), 0.5, DRAWFLAG_NORMAL);
			}
			if (hgtype2) {
				hgapos_y += 5;
				hgammo = getstati(STAT_HGAMMO2);
				if (hgammo)
					draw_string_colorcoded_center(hgapos, strcat(nadget_TypeToExpandedName(hgtype2), "s: ^3", ftos(hgammo)), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
				else
					draw_string_colorcoded_center(hgapos, strcat(nadget_TypeToExpandedName(hgtype2), "s: ^1", ftos(hgammo)), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
				
				if (hgregen2 && hgregen2 != 1) {
					vector hgrsize = '70 3 0';
					hgapos_y += 10;
					hgapos_x = (CVAR(vid_conwidth) - hgrsize_x) * 0.5;
					hgrsize_x *= hgregen2;
					drawfill(hgapos, hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED), 0.5, DRAWFLAG_NORMAL);
				}
			}
		}
		sbar_nadget_messages(hgtype, hgapos, hgdetons, hgammo);
	}
	// draw scores and timer
	sbar_score_draw(scoresector_pos, scoresector_size, 1);
	sbar_timer();
	// draw strength/invincibility icon and timer
	sbar_powerups_draw(/*powerup_pos*/);
	sbar_runes_draw();
	sbar_gametype_hud(((CVAR(cl_rm_hud_alt) && !CVAR(cl_rm_hud_old)) ? '200 0 2' : '0 0 8'), 1);
}
