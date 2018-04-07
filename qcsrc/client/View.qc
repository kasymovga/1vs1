#define spider_rocket_icon "gfx/spiderbot/rocket_ico.tga"
#define spider_rocket_targ "gfx/spiderbot/target.tga"
#define SPIDER_CROSS "textures/spiderbot/cross.tga"
#define rkt_size 32
#define rld_size_x 256
#define rld_size_y 16

//float trace_dphitcontents;
float trace_networkentity;
//float Q3SURFACEFLAG_SLICK = 2; // low friction surface
float DPCONTENTS_SOLID = 1; // blocks player movement
float DPCONTENTS_BODY = 32; // blocks player movement
float DPCONTENTS_CORPSE = 64; // blocks player movement
float DPCONTENTS_PLAYERCLIP = 256; // blocks player movement
float drawtime;

#if 0
float tan(float x)
{
	return sin(x) / cos(x);
}
float atan2(float y, float x)
{
	vector v;
	v = '1 0 0' * x + '0 1 0' * y;
	v = vectoangles(v);
	return v_y * 0.01745329251994329576;
}
#endif

float fovx, fovy;
float old_vid_width, old_vid_height, old_viewzoom, old_fov, old_vid_pixelheight;
vector GetCurrentFov()
{
	float zoomdir, zoomfactor, zoomspeed;

	zoomfactor = CVAR(cl_zoomfactor);
	if(zoomfactor < 1 || zoomfactor > 16)
		zoomfactor = 2.5;
	zoomspeed = CVAR(cl_zoomspeed);
	if(zoomspeed >= 0)
		if(zoomspeed < 0.5 || zoomspeed > 16)
			zoomspeed = 3.5;

	zoomdir = button_zoom;
	if(getstati(STAT_ACTIVEWEAPON) == WEP_NEX) // do NOT use switchweapon here
		zoomdir += button_attack2;
	if(spectatee_status > 0 || isdemo_flag)
	{
		if(spectatorbutton_zoom)
			zoomdir = 0 + !zoomdir;
			// do not even THINK about removing this 0
			// _I_ know what I am doing
			// fteqcc does not
	}

	if(zoomdir)
		zoomin_effect = 0;

	if(zoomin_effect || camera_active)
	{
		current_viewzoom = min(1, current_viewzoom + drawframetime);
	}
	else
	{
		if(zoomspeed < 0) // instant zoom
		{
			if(zoomdir)
				current_viewzoom = 1 / zoomfactor;
			else
				current_viewzoom = 1;
		}
		else
		{
			if(zoomdir)
				current_viewzoom = 1 / bound(1, 1 / current_viewzoom + drawframetime * zoomspeed * (zoomfactor - 1), zoomfactor);
			else
				current_viewzoom = bound(1 / zoomfactor, current_viewzoom + drawframetime * zoomspeed * (1 - 1 / zoomfactor), 1);
		}
	}

	if(almost_equals(current_viewzoom, 1))
		current_zoomfraction = 0;
	else if(almost_equals(current_viewzoom, 1/zoomfactor))
		current_zoomfraction = 1;
	else
		current_zoomfraction = (current_viewzoom - 1) / (1/zoomfactor - 1);

	if(CVAR(cl_zoomsensitivity) < 1)
		setsensitivityscale(pow(current_viewzoom, 1 - CVAR(cl_zoomsensitivity)));
	else
		setsensitivityscale(1);

	if (old_viewzoom == current_viewzoom)
	if (old_fov == fov)
	if (old_vid_width == vid_width)
	if (old_vid_height == vid_height)
	if (old_vid_pixelheight == CVAR(vid_pixelheight))
		goto skip;

	old_viewzoom = current_viewzoom;
	old_vid_width = vid_width;
	old_vid_height = vid_height;
	old_fov = fov;
	old_vid_pixelheight = CVAR(vid_pixelheight);
	float frustumx, frustumy;
	fov_zoomed = fov * current_viewzoom;
	frustumy = tan(fov * 0.00872664625997164788) * 0.75 * current_viewzoom;
	frustumx = frustumy * vid_width / vid_height / CVAR(vid_pixelheight);
	fovx = atan2(frustumx, 1) / 0.00872664625997164788;
	fovy = atan2(frustumy, 1) / 0.00872664625997164788;
:skip
	return '1 0 0' * fovx + '0 1 0' * fovy;
}

// this function must match W_SetupShot!
float zoomscript_caught;

vector wcross_origin;

float vshield;
void DrawTintEffects(void) {
    float st = getstati(STAT_STEALTH);
    float s = st || getstatf(STAT_HGSHIELD);
    //float twarp = getstatf(STAT_HGTWARP_WARPTIME);
    vector fullscreen;
	fullscreen_x = CVAR(vid_conwidth);
	fullscreen_y = CVAR(vid_conheight);
	fullscreen_z = 0;

    if(s)
        vshield = approach(vshield, 1, frametime * 3);
    else
        vshield = approach(vshield, 0, frametime * 3);

    if(vshield) {
        if(st) {
            drawfill('0 0 0', fullscreen, '1 1 1', 0.1 * vshield, DRAWFLAG_MODULATE);
        } else {
#if 0
            var clr = if(getstati(STAT_BUFFS) & BUFF_ADEPT)
                '1 0.5 1'
            else
                '1 1 0.5';
#endif
			vector clr = '1 1 0.5';

            drawfill('0 0 0', fullscreen, clr * vshield + '1 1 1' * (1 - vshield), 1, DRAWFLAG_MODULATE);
            drawfill('0 0 0', fullscreen, clr, 0.1 * vshield, DRAWFLAG_ADDITIVE);
        }

    }

#if 0
    if(twarp) {
        const twarp_dur = 3;
        twarp = 1 - bound(0, (servertime - twarp) / twarp_dur, 1);

        if(twarp) {
            twarp = ipol_pow2In(twarp);
            drawfill('0 0 0', fullscreen, '0.85 0.9 1', 0.25 * twarp, DRAWFLAG_ADDITIVE);
        }
    }
#endif
}

void CSQC_kh_hud(void);
void CSQC_ctf_hud(void);
void PostInit(void);
void CSQC_Demo_Camera();
float Sbar_WouldDrawScoreboard ();
float view_set;
float camera_mode;
void CSQC_spider_HUD();
void CSQC_UpdateView(float w, float h)
{
	entity e;
	read_cvars();

	dprint_load();
	WaypointSprite_Load();

	if(spectatee_status)
		myteam = GetPlayerColor(spectatee_status - 1);
	else
		myteam = GetPlayerColor(player_localentnum - 1);

	ticrate = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);

	// Render the Scene
	vid_width = w;
	vid_height = h;

#ifdef BLURTEST
	if(time > blurtest_time0 && time < blurtest_time1)
	{
		float r, t;

		t = (time - blurtest_time0) / (blurtest_time1 - blurtest_time0);
		r = t * blurtest_radius;
		f = 1 / pow(t, blurtest_power) - 1;

		cvar_set("r_glsl_postprocess", "1");
		cvar_set("r_glsl_postprocess_uservec1", strcat(ftos(r), " ", ftos(f), " 0 0"));
	}
	else
	{
		cvar_set("r_glsl_postprocess", "0");
		cvar_set("r_glsl_postprocess_uservec1", "0 0 0 0");
	}
#endif

	Fog_Force();

	drawframetime = max(0.000001, time - drawtime);
	drawtime = time;

	// watch for gametype changes here...
	// in ParseStuffCMD the cmd isn't executed yet :/
	// might even be better to add the gametype to TE_CSQC_INIT...?
	if(!postinit)
		PostInit();

	if(intermission && !isdemo_flag && !(calledhooks & HOOK_END))
	if(calledhooks & HOOK_START)
	{
		localcmd("\ncl_hook_gameend;");
		calledhooks |= HOOK_END;
	}

	fov = cvar("fov");
	if(button_zoom || fov <= 59.5)
	{
		if(!zoomscript_caught)
		{
			localcmd("+button4\n");
			zoomscript_caught = 1;
			ignore_plus_zoom += 1;
		}
	}
	else
	{
		if(zoomscript_caught)
		{
			localcmd("-button4\n");
			zoomscript_caught = 0;
			ignore_minus_zoom += 1;
		}
	}

	sbar_alpha_fg = CVAR(sbar_alpha_fg) * (1 - CVAR(_menu_alpha));
	ColorTranslateMode = CVAR(cl_stripcolorcodes);
	activeweapon = getstati(STAT_SWITCHWEAPON);

	// ALWAYS Clear Current Scene First
	R_ClearScene();

	// Assign Standard Viewflags
	// Draw the World (and sky)
	R_SetView(VF_DRAWWORLD, 1);

	if(!intermission || !view_set)
	{
		view_angles = input_angles;
		makevectors(view_angles);
		view_forward = v_forward;
		view_right = v_right;
		view_up = v_up;
		view_set = 1;
		view_origin = CSQCPhysic_SetCamera();
	}
	WarpZone_FixView();

	// Set the console size vars

	R_SetView(VF_FOV, GetCurrentFov());

	// Camera for demo playback
	if(camera_active)
	{
		if(CVAR(camera_enable))
			CSQC_Demo_Camera();
		else
		{
			cvar_set("chase_active", ftos(chase_active_backup));
			cvar_set("cl_demo_mousegrab", "0");
			camera_active = FALSE;
		}
	}
#ifdef CAMERATEST
	else if(CVAR(camera_enable))
#else
	else if(CVAR(camera_enable) && isdemo_flag)
#endif
	{
		// Enable required Darkplaces cvars
		chase_active_backup = cvar("chase_active");
		cvar_set("chase_active", "2");
		cvar_set("cl_demo_mousegrab", "1");
		camera_active = TRUE;
		camera_mode = FALSE;
	}

	sb_hidescores = FALSE;
	if (Sbar_WouldDrawScoreboard())
		draw_crosshair = FALSE;
	else
		draw_crosshair = TRUE;

	R_SetView(VF_DRAWCROSSHAIR, 0); //Make sure engine crosshairs are always hidden

	// Draw the Engine Status Bar (the default Quake HUD)
	R_SetView(VF_DRAWENGINESBAR, 0);

	// Update the mouse position
	/*
	mousepos_x = vid_conwidth;
	mousepos_y = vid_conheight;
	mousepos = mousepos*0.5 + getmousepos();
	*/

	e = self;
	for(self = world; (self = nextent(self)); )
		if(self.draw)
			self.draw();
	self = e;

	R_AddEntities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	R_RenderScene();

	// now switch to 2D drawing mode by calling a 2D drawing function
	// then polygon drawing will draw as 2D stuff, and NOT get queued until the
	// next R_RenderScene call
	drawstring('0 0 0', "", '1 1 0', '1 1 1', 0, 0);

	DrawTintEffects();

	// draw 2D entities
	e = self;
	for(self = findchainfloat(draw2dflag, 1); self; self = self.chain)
		self.draw2d();

	self = e;

	// draw radar
	if(ons_showmap)
		teamradar_view(TRUE, "");

	if (CVAR(cl_showpressedkeys)) { // draw pressed keys when spectating and playing
		if(spectatee_status > 0 || CVAR(cl_showpressedkeys) >= 2)
			Sbar_DrawPressedKeys();
	}

	if (CVAR(cl_showspeed))
		Sbar_ShowSpeed();

	if (CVAR(cl_showacceleration))
		Sbar_ShowAcceleration();

	Sbar_DrawCenterPrint(); // draw centerprint messages even if viewsize >= 120

    float hud;
    hud = getstati(STAT_HUD);
    if(hud == HUD_SPIDERBOT)
    {
        vector sz;
        CSQC_spider_HUD();
        sz = drawgetimagesize(SPIDER_CROSS);
        sz_x *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
        sz_y *= CVAR_OR(cl_vehicle_spiderbot_cross_size,1);
        drawpic('0.5 0 0' * (CVAR(vid_conwidth) - sz_x) + '0 0.5 0' * (CVAR(vid_conheight) - sz_y), SPIDER_CROSS, sz, '1 1 1', CVAR_OR(cl_vehicle_spiderbot_cross_alpha,0.6), DRAWFLAG_NORMAL);
    }
    else
    {
		if(CVAR(viewsize) < 120)
			Sbar_Draw();

        // crosshair goes VERY LAST
        if (draw_crosshair) {
			float bullets, ring_scale;
			// wcross_origin = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
			wcross_origin = project_3d_to_2d(view_origin + MAX_SHOT_DISTANCE * view_forward);
			wcross_origin_z = 0;
            string wcross_style;
            wcross_style = cvar_string("crosshair");
            if (wcross_style != "0") {
                vector wcross_color, wcross_size;
                string wcross_wep, wcross_name;
                float wcross_alpha, wcross_sizefloat;

                wcross_color_x = CVAR(crosshair_color_red);
                wcross_color_y = CVAR(crosshair_color_green);
                wcross_color_z = CVAR(crosshair_color_blue);
                wcross_alpha = CVAR(crosshair_color_alpha) * (1-CVAR(_menu_alpha));
                wcross_sizefloat = CVAR(crosshair_size) * (1-CVAR(_menu_alpha));
                if (CVAR(crosshair_per_weapon)) {
                    e = get_weaponinfo(activeweapon);
                    if (e && e.netname != "")
                    {
                        wcross_wep = e.netname;
                        wcross_style = cvar_string(strcat("crosshair_", wcross_wep));
                        if(wcross_style == "")
                            wcross_style = e.netname;

                        if(!CVAR(crosshair_color_override))
                        {
                            wcross_color_x = cvar(strcat("crosshair_", wcross_wep, "_color_red"));
                            wcross_color_y = cvar(strcat("crosshair_", wcross_wep, "_color_green"));
                            wcross_color_z = cvar(strcat("crosshair_", wcross_wep, "_color_blue"));
                        }

                        wcross_alpha *= cvar(strcat("crosshair_", wcross_wep, "_color_alpha"));
                        wcross_sizefloat *= cvar(strcat("crosshair_", wcross_wep, "_size"));
                    }
                }

                wcross_name = strcat("gfx/crosshair", wcross_style);

                wcross_size = drawgetimagesize(wcross_name);
                wcross_size_x *= wcross_sizefloat;
                wcross_size_y *= wcross_sizefloat;
				
				// ring around crosshair representing bullets left in camping rifle clip
				if (activeweapon == WEP_CAMPINGRIFLE)
				{
					ring_scale = CVAR(crosshair_campingrifle_ring_size);
					bullets = bound(0, getstati(STAT_BULLETS_LOADED), 8);
				}
				else
					bullets = 0;
				
				if (bullets)
					drawpic(wcross_origin - '0.5 0 0' * (wcross_size_x * ring_scale) - '0 0.5 0' * (wcross_size_y * ring_scale), strcat("gfx/hud/rifle_ring_", ftos(bullets)), wcross_size * ring_scale, wcross_color, wcross_alpha, DRAWFLAG_NORMAL);

				drawpic(wcross_origin - '0.5 0 0' * (wcross_size_x) - '0 0.5 0' * ( wcross_size_y), wcross_name, wcross_size, wcross_color, wcross_alpha, DRAWFLAG_NORMAL);
				if (CVAR(crosshair_dot))
				{
					vector dot_color = wcross_color;
					if(CVAR(crosshair_dot_color_custom))
					{
						string dot_color_string = cvar_string("crosshair_dot_color");
						if (dot_color_string != "0")
							dot_color = stov(dot_color_string);
					}
					drawpic(wcross_origin - '0.5 0 0' * (wcross_size_x * CVAR(crosshair_dot_size)) - '0 0.5 0' * (wcross_size_y * CVAR(crosshair_dot_size)), crosshairdot_tex, wcross_size * CVAR(crosshair_dot_size), dot_color, wcross_alpha * CVAR(crosshair_dot_alpha), DRAWFLAG_NORMAL);
				}
            }
        }
    }
	if (Draw2d_Post) {
		e = self;
		self = Draw2d_Post_self;
		Draw2d_Post();
		Draw2d_Post = NULL;
		Draw2d_Post_self = NULL;
		self = e;
	}

	Mouse_Draw();

	// we must do this check AFTER a frame was rendered, or it won't work
	if(cs_project_is_b0rked == 0)
	{
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
		if(v1 == v2)
			cs_project_is_b0rked = 1;
		else
			cs_project_is_b0rked = -1;
		cvar_set("vid_conwidth", w0);
		cvar_set("vid_conheight", h0);
	}

	// be safe against triggerbots until everyone has the fixed engine
	// this call is meant to overwrite the trace globals by something
	// unsuspicious
	traceline('0 0 0', '0 0 0', MOVE_WORLDONLY, world);
}

void Sbar_Draw();
void CSQC_spider_HUD()
{
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
    drawfill(p, '256 0 0' * shield + '0 8 0' , '0.5 0.5 1', 0.75, DRAWFLAG_NORMAL);
    p_y += 8;
    drawfill(p, '256 0 0' * hp + '0 8 0' , '0 1 0', 0.75, DRAWFLAG_NORMAL);
    p_x += 256 * hp;
    drawfill(p, '256 0 0' * (1-hp) + '0 8 0' , '0 0 0', 0.75, DRAWFLAG_NORMAL);

    // Draw minigun heat indicator
    p = '0.5 0 0' * (CVAR(vid_conwidth) - 256);
    p = p + '0 1 0' * CVAR(vid_conheight) - '0 74  0';
    drawfill(p, '256 0 0' * (1-heat) + '0 2 0' ,'0 0 1', 0.5, DRAWFLAG_NORMAL);
    p_x += 256 * (1-heat);
    drawfill(p, '256 0 0' * heat  + '0 2 0' , '1 0 0', 0.5, DRAWFLAG_NORMAL);

    // Draw rocket icons for loaded/empty tubes.
    pp = '0.5 0 0' * (CVAR(vid_conwidth) - (rkt_size * 8));
    pp += '0 1 0' * CVAR(vid_conheight) - '0 104 0';
    for(i = 0; i < 8; ++i)
    {
        p = pp + '1 0 0' * (rkt_size * i);
        if(rockets == 8)
        {
            if(floor(reload * 8) == i)
            {
                drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 0 0' + '0 1 0' * ((reload*8)-i), 0.75 , DRAWFLAG_NORMAL);
            }
            else if(i < reload * 8)
                drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 1 0', 0.75 , DRAWFLAG_NORMAL);
            else
                drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0.5 0.5 0.5', 0.75, DRAWFLAG_NORMAL);
        }
        else
        {
            if(i < rockets)
                drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 0 0', 0.25, DRAWFLAG_NORMAL);
            else
                drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 1 0' * reload, 0.75, DRAWFLAG_NORMAL);
        }
    }
}

// following vectors must be global to allow seamless switching between camera modes
vector camera_offset, current_camera_offset, mouse_angles, current_angles, current_origin, current_position;
void CSQC_Demo_Camera()
{
	float speed, attenuation, dimensions;
	vector tmp, delta;

	if( cvar("camera_reset") || !camera_mode )
	{
		camera_offset = '0 0 0';
		current_angles = '0 0 0';
		camera_direction = '0 0 0';
		camera_offset_z += 30;
		camera_offset_x += 30 * -cos(current_angles_y * DEG2RAD);
		camera_offset_y += 30 * -sin(current_angles_y * DEG2RAD);
		current_origin = view_origin;
		current_camera_offset  = camera_offset;
		cvar_set("camera_reset", "0");
		camera_mode = CAMERA_CHASE;
	}

	// Camera angles
	if( camera_roll )
		mouse_angles_z += camera_roll * cvar("camera_speed_roll");

	if(cvar("camera_look_player"))
	{
		local vector dir;
		local float n;

		dir = normalize(view_origin - current_position);
		n = mouse_angles_z;
		mouse_angles = vectoangles(dir);
		mouse_angles_x = mouse_angles_x * -1;
		mouse_angles_z = n;
	}
	else
	{
		tmp = getmousepos() * 0.1;
		if(vlen(tmp)>cvar("camera_mouse_treshold"))
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
	if(mouse_angles_y < -60 && current_angles_y > 60)
		delta = '0 360 0';
	if(mouse_angles_y > 60 && current_angles_y < -60)
		delta = '0 -360 0';

	if(cvar("camera_look_player"))
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

	if( camera_direction_x )
	{
		tmp_x = camera_direction_x * cos(current_angles_y * DEG2RAD);
		tmp_y = camera_direction_x * sin(current_angles_y * DEG2RAD);
		if( cvar("camera_forward_follows") && !cvar("camera_look_player") )
			tmp_z = camera_direction_x * -sin(current_angles_x * DEG2RAD);
		++dimensions;
	}

	if( camera_direction_y )
	{
		tmp_x += camera_direction_y * -sin(current_angles_y * DEG2RAD);
		tmp_y += camera_direction_y * cos(current_angles_y * DEG2RAD) * cos(current_angles_z * DEG2RAD);
		tmp_z += camera_direction_y * sin(current_angles_z * DEG2RAD);
		++dimensions;
	}

	if( camera_direction_z )
	{
		tmp_z += camera_direction_z * cos(current_angles_z * DEG2RAD);
		++dimensions;
	}

	if(cvar("camera_free"))
		speed = cvar("camera_speed_free");
	else
		speed = cvar("camera_speed_chase");

	if(dimensions)
	{
		speed = speed * sqrt(1 / dimensions);
		camera_offset += tmp * speed;
	}

	current_camera_offset += (camera_offset - current_camera_offset) * attenuation;

	// Camera modes
	if( cvar("camera_free") )
	{
		if ( camera_mode == CAMERA_CHASE )
		{
			current_camera_offset = current_origin + current_camera_offset;
			camera_offset = current_origin + camera_offset;
		}

		camera_mode = CAMERA_FREE;
		current_position = current_camera_offset;
	}
	else
	{
		if ( camera_mode == CAMERA_FREE )
		{
			current_origin = view_origin;
			camera_offset = camera_offset - current_origin;
			current_camera_offset = current_camera_offset - current_origin;
		}

		camera_mode = CAMERA_CHASE;

		if(cvar("camera_chase_smoothly"))
			current_origin += (view_origin - current_origin) * attenuation;
		else
			current_origin = view_origin;

		current_position = current_origin + current_camera_offset;
	}

	R_SetView(VF_ANGLES, current_angles);
	R_SetView(VF_ORIGIN, current_position);
}
