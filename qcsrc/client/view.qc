#define spider_rocket_icon "gfx/spiderbot/rocket_ico"
#define spider_rocket_targ "gfx/spiderbot/target"
#define SPIDER_CROSS "textures/spiderbot/cross"
#define rkt_size 32

float view_drawtime;
float view_project_is_broken;
float view_old_vid_width, view_old_vid_height, view_old_zoom, view_old_fov, view_old_vid_pixelheight;
float view_fovx, view_fovy; //must be global because of goto skip
float view_zoomscript_caught;
float view_camera_mode;

void(void) view_camera_setup;
void(void) view_spider_hud;

vector(void) view_fov_calculate {
	float zoomdir, zoomfactor, zoomspeed;
	zoomfactor = CVAR(cl_zoomfactor);
	if (zoomfactor < 1 || zoomfactor > 16)
		zoomfactor = 2.5;

	zoomspeed = CVAR(cl_zoomspeed);
	if (zoomspeed >= 0)
		if (zoomspeed < 0.5 || zoomspeed > 16)
			zoomspeed = 3.5;

	zoomdir = any_button_zoom;
	if (spectatee_status > 0 || isdemo_flag)
	if (spectatorbutton_zoom)
		zoomdir = (zoomdir ? 0 : 1);

	if (camera_active) {
		current_viewzoom = min(1, current_viewzoom + drawframetime);
	} else {
		if (zoomspeed < 0) { // instant zoom
			if (zoomdir)
				current_viewzoom = 1 / zoomfactor;
			else
				current_viewzoom = 1;
		} else {
			if (zoomdir)
				current_viewzoom = 1 / bound(1, 1 / current_viewzoom + drawframetime * zoomspeed * (zoomfactor - 1), zoomfactor);
			else
				current_viewzoom = bound(1 / zoomfactor, current_viewzoom + drawframetime * zoomspeed * (1 - 1 / zoomfactor), 1);
		}
	}
	if (math_almost_equals(current_viewzoom, 1))
		current_zoomfraction = 0;
	else if (math_almost_equals(current_viewzoom, 1/zoomfactor))
		current_zoomfraction = 1;
	else
		current_zoomfraction = (current_viewzoom - 1) / (1/zoomfactor - 1);

	if (CVAR(cl_zoomsensitivity) < 1)
		setsensitivityscale(pow(current_viewzoom, 1 - CVAR(cl_zoomsensitivity)));
	else
		setsensitivityscale(1);

	if (view_old_zoom == current_viewzoom)
	if (view_old_fov == view_fov)
	if (view_old_vid_width == vid_width)
	if (view_old_vid_height == vid_height)
	if (view_old_vid_pixelheight == CVAR(vid_pixelheight))
		goto skip;

	view_old_zoom = current_viewzoom;
	view_old_vid_width = vid_width;
	view_old_vid_height = vid_height;
	view_old_fov = view_fov;
	view_old_vid_pixelheight = CVAR(vid_pixelheight);
	float frustumx, frustumy;
	view_fov_zoomed = view_fov * current_viewzoom;
	frustumy = tan(view_fov * 0.00872664625997164788) * 0.75 * current_viewzoom;
	frustumx = frustumy * vid_width / vid_height / CVAR(vid_pixelheight);
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

void(float w, float h) CSQC_UpdateView { //called by engine
	entity e;
	read_cvars();
	spectatee_status = getstati(STAT_SPECSTATUS);
	player_deadflag = getstati(STAT_PLAYER_STATE);
	spectatorbutton_zoom = spectatee_status & 256;
	spectatee_status = spectatee_status & 255;
	observer_status = (spectatee_status ? (spectatee_status == player_localentnum) : 0);
	if (spectatee_status)
		team_my = player_color(spectatee_status - 1);
	else
		team_my = player_color(player_localentnum - 1);

	ticrate = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
	// Render the Scene
	vid_width = w;
	vid_height = h;
	fog_force();
	drawframetime = max(0.000001, time - view_drawtime);
	view_drawtime = time;
	view_fov = cvar("fov");
	any_button_zoom = button_zoom;
	if (button_attack2_allowed) {
		if (getstati(STAT_ACTIVEWEAPON) == WEP_NEX)
		if not(CVAR(cl_nex_secondary_zoom_disable))
			any_button_zoom += button_attack2;
	}
	if (any_button_zoom || view_fov <= 59.5) {
		if not(view_zoomscript_caught)
		if not(button_zoom) {
			localcmd("+button4\n");
			view_zoomscript_caught = 1;
			ignore_plus_zoom += 1;
		}
	} else {
		if (view_zoomscript_caught) {
			localcmd("-button4\n");
			view_zoomscript_caught = 0;
			ignore_minus_zoom += 1;
		}
	}
	sbar_alpha_fg = CVAR(sbar_alpha_fg) * (1 - CVAR(_menu_alpha));
	weapon_current = getstati(STAT_SWITCHWEAPON);
	// ALWAYS Clear Current Scene First
	R_ClearScene();
	// Assign Standard Viewflags
	// Draw the World (and sky)
	R_SetView(VF_DRAWWORLD, 1);
	view_angles = input_angles;
	view_origin = physics_view_origin();
	warpzone_view_fix();
	physics_camera_setup();
	makevectors(view_angles);
	view_forward = v_forward;
	view_right = v_right;
	view_up = v_up;
	// Set the console size vars
	R_SetView(VF_FOV, view_fov_calculate());
	// Camera for demo playback
	if (camera_active) {
		if (CVAR(camera_enable))
			view_camera_setup();
		else {
			cvar_set("chase_active", ftos(chase_active_backup));
			cvar_set("cl_demo_mousegrab", "0");
			camera_active = FALSE;
		}
	} else if (CVAR(camera_enable)
#ifndef CAMERATEST
			&& isdemo_flag
#endif
			) {
		// Enable required Darkplaces cvars
		chase_active_backup = cvar("chase_active");
		cvar_set("chase_active", "2");
		cvar_set("cl_demo_mousegrab", "1");
		camera_active = TRUE;
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
	for (self = findchainfloat(draw2dflag, 1); self; self = self.chain)
		self.draw2d();

	self = e;
	// draw radar
	if (ons_showmap)
		teamradar_view(TRUE, "");

	if not(sbar_showscores) {
		if (CVAR(cl_showpressedkeys)) { // draw pressed keys when spectating and playing
			if ((spectatee_status > 0 && !observer_status) || CVAR(cl_showpressedkeys) >= 2)
				Sbar_DrawPressedKeys();
		}
		if (CVAR(cl_showspeed))
			Sbar_ShowSpeed();

		if (CVAR(cl_showacceleration))
			Sbar_ShowAcceleration();
	}
	centerprint_draw(); // draw centerprint messages even if viewsize >= 120
	if (observer_status)
		view_crosshair = FALSE;
	else if (sbar_hidescores)
		view_crosshair = FALSE;
	else
		view_crosshair = TRUE;

	float hud;
	hud = getstati(STAT_HUD);
	if (hud == HUD_SPIDERBOT) {
		vector sz;
		view_spider_hud();
		if (view_crosshair) {
			sz = drawgetimagesize(SPIDER_CROSS);
			sz_x *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
			sz_y *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
			weapon_cross_origin_set();
			drawpic(weapon_cross_origin - 0.5 * sz, SPIDER_CROSS, sz, '1 1 1', CVAR_OR(cl_vehicle_spiderbot_cross_alpha,0.6), DRAWFLAG_NORMAL);
		}
	} else {
		if (CVAR(viewsize) < 120)
			Sbar_Draw();

		// crosshair goes VERY LAST
		if (view_crosshair) {
			weapon_cross_origin_set();
			string wcross_style;
			wcross_style = cvar_string("crosshair");
			if (wcross_style != "0") {
				vector wcross_color, wcross_size;
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
					if (crosshair_hittime >= time) {
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
					drawpic(weapon_cross_origin - '0.5 0 0' * (wcross_size_x * CVAR(crosshair_dot_size)) - '0 0.5 0' * (wcross_size_y * CVAR(crosshair_dot_size)), crosshairdot_tex, wcross_size * CVAR(crosshair_dot_size), dot_color, wcross_alpha * CVAR(crosshair_dot_alpha), DRAWFLAG_NORMAL);
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
	Mouse_Draw();
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
	traceline('0 0 0', '0 0 0', MOVE_WORLDONLY, world);
}

void(void) view_spider_hud {
    float rockets,reload,heat,hp,shield,i;
    vector p,pp;
	Sbar_Draw();
    rockets = getstati(STAT_SPIDERBOT_ROCKETS);
    heat    = min(getstatf(STAT_SPIDERBOT_HEAT),1);
    reload  = min(getstatf(STAT_SPIDERBOT_RELOAD),1);
    hp      = min(getstatf(STAT_SPIDERBOT_HEALTH),1);
    shield  = min(getstatf(STAT_SPIDERBOT_SHIELD),1);
    // Draw health bar
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
	}
}

// following vectors must be global to allow seamless switching between camera modes
vector camera_offset, current_camera_offset, mouse_angles, current_angles, current_origin, current_position;
void(void) view_camera_setup {
	float speed, attenuation, dimensions;
	vector tmp, delta;
	if (cvar("camera_reset") || !view_camera_mode) {
		camera_offset = '0 0 0';
		current_angles = '0 0 0';
		camera_direction = '0 0 0';
		camera_offset_z += 30;
		camera_offset_x += 30 * -cos(current_angles_y * DEG2RAD);
		camera_offset_y += 30 * -sin(current_angles_y * DEG2RAD);
		current_origin = view_origin;
		current_camera_offset  = camera_offset;
		cvar_set("camera_reset", "0");
		view_camera_mode = CAMERA_CHASE;
	}
	// Camera angles
	if (camera_roll)
		mouse_angles_z += camera_roll * cvar("camera_speed_roll");

	if (cvar("camera_look_player")) {
		local vector dir;
		local float n;
		dir = normalize(view_origin - current_position);
		n = mouse_angles_z;
		mouse_angles = vectoangles(dir);
		mouse_angles_x = mouse_angles_x * -1;
		mouse_angles_z = n;
	} else {
		tmp = getmousepos() * 0.1;
		if (vlen(tmp)>cvar("camera_mouse_treshold"))
		{
			mouse_angles_x += tmp_y * cos(mouse_angles_z * DEG2RAD) + (tmp_x * sin(mouse_angles_z * DEG2RAD));
			mouse_angles_y -= tmp_x * cos(mouse_angles_z * DEG2RAD) + (tmp_y * -sin(mouse_angles_z * DEG2RAD));
		}
	}
	while (mouse_angles_x < -180) mouse_angles_x = mouse_angles_x + 360;
	while (mouse_angles_x > 180) mouse_angles_x = mouse_angles_x - 360;
	while (mouse_angles_y < -180) mouse_angles_y = mouse_angles_y + 360;
	while (mouse_angles_y > 180) mouse_angles_y = mouse_angles_y - 360;
	// Fix difference when angles don't have the same sign
	delta = '0 0 0';
	if (mouse_angles_y < -60 && current_angles_y > 60)
		delta = '0 360 0';
	if (mouse_angles_y > 60 && current_angles_y < -60)
		delta = '0 -360 0';

	if (cvar("camera_look_player"))
		attenuation = cvar("camera_look_attenuation");
	else
		attenuation = cvar("camera_speed_attenuation");

	attenuation = 1 / max(1, attenuation);
	current_angles += (mouse_angles - current_angles + delta) * attenuation;
	while (current_angles_x < -180) current_angles_x = current_angles_x + 360;
	while (current_angles_x > 180) current_angles_x = current_angles_x - 360;
	while (current_angles_y < -180) current_angles_y = current_angles_y + 360;
	while (current_angles_y > 180) current_angles_y = current_angles_y - 360;
	// Camera position
	tmp = '0 0 0';
	dimensions = 0;
	if (camera_direction_x) {
		tmp_x = camera_direction_x * cos(current_angles_y * DEG2RAD);
		tmp_y = camera_direction_x * sin(current_angles_y * DEG2RAD);
		if (cvar("camera_forward_follows") && !cvar("camera_look_player"))
			tmp_z = camera_direction_x * -sin(current_angles_x * DEG2RAD);

		++dimensions;
	}
	if (camera_direction_y) {
		tmp_x += camera_direction_y * -sin(current_angles_y * DEG2RAD);
		tmp_y += camera_direction_y * cos(current_angles_y * DEG2RAD) * cos(current_angles_z * DEG2RAD);
		tmp_z += camera_direction_y * sin(current_angles_z * DEG2RAD);
		++dimensions;
	}
	if (camera_direction_z) {
		tmp_z += camera_direction_z * cos(current_angles_z * DEG2RAD);
		++dimensions;
	}
	if (cvar("camera_free"))
		speed = cvar("camera_speed_free");
	else
		speed = cvar("camera_speed_chase");

	if (dimensions) {
		speed = speed * sqrt(1 / dimensions);
		camera_offset += tmp * speed;
	}
	current_camera_offset += (camera_offset - current_camera_offset) * attenuation;
	// Camera modes
	if (cvar("camera_free")) {
		if (view_camera_mode == CAMERA_CHASE) {
			current_camera_offset = current_origin + current_camera_offset;
			camera_offset = current_origin + camera_offset;
		}
		view_camera_mode = CAMERA_FREE;
		current_position = current_camera_offset;
	} else {
		if (view_camera_mode == CAMERA_FREE) {
			current_origin = view_origin;
			camera_offset = camera_offset - current_origin;
			current_camera_offset = current_camera_offset - current_origin;
		}
		view_camera_mode = CAMERA_CHASE;
		if (cvar("camera_chase_smoothly"))
			current_origin += (view_origin - current_origin) * attenuation;
		else
			current_origin = view_origin;

		current_position = current_origin + current_camera_offset;
	}
	R_SetView(VF_ANGLES, current_angles);
	R_SetView(VF_ORIGIN, current_position);
}

vector(vector vec) view_project_3d_to_2d {
	vec = cs_project(vec);
	if (view_project_is_broken > 0) {
		vec_x *= CVAR(vid_conwidth) / vid_width;
		vec_y *= CVAR(vid_conheight) / vid_height;
	}
	return vec;
}

