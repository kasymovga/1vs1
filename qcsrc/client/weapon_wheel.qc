entity weapon_wheel_control;
float weapon_wheel_under_cursor;
float weapon_wheel_available;

float(void) weapon_wheel_remove {
	if not(weapon_wheel_control) return FALSE;
	remove(weapon_wheel_control);
	weapon_wheel_control = NULL;
	localcmd("cmd slowmoend\n");
	return TRUE;
}

float(float bInputType, float nPrimary, float nSecondary) weapon_wheel_input_event {
	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			weapon_wheel_remove();
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			weapon_wheel_remove();
			if (weapon_wheel_under_cursor >= 0)
				localcmd("impulse ", ftos(229 + weapon_wheel_under_cursor), "\n");

			return TRUE;
		}
	}
	return FALSE;
}

void(void) weapon_wheel_draw {
	mouse_enable("");
	weapon_wheel_under_cursor = -1;
	sbar_hidescores = TRUE;
	view_fixangle = 1;
	view_fixed_angles = view_camera_angles;
	input_event_callback = weapon_wheel_input_event;
	float weapon_switch = getstati(STAT_SWITCHWEAPON);
	entity e;
	float imp, nr, sp, apos, idx, active, value, a, undercursore;
	float stat_weapons = getstati(STAT_WEAPONS);
	float stat_weapons_extra = getstati(STAT_WEAPONS_EXTRA);
	float fade = 1;
	vector pos = '0 0 0';
	for (idx = 0; idx < 10; ++idx)
		sbar_weaponspace[idx] = 0;

	drawfill('0 0 0', '1 0 0' * CVAR(vid_conwidth) + CVAR(vid_conheight) * '0 1 0', '0.25 0.25 0.25', 0.75, DRAWFLAG_NORMAL);
	vector mpos = mouse_position();
	WEAPON_INFO_FOR_EACH(e) {
		if not(stat_weapons & e.weapons)
		if not(stat_weapons_extra & e.weapons_extra)
			continue;

		imp = e.impulse;
		nr = e.weapon;
		if not(imp >= 0) continue;
		if (imp == 0)
			idx = 9;
		else
			idx = imp - 1;

		active = (nr == weapon_switch);
		value = (active) ? 2 : 0.75;
		sbar_color_x = sbar_color_y = sbar_color_z = value;
		sp = sbar_weaponspace[idx];
		sbar_weaponspace[idx] = sp + 1;
		apos = 2 * MATH_PI * ((idx / 10) - 0.15);
		pos_x = cos(apos) * 200 * (sp ? 1.5 : 1) + CVAR(vid_conwidth) * 0.5 - 40;
		pos_y = sin(apos) * 150 * (sp ? 1.5 : 1) + CVAR(vid_conheight) * 0.5 - 20;
		if (weapon_wheel_under_cursor < 0 && mpos_x >= pos_x - 10 && mpos_y >= pos_y - 10 && mpos_x <= pos_x + 90 && mpos_y <= pos_y + 50) {
			weapon_wheel_under_cursor = e.weapon;
			undercursore = TRUE;
		} else
			undercursore = FALSE;

		if (active || undercursore)
			drawpic(pos, "gfx/hud/sb_ammobg", '80 40 0', '1 1 1', fade * sbar_alpha_fg * (active + undercursore) * 0.5, DRAWFLAG_NORMAL);

		drawpic(pos, e.icon, '80 40 0', sbar_color, fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
		a = 0;
		pos_x += 2;
		e = weapon_info(nr);
		if (e.items) {
			if (e.items & IT_SHELLS)
				a = getstati(STAT_SHELLS);
			else if (e.items & IT_NAILS)
				a = getstati(STAT_NAILS);
			else if (e.items & IT_ROCKETS)
				a = getstati(STAT_ROCKETS);
			else if (e.items & IT_CELLS)
				a = getstati(STAT_CELLS);

			if (a)
				drawstring(pos, ftos(a), '8 8 0', '1 1 1', sbar_alpha_fg * fade, DRAWFLAG_NORMAL);
			else
				drawstring(pos, "X", '8 8 0', '1 0 0', sbar_alpha_fg * fade, DRAWFLAG_NORMAL);
		}
	}
}

float(void) weapon_wheel {
	if not(weapon_wheel_control) {
		weapon_wheel_control = spawn();
		weapon_wheel_control.draw2d = weapon_wheel_draw;
		weapon_wheel_control.draw2dflag = TRUE;
		localcmd("cmd slowmostart\n");
		return TRUE;
	}
	localcmd("cmd slowmostart\n");
	return FALSE;
}

void(void) weapon_wheel_enable {
	weapon_wheel_available = 1;
	registercmd("impulse");
	registercmd("+attack");
}
