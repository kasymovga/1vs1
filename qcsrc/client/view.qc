float view_drawtime;
float view_project_is_broken;
float view_old_view_width, view_old_view_height, view_old_zoom, view_old_fov, view_old_vid_pixelheight;
float view_fovx, view_fovy; //must be global because of goto skip
float view_zoomscript_caught;
float view_camera_mode;
float view_anybutton_zoom;
float view_spectatorbutton_zoom;
float view_zoom_current;
float view_damage_time, view_damage_roll, view_damage_pitch;
vector view_punchangle;

void(void) view_camera_setup;
void(void) view_vehicle_hud;

vector(void) view_fov_calculate {
	float zoomdir, zoomfactor, zoomspeed;
	zoomfactor = CVAR(cl_zoomfactor);
	if (zoomfactor < 1 || zoomfactor > 16)
		zoomfactor = 2.5;

	zoomspeed = CVAR(cl_zoomspeed);
	if (zoomspeed >= 0)
		if (zoomspeed < 0.5 || zoomspeed > 16)
			zoomspeed = 3.5;

	zoomdir = view_anybutton_zoom;
	if (view_spectatee_status > 0 || main_isdemo)
	if (view_spectatorbutton_zoom)
		zoomdir = (zoomdir ? 0 : 1);

	if (view_camera_free_active) {
		view_zoom_current = min(1, view_zoom_current + view_drawframetime);
	} else {
		if (zoomspeed < 0) { // instant zoom
			if (zoomdir)
				view_zoom_current = 1 / zoomfactor;
			else
				view_zoom_current = 1;
		} else {
			if (zoomdir)
				view_zoom_current = 1 / bound(1, 1 / view_zoom_current + view_drawframetime * zoomspeed * (zoomfactor - 1), zoomfactor);
			else
				view_zoom_current = bound(1 / zoomfactor, view_zoom_current + view_drawframetime * zoomspeed * (1 - 1 / zoomfactor), 1);
		}
	}
	if (math_almost_equals(view_zoom_current, 1))
		view_zoom_fraction_current = 0;
	else if (math_almost_equals(view_zoom_current, 1/zoomfactor))
		view_zoom_fraction_current = 1;
	else
		view_zoom_fraction_current = (view_zoom_current - 1) / (1/zoomfactor - 1);

	if (CVAR(cl_zoomsensitivity) < 1)
		setsensitivityscale(pow(view_zoom_current, 1 - CVAR(cl_zoomsensitivity)));
	else
		setsensitivityscale(1);

	if (view_old_zoom == view_zoom_current)
	if (view_old_fov == view_fov)
	if (view_old_view_width == view_width)
	if (view_old_view_height == view_height)
	if (view_old_vid_pixelheight == CVAR(vid_pixelheight))
		goto skip;

	view_old_zoom = view_zoom_current;
	view_old_view_width = view_width;
	view_old_view_height = view_height;
	view_old_fov = view_fov;
	view_old_vid_pixelheight = CVAR(vid_pixelheight);
	float frustumx, frustumy;
	view_fov_zoomed = view_fov * view_zoom_current;
	frustumy = tan(view_fov * 0.00872664625997164788) * 0.75 * view_zoom_current;
	frustumx = frustumy * view_width / view_height / CVAR(vid_pixelheight);
	view_fovx = atan2(frustumx, 1) / 0.00872664625997164788;
	view_fovy = atan2(frustumy, 1) / 0.00872664625997164788;
:skip
	return '1 0 0' * view_fovx + '0 1 0' * view_fovy;
}

float view_tint_effect_shield;
void view_tint_effect(void) {
	float st = getstati(STAT_STEALTH);
	float s = st || getstatf(STAT_HGSHIELD);
	vector fullscreen;
	fullscreen_x = CVAR(vid_conwidth);
	fullscreen_y = CVAR(vid_conheight);
	fullscreen_z = 0;
	if (s)
		view_tint_effect_shield = approach(view_tint_effect_shield, 1, frametime * 3);
	else
		view_tint_effect_shield = approach(view_tint_effect_shield, 0, frametime * 3);

	if (view_tint_effect_shield) {
		if (st) {
			drawfill('0 0 0', fullscreen, '1 1 1', 0.1 * view_tint_effect_shield, DRAWFLAG_MODULATE);
		} else {
			vector clr = '1 1 0.5';
			drawfill('0 0 0', fullscreen, clr * view_tint_effect_shield + '1 1 1' * (1 - view_tint_effect_shield), 1, DRAWFLAG_MODULATE);
			drawfill('0 0 0', fullscreen, clr, 0.1 * view_tint_effect_shield, DRAWFLAG_ADDITIVE);
		}
	}
}

vector(float x) view_healthcolor {
	vector c;
	c_z = 0;
	x = 200 * (x / sbar_health_nice);
	if(x > 600) {
		c_x = 0;
		c_y = 1;
		c_z = 1;
	} else if(x > 200) {
		c_x = 0;
		c_y = 1;
		c_z = (x-200)*0.0025;
	} else if(x > 150) {
		c_x = 0.4 - (x-150)*0.02 * 0.4;
		c_y = 0.9 + (x-150)*0.02 * 0.1;
	} else if(x > 100) {
		c_x = 1 - (x-100)*0.02 * 0.6;
		c_y = 1 - (x-100)*0.02 * 0.1;
		c_z = 1 - (x-100)*0.02;
	} else if(x > 50) {
		c_x = 1;
		c_y = 1;
		c_z = 0.2 + (x-50)*0.02 * 0.8;
	} else if(x > 20) {
		c_x = 1;
		c_y = (x-20)*90/27/100;
		c_z = (x-20)*90/27/100 * 0.2;
	} else {
		c_x = 1;
		c_y = 0;
	}
	return c;
}

void(float w, float h) CSQC_UpdateView { //called by engine
	entity e;
	view_vehicle = FALSE;
	read_cvars();
	view_spectatee_status = getstati(STAT_SPECSTATUS);
	player_deadflag = getstati(STAT_PLAYER_STATE);
	view_spectatorbutton_zoom = view_spectatee_status & 256;
	view_spectatee_status = view_spectatee_status & 255;
	view_observer_status = (view_spectatee_status ? (view_spectatee_status == player_localentnum) : 0);
	if (view_spectatee_status)
		team_my = player_color(view_spectatee_status - 1);
	else
		team_my = player_color(player_localentnum - 1);

	server_ticrate = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
	// Render the Scene
	view_width = w;
	view_height = h;
	view_crosshair = TRUE;
	fog_force();
	view_drawframetime = max(0.000001, time - view_drawtime);
	view_drawtime = time;
	view_fov = cvar("fov");
	view_anybutton_zoom = input_button_zoom;
	if (input_button_attack2_allowed) {
		if (getstati(STAT_ACTIVEWEAPON) == WEAPON_NEX)
		if not(CVAR(cl_nex_secondary_zoom_disable))
			view_anybutton_zoom += input_button_attack2;
	}
	if (view_anybutton_zoom || view_fov <= 59.5) {
		if not(view_zoomscript_caught)
		if not(input_button_zoom) {
			localcmd("+button4\n");
			view_zoomscript_caught = 1;
			cmd_ignore_plus_zoom += 1;
		}
	} else {
		if (view_zoomscript_caught) {
			localcmd("-button4\n");
			view_zoomscript_caught = 0;
			cmd_ignore_minus_zoom += 1;
		}
	}
	sbar_alpha_fg = CVAR(sbar_alpha_fg) * (1 - CVAR(_menu_alpha));
	weapon_current = getstati(STAT_WEAPON);
	// ALWAYS Clear Current Scene First
	R_ClearScene();
	// Assign Standard Viewflags
	// Draw the World (and sky)
	R_SetView(VF_DRAWWORLD, 1);
	view_angles = input_angles;
	view_origin = physics_view_origin();
	warpzone_view_fix();
	physics_camera_setup();
	if (view_recoil_mode) {
		makevectors(view_angles + view_punchangle);
	} else
		makevectors(view_angles);

	view_forward = v_forward;
	view_right = v_right;
	view_up = v_up;
	if (view_fixangle) {
		R_SetView(VF_ANGLES, view_fixed_angles);
		if (view_fixangle > 0)
			R_SetView(VF_CL_VIEWANGLES, view_fixed_angles);

		view_fixangle = 0;
		view_camera_angles = view_fixed_angles;
	} else {
		vector v = '0 0 0';
		if (CVAR(cl_recoil) || view_recoil_mode) v += view_punchangle;
		if (view_kickangles) {
			if (dmg_take || dmg_save) {
				float f = (dmg_take + dmg_save) * 0.5;
				vector v = normalize(view_origin - dmg_origin);
				if (v != '0 0 0') {
					view_damage_roll = CVAR(v_kickroll) * (v * view_right) * f;
					view_damage_pitch = CVAR(v_kickpitch) * (v * view_forward) * f;
					view_damage_time = CVAR(v_kicktime);
				}
				dmg_take = 0;
				dmg_save = 0;
			}
			if (view_damage_time && CVAR(v_kicktime)) {
				float f = view_damage_time / CVAR(v_kicktime);
				v += (view_damage_pitch * '1 0 0' * f + view_damage_roll * '0 0 1' * f);
				view_damage_time = max(0, view_damage_time - view_drawframetime);
			}
		}
		R_SetView(VF_ANGLES, view_angles + v);
		view_camera_angles = view_angles;
	}
	// Set the console size vars
	R_SetView(VF_FOV, view_fov_calculate());
	// Camera for demo playback
	if (view_camera_free_active) {
		if (CVAR(camera_enable)
#ifndef CAMERATEST
				&& main_isdemo
#endif
				)
			view_camera_setup();
		else {
			chase_unlock();
			cvar_set("cl_demo_mousegrab", "0");
			view_camera_free_active = FALSE;
		}
	} else if (CVAR(camera_enable)
#ifndef CAMERATEST
			&& main_isdemo
#endif
			) {
		// Enable required Darkplaces cvars
		chase_lock();
		cvar_set("cl_demo_mousegrab", "1");
		view_camera_free_active = TRUE;
		view_camera_mode = FALSE;
	}
	sbar_hidescores = FALSE;
	R_SetView(VF_DRAWCROSSHAIR, 0); //Make sure engine crosshairs are always hidden
	R_SetView(VF_DRAWENGINESBAR, 0);
	e = self;
	for (self = world; (self = nextent(self)); )
		if (self.draw)
			self.draw();

	self = e;
	R_AddEntities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	R_RenderScene();
	// now switch to 2D drawing mode by calling a 2D drawing function
	// then polygon drawing will draw as 2D stuff, and NOT get queued until the
	// next R_RenderScene call
	drawstring('0 0 0', "", '1 1 0', '1 1 1', 0, 0);
	view_tint_effect();
	// draw 2D entities
	e = self;
	float max2dflag = 1;
	for (self = findflags(NULL, draw2dflag, 63); self; self = findflags(self, draw2dflag, 63)) {
		if (self.draw2dflag > max2dflag)
			max2dflag = self.draw2dflag;
		else if (self.draw2dflag == 1)
			self.draw2d();
	}
	if (max2dflag > 1) {
		float i;
		if (max2dflag > 2)
			sbar_hidescores = TRUE;

		for (i = 2; i <= max2dflag; i++)
			for (self = findfloat(NULL, draw2dflag, i); self; self = findfloat(self, draw2dflag, i)) {
				self.draw2d();
			}
	}
	self = e;
	// draw radar
	if (radar_show)
		radar_view(TRUE, "");
	else if (CVAR(cl_teamradar)) {
		if (CVAR(cl_teamradar) == 2 || team_mode)
		if (view_crosshair)
			radar_view(FALSE, "");
	}
	if (view_observer_status)
		view_crosshair = FALSE;
	else if (sbar_hidescores)
		view_crosshair = FALSE;

	if (!sbar_showscores && !sbar_hidescores) {
		if (CVAR(cl_showpressedkeys)) { // draw pressed keys when spectating and playing
			if ((view_spectatee_status > 0 && !view_observer_status) || CVAR(cl_showpressedkeys) >= 2)
				sbar_pressedkeys_draw();
		}
		if (CVAR(cl_showspeed))
			sbar_speed_draw();

		if (CVAR(cl_showacceleration))
			sbar_acceleration_draw();
	}
	centerprint_draw(); // draw centerprint messages even if viewsize >= 120
	if (view_vehicle) {
		vector sz;
		view_vehicle_hud();
		if (view_crosshair) {
			#define SPIDER_CROSS "textures/spiderbot/cross"
			sz = drawgetimagesize(SPIDER_CROSS);
			sz_x *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
			sz_y *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
			weapon_cross_origin_set();
			drawpic(weapon_cross_origin - 0.5 * sz, SPIDER_CROSS, sz, '1 1 1', CVAR_OR(cl_vehicle_spiderbot_cross_alpha,0.6), DRAWFLAG_NORMAL);
			#undef SPIDER_CROSS
		}
	} else {
		if (CVAR(viewsize) < 120)
			sbar_draw();

		// crosshair goes VERY LAST
		if (view_crosshair) {
			weapon_cross_origin_set();
			string wcross_style;
			wcross_style = cvar_string("crosshair");
			if (wcross_style != "0") {
				vector wcross_color = '0 0 0', wcross_size;
				string wcross_wep, wcross_name;
				float wcross_alpha, wcross_sizefloat;
				wcross_alpha = CVAR(crosshair_color_alpha) * (1-CVAR(_menu_alpha));
				wcross_sizefloat = CVAR(crosshair_size) * (1-CVAR(_menu_alpha));
				if (CVAR(crosshair_per_weapon)) {
					e = weapon_info(weapon_current);
					if (e && e.netname != "") {
						wcross_wep = e.netname;
						wcross_style = cvar_string(strcat("crosshair_", wcross_wep));
						if (wcross_style == "")
							wcross_style = e.netname;

						if (!CVAR(crosshair_color_override)) {
							wcross_color_x = cvar(strcat("crosshair_", wcross_wep, "_color_red"));
							wcross_color_y = cvar(strcat("crosshair_", wcross_wep, "_color_green"));
							wcross_color_z = cvar(strcat("crosshair_", wcross_wep, "_color_blue"));
						}
						wcross_alpha *= cvar(strcat("crosshair_", wcross_wep, "_color_alpha"));
						wcross_sizefloat *= cvar(strcat("crosshair_", wcross_wep, "_size"));
					}
				} else {
					if (view_crosshair_hittime >= time) {
						wcross_color_x = CVAR(crosshair_hit_color_red);
						wcross_color_y = CVAR(crosshair_hit_color_green);
						wcross_color_z = CVAR(crosshair_hit_color_blue);
						wcross_sizefloat *= CVAR(crosshair_hit_size);
					} else {
						wcross_color_x = CVAR(crosshair_color_red);
						wcross_color_y = CVAR(crosshair_color_green);
						wcross_color_z = CVAR(crosshair_color_blue);
					}
				}
				RM(
					if (CVAR(rm_crosshealth)) {
						vector x = rm_hud_healtharmor_maxdamage(getstati(STAT_HEALTH), getstati(STAT_ARMOR), sbar_armor_block_percentage);
						wcross_color = view_healthcolor(x_x);
					}
					rm_crosshair_ring_draw(weapon_cross_origin, wcross_color, wcross_alpha);
				)
				wcross_name = strcat("gfx/crosshair", wcross_style);
				wcross_size = drawgetimagesize(wcross_name);
				wcross_size_x *= wcross_sizefloat;
				wcross_size_y *= wcross_sizefloat;
				drawpic(weapon_cross_origin - '0.5 0 0' * (wcross_size_x) - '0 0.5 0' * ( wcross_size_y), wcross_name, wcross_size, wcross_color, wcross_alpha, DRAWFLAG_NORMAL);
				if (CVAR(crosshair_dot)) {
					vector dot_color = wcross_color;
					if (CVAR(crosshair_dot_color_custom)) {
						string dot_color_string = cvar_string("crosshair_dot_color");
						if (dot_color_string != "0")
							dot_color = stov(dot_color_string);
					}
					drawpic(weapon_cross_origin - '0.5 0 0' * (wcross_size_x * CVAR(crosshair_dot_size)) - '0 0.5 0' * (wcross_size_y * CVAR(crosshair_dot_size)), view_crosshairdot_tex, wcross_size * CVAR(crosshair_dot_size), dot_color, wcross_alpha * CVAR(crosshair_dot_alpha), DRAWFLAG_NORMAL);
				}
			}
		}
	}
	if (view_draw2d_post) {
		e = self;
		self = view_draw2d_post_self;
		view_draw2d_post();
		view_draw2d_post = NULL;
		view_draw2d_post_self = NULL;
		self = e;
	}
	mouse_draw();
	// we must do this check AFTER a frame was rendered, or it won't work
	if (view_project_is_broken == 0) {
		string w0, h0;
		w0 = cvar_string("vid_conwidth");
		h0 = cvar_string("vid_conheight");
		//R_SetView(VF_VIEWPORT, '0 0 0', '640 480 0');
		//R_SetView(VF_FOV, '90 90 0');
		R_SetView(VF_ORIGIN, '0 0 0');
		R_SetView(VF_ANGLES, '0 0 0');
		R_SetView(VF_PERSPECTIVE, 1);
		makevectors('0 0 0');
		vector v1, v2;
		cvar_set("vid_conwidth", "800");
		cvar_set("vid_conheight", "600");
		v1 = cs_project(v_forward);
		cvar_set("vid_conwidth", "640");
		cvar_set("vid_conheight", "480");
		v2 = cs_project(v_forward);
		if (v1 == v2)
			view_project_is_broken = 1;
		else
			view_project_is_broken = -1;

		cvar_set("vid_conwidth", w0);
		cvar_set("vid_conheight", h0);
	}
	// be safe against triggerbots until everyone has the fixed engine
	// this call is meant to overwrite the trace globals by something
	// unsuspicious
	traceline('0 0 0', '0 0 0', TRACE_MOVE_WORLDONLY, world);
}

void(void) view_vehicle_hud {
	float rockets,reload,heat,hp,shield,i;
	vector p,pp;
	sbar_draw();
	rockets = getstati(STAT_SPIDERBOT_ROCKETS);
	heat = min(getstatf(STAT_SPIDERBOT_HEAT),1);
	reload = min(getstatf(STAT_SPIDERBOT_RELOAD),1);
	hp = min(getstatf(STAT_SPIDERBOT_HEALTH),1);
	shield = min(getstatf(STAT_SPIDERBOT_SHIELD),1);
	// Draw health bar
	#define rkt_size 32
	p = '0.5 0 0' * (CVAR(vid_conwidth) - (rkt_size * 8));
	p = p + '0 1 0' * CVAR(vid_conheight) - '0 72 0';
	//pp = ('0 1 0' * hp) + ('1 0 0' * (1-hp));
	if (shield >= 0)
		drawfill(p, '256 0 0' * shield + '0 8 0' , '0.5 0.5 1', 0.75, DRAWFLAG_NORMAL);

	p_y += 8;
	drawfill(p, '256 0 0' * hp + '0 8 0' , '0 1 0', 0.75, DRAWFLAG_NORMAL);
	p_x += 256 * hp;
	drawfill(p, '256 0 0' * (1-hp) + '0 8 0' , '0 0 0', 0.75, DRAWFLAG_NORMAL);
	// Draw heat indicator
	if (heat >= 0) {
		p = '0.5 0 0' * (CVAR(vid_conwidth) - 256);
		p = p + '0 1 0' * CVAR(vid_conheight) - '0 74  0';
		drawfill(p, '256 0 0' * (1-heat) + '0 2 0' ,'0 0 1', 0.5, DRAWFLAG_NORMAL);
		p_x += 256 * (1-heat);
		drawfill(p, '256 0 0' * heat  + '0 2 0' , '1 0 0', 0.5, DRAWFLAG_NORMAL);
	}
	// Draw rocket icons for loaded/empty tubes.
	if (rockets >= 0) {
		#define spider_rocket_icon "gfx/spiderbot/rocket_ico"
		pp = '0.5 0 0' * (CVAR(vid_conwidth) - (rkt_size * 8));
		pp += '0 1 0' * CVAR(vid_conheight) - '0 104 0';
		for (i = 0; i < 8; ++i) {
			p = pp + '1 0 0' * (rkt_size * i);
			if (rockets == 8) {
				if (floor(reload * 8) == i) {
					drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 0 0' + '0 1 0' * ((reload*8)-i), 0.75 , DRAWFLAG_NORMAL);
				} else if (i < reload * 8)
					drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 1 0', 0.75 , DRAWFLAG_NORMAL);
				else
					drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0.5 0.5 0.5', 0.75, DRAWFLAG_NORMAL);
			} else {
				if (i < rockets)
					drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 0 0', 0.25, DRAWFLAG_NORMAL);
				else
					drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 1 0' * reload, 0.75, DRAWFLAG_NORMAL);
			}
		}
		#undef spider_rocket_icon
	}
	#undef rkt_size
}

// following vectors must be global to allow seamless switching between camera modes
vector view_camera_free_offset, view_camera_free_offset, view_camera_mouse_angles, view_camera_free_angles, view_camera_free_origin, view_camera_free_position;
void(void) view_camera_setup {
	float speed, attenuation, dimensions;
	vector tmp, delta;
	if (view_camera_script_active) {
		view_camera_script();
		return;
	}
	if (cvar("camera_reset") || !view_camera_mode) {
		view_camera_free_offset = '0 0 0';
		view_camera_free_angles = '0 0 0';
		view_camera_direction = '0 0 0';
		view_camera_free_offset_z += 30;
		view_camera_free_offset_x += 30 * -cos(view_camera_free_angles_y * MATH_DEG2RAD);
		view_camera_free_offset_y += 30 * -sin(view_camera_free_angles_y * MATH_DEG2RAD);
		view_camera_free_origin = view_origin;
		view_camera_free_offset  = view_camera_free_offset;
		cvar_set("camera_reset", "0");
		view_camera_mode = CAMERA_CHASE;
	}
	// Camera angles
	if (view_camera_roll)
		view_camera_mouse_angles_z += view_camera_roll * cvar("camera_speed_roll");

	if (cvar("camera_look_player")) {
		vector dir;
		float n;
		dir = normalize(view_origin - view_camera_free_position);
		n = view_camera_mouse_angles_z;
		view_camera_mouse_angles = vectoangles(dir);
		view_camera_mouse_angles_x = view_camera_mouse_angles_x * -1;
		view_camera_mouse_angles_z = n;
	} else {
		tmp = getmousepos() * 0.1;
		if (vlen(tmp)>cvar("camera_mouse_treshold"))
		{
			view_camera_mouse_angles_x += tmp_y * cos(view_camera_mouse_angles_z * MATH_DEG2RAD) + (tmp_x * sin(view_camera_mouse_angles_z * MATH_DEG2RAD));
			view_camera_mouse_angles_y -= tmp_x * cos(view_camera_mouse_angles_z * MATH_DEG2RAD) + (tmp_y * -sin(view_camera_mouse_angles_z * MATH_DEG2RAD));
		}
	}
	while (view_camera_mouse_angles_x < -180) view_camera_mouse_angles_x = view_camera_mouse_angles_x + 360;
	while (view_camera_mouse_angles_x > 180) view_camera_mouse_angles_x = view_camera_mouse_angles_x - 360;
	while (view_camera_mouse_angles_y < -180) view_camera_mouse_angles_y = view_camera_mouse_angles_y + 360;
	while (view_camera_mouse_angles_y > 180) view_camera_mouse_angles_y = view_camera_mouse_angles_y - 360;
	// Fix difference when angles don't have the same sign
	delta = '0 0 0';
	if (view_camera_mouse_angles_y < -60 && view_camera_free_angles_y > 60)
		delta = '0 360 0';
	if (view_camera_mouse_angles_y > 60 && view_camera_free_angles_y < -60)
		delta = '0 -360 0';

	if (cvar("camera_look_player"))
		attenuation = cvar("camera_look_attenuation");
	else
		attenuation = cvar("camera_speed_attenuation");

	attenuation = 1 / max(1, attenuation);
	view_camera_free_angles += (view_camera_mouse_angles - view_camera_free_angles + delta) * attenuation;
	while (view_camera_free_angles_x < -180) view_camera_free_angles_x = view_camera_free_angles_x + 360;
	while (view_camera_free_angles_x > 180) view_camera_free_angles_x = view_camera_free_angles_x - 360;
	while (view_camera_free_angles_y < -180) view_camera_free_angles_y = view_camera_free_angles_y + 360;
	while (view_camera_free_angles_y > 180) view_camera_free_angles_y = view_camera_free_angles_y - 360;
	// Camera position
	tmp = '0 0 0';
	dimensions = 0;
	if (view_camera_direction_x) {
		tmp_x = view_camera_direction_x * cos(view_camera_free_angles_y * MATH_DEG2RAD);
		tmp_y = view_camera_direction_x * sin(view_camera_free_angles_y * MATH_DEG2RAD);
		if (cvar("camera_forward_follows") && !cvar("camera_look_player"))
			tmp_z = view_camera_direction_x * -sin(view_camera_free_angles_x * MATH_DEG2RAD);

		++dimensions;
	}
	if (view_camera_direction_y) {
		tmp_x += view_camera_direction_y * -sin(view_camera_free_angles_y * MATH_DEG2RAD);
		tmp_y += view_camera_direction_y * cos(view_camera_free_angles_y * MATH_DEG2RAD) * cos(view_camera_free_angles_z * MATH_DEG2RAD);
		tmp_z += view_camera_direction_y * sin(view_camera_free_angles_z * MATH_DEG2RAD);
		++dimensions;
	}
	if (view_camera_direction_z) {
		tmp_z += view_camera_direction_z * cos(view_camera_free_angles_z * MATH_DEG2RAD);
		++dimensions;
	}
	if (cvar("camera_free"))
		speed = cvar("camera_speed_free");
	else
		speed = cvar("camera_speed_chase");

	if (dimensions) {
		speed = speed * sqrt(1 / dimensions);
		view_camera_free_offset += tmp * speed;
	}
	//view_camera_free_offset += (view_camera_free_offset - view_camera_free_offset) * attenuation;
	// Camera modes
	if (cvar("camera_free")) {
		if (view_camera_mode == CAMERA_CHASE) {
			view_camera_free_offset = view_camera_free_origin + view_camera_free_offset;
			view_camera_free_offset = view_camera_free_origin + view_camera_free_offset;
		}
		view_camera_mode = CAMERA_FREE;
		view_camera_free_position = view_camera_free_offset;
	} else {
		if (view_camera_mode == CAMERA_FREE) {
			view_camera_free_origin = view_origin;
			view_camera_free_offset = view_camera_free_offset - view_camera_free_origin;
			view_camera_free_offset = view_camera_free_offset - view_camera_free_origin;
		}
		view_camera_mode = CAMERA_CHASE;
		if (cvar("camera_chase_smoothly"))
			view_camera_free_origin += (view_origin - view_camera_free_origin) * attenuation;
		else
			view_camera_free_origin = view_origin;

		view_camera_free_position = view_camera_free_origin + view_camera_free_offset;
	}
	R_SetView(VF_ANGLES, view_camera_free_angles);
	R_SetView(VF_ORIGIN, view_camera_free_position);
}

vector(vector vec) view_project_3d_to_2d {
	vec = cs_project(vec);
	if (view_project_is_broken > 0) {
		vec_x *= CVAR(vid_conwidth) / view_width;
		vec_y *= CVAR(vid_conheight) / view_height;
	}
	return vec;
}

