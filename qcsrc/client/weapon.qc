void(void) weapon_cross_origin_set {
	if (CVAR(chase_active) || physics_plug_adjust_view) {
		traceline(view_origin, view_origin + WORLD_MAX_SHOT_DISTANCE * view_forward, TRACE_MOVE_WORLDONLY, world);
		weapon_cross_origin = view_project_3d_to_2d(trace_endpos);
	} else {
		weapon_cross_origin = view_project_3d_to_2d(view_origin + WORLD_MAX_SHOT_DISTANCE * view_forward);
	}
	weapon_cross_origin_z = 0;
}

void(void) weapon_update_icons {
	entity e;
	string s;
	float i;
	WEAPON_INFO_FOR_EACH(e) {
		str_unzone_ifneeded(e.icon);
		s = strcat("gfx/hud/inv_weapon_", e.netname);
		if not(file_exists_image(s)) {
			if (e.netname == "minstanex")
				s = "gfx/hud/inv_weapon10";
			else if (e.netname == "campingrifle")
				s = "gfx/hud/inv_weapon14";
			else {
				s = strcat("gfx/hud/inv_weapon", ftos(e.weapon - 1));
				if not(file_exists_image(s))
					s = "gfx/hud/num_minus";
			}
		}
		e.icon = strzone(s);
	}
	weapon_info(0).icon = "gfx/hud/num_minus"; //dummy weapon
	font_load_icons();
}

void(void) weapon_info_read {
	float wid, imp, at;
	string n;
	entity e;
	float a;
	while ((wid = net_read_byte())) {
		imp = net_read_byte();
		at = net_read_coord();
		n = str_zone_ifneeded(net_read_string());
		a = net_read_short();
		e = weapon_register_common(wid, imp, n, n);
		if not(cvar(strcat("crosshair_", e.netname, "_size"))) {
			if not(file_exists_image(strcat("gfx/crosshair", e.netname)))
				registercvar(strcat("crosshair_", e.netname), "campingrifle");
			else
				registercvar(strcat("crosshair_", e.netname), e.netname);

			registercvar(strcat("crosshair_", e.netname, "_color_red"), "1");
			registercvar(strcat("crosshair_", e.netname, "_color_green"), "1");
			registercvar(strcat("crosshair_", e.netname, "_color_blue"), "1");
			registercvar(strcat("crosshair_", e.netname, "_color_alpha"), "1");
			registercvar(strcat("crosshair_", e.netname, "_size"), "0.5");
		}
		e.items = at;
		e.health = a;
	}
	weapon_update_icons();
}
