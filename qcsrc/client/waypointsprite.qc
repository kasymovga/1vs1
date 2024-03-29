float waypointsprite_fadedistance;
float waypointsprite_edgefadealpha;
float waypointsprite_edgefadescale;
float waypointsprite_crosshairfadealpha;
float waypointsprite_crosshairfadescale;
float waypointsprite_distancefadealpha;
float waypointsprite_distancefadescale;
float waypointsprite_distancefadedistance;

.float rule;
.string netname; // primary picture
.string netname2; // secondary picture
.string netname3; // tertiary picture
.float team; // team that gets netname2
.float lifetime;
.float fadetime;
.float maxdistance;
.float hideflags;
.float spawntime;
.float build_started;
.float build_starthealth;
.float build_finished;

vector SPRITE_SIZE = '288 36 0';
vector SPRITE_HOTSPOT = '144 36 0';
float SPRITE_HEALTHBAR_WIDTH = 144;
float SPRITE_HEALTHBAR_HEIGHT = 9;
float SPRITE_HEALTHBAR_MARGIN = 6;
float SPRITE_HEALTHBAR_BORDER = 2;
float SPRITE_HEALTHBAR_BORDERALPHA = 1;
float SPRITE_HEALTHBAR_HEALTHALPHA = 0.5;

void(vector org, float rot, float h, vector sz, vector hotspot, float width, float height, float margin, float border, float align, vector rgb, float a, vector hrgb, float ha, float f) waypointsprite_healthbar_draw {
	vector o, ri, up;
	float owidth; // outer width
	hotspot = -1 * hotspot;
	// hotspot-relative coordinates of the healthbar corners
	o = hotspot;
	ri = '1 0 0';
	up = '0 1 0';
	rot = -rot; // rotate by the opposite angle, as our coordinate system is reversed
	o = math_rotate(o, rot) + org;
	ri = math_rotate(ri, rot);
	up = math_rotate(up, rot);
	owidth = width + 2 * border;
	o = o - up * (margin + border + height) + ri * (sz_x - owidth) * 0.5;
	draw_quad(o - up * border,                               ri * owidth,    up * border, "", rgb,  a,  f);
	draw_quad(o + up * height,                               ri * owidth,    up * border, "", rgb,  a,  f);
	draw_quad(o,                                             ri * border,    up * height, "", rgb,  a,  f);
	draw_quad(o + ri * (owidth - border),                    ri * border,    up * height, "", rgb,  a,  f);
	draw_quad(o + ri * (border + align * ((1 - h) * width)), ri * width * h, up * height, "", hrgb, ha, f);
}

void(void) waypointsprite_draw {
	string spriteimage;
	float t;
	if (self.lifetime)
		self.alpha = pow(bound(0, (self.fadetime - time) / self.lifetime, 1), CVAR(g_waypointsprite_timealphaexponent));
	else
		self.alpha = 1;

	if (self.hideflags & 2)
		return; // radar only

	if (CVAR(cl_hidewaypoints) >= 2)
		return;

	if (self.hideflags & 1)
		if (CVAR(cl_hidewaypoints))
			return; // fixed waypoint

	interpolate_do();
	t = player_color(player_localentnum - 1);
	spriteimage = "";
	// choose the sprite
	switch (self.rule) {
		case SPRITERULE_DEFAULT:
			if (self.team) {
				if (self.team == t)
					spriteimage = self.netname;
				else
					spriteimage = "";
			} else
				spriteimage = self.netname;

			break;
		case SPRITERULE_TEAMPLAY:
			if (t == TEAM_COLOR_SPECTATOR + 1)
				spriteimage = self.netname3;
			else if (self.team == t)
				spriteimage = self.netname2;
			else
				spriteimage = self.netname;

			break;
		default:
			error("Invalid waypointsprite rule!");
			break;
	}
	if (spriteimage == "")
		return;
	
	float dist;
	dist = vlen(self.origin - view_origin);
	float a;
	a = self.alpha * sbar_alpha_fg;
	if (self.maxdistance > CVAR(g_waypointsprite_normdistance))
		a *= pow(bound(0, (self.maxdistance - dist) / (self.maxdistance - CVAR(g_waypointsprite_normdistance)), 1), CVAR(g_waypointsprite_distancealphaexponent));
	else if (self.maxdistance > 0)
		a *= pow(bound(0, (waypointsprite_fadedistance - dist) / (waypointsprite_fadedistance - CVAR(g_waypointsprite_normdistance)), 1), CVAR(g_waypointsprite_distancealphaexponent)) * (1 - CVAR(g_waypointsprite_minalpha)) + CVAR(g_waypointsprite_minalpha);

	if (a <= 0)
		return;
	
	// draw the sprite image
	vector o;
	float rot;
	o = view_project_3d_to_2d(self.origin);
	rot = 0;
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight)) {
		// scale it to be just in view
		vector d;
		float f1, f2;
		// get the waypoint angle vector
		/*
		d_x = view_right * (self.origin - view_origin) * CVAR(vid_conwidth) / view_width;
		d_y = -view_up * (self.origin - view_origin) * CVAR(vid_conheight) / (view_height * vid_pixelheight);
		d_z = 0;
		*/
		d = o - '0.5 0 0' * CVAR(vid_conwidth) - '0 0.5 0' * CVAR(vid_conheight);
		/*
		if(v_flipped)
			d_x = -d_x;
		*/
		f1 = d_x / CVAR(vid_conwidth);
		f2 = d_y / CVAR(vid_conheight);
		if (max(f1, -f1) > max(f2, -f2)) {
			if (d_z * f1 > 0) {
				// RIGHT edge
				d = d * (0.5 / f1);
				rot = 3;
			} else {
				// LEFT edge
				d = d * (-0.5 / f1);
				rot = 1;
			}
		} else {
			if (d_z * f2 > 0) {
				// BOTTOM edge
				d = d * (0.5 / f2);
				rot = 0;
			} else {
				// TOP edge
				d = d * (-0.5 / f2);
				rot = 2;
			}
		}
		o = d + '0.5 0 0' * CVAR(vid_conwidth) + '0 0.5 0' * CVAR(vid_conheight);
	}
	o_z = 0;
	float vidscale;
	vidscale = max(CVAR(vid_conwidth) / view_width, CVAR(vid_conheight) / view_height);
	if (!self.cnt) {
		t = stof(db_get(db_temp, strcat("/spriteframes/", spriteimage)));
		self.cnt = t + 1;
	} else
		t = self.cnt - 1;

	if (t == 0)
		spriteimage = strcat("models/sprites/", spriteimage);
	else
		spriteimage = strcat("models/sprites/", spriteimage, "_frame", ftos(math_mod(floor((max(0, time - self.spawntime)) * 2), t)));

	float edgedistance_min, crosshairdistance;
	edgedistance_min = min4(o_y, o_x,CVAR(vid_conwidth) - o_x, CVAR(vid_conheight) - o_y);
	crosshairdistance = sqrt( pow(o_x - CVAR(vid_conwidth)/2, 2) + pow(o_y - CVAR(vid_conheight)/2, 2) );
	t = CVAR_OR(g_waypointsprite_scale, 1) * (1 - CVAR(_menu_alpha)) * vidscale;
	a = a * (1 - (1 - waypointsprite_distancefadealpha) * (bound(0, dist/waypointsprite_distancefadedistance, 1)));
	t = t * (1 - (1 - waypointsprite_distancefadescale) * (bound(0, dist/waypointsprite_distancefadedistance, 1)));
	if (edgedistance_min < CVAR(g_waypointsprite_edgefadedistance)) {
		a = a * (1 - (1 - waypointsprite_edgefadealpha) * (1 - bound(0, edgedistance_min/CVAR(g_waypointsprite_edgefadedistance), 1)));
		t = t * (1 - (1 - waypointsprite_edgefadescale) * (1 - bound(0, edgedistance_min/CVAR(g_waypointsprite_edgefadedistance), 1)));
	}
	if (crosshairdistance < CVAR(g_waypointsprite_crosshairfadedistance)) {
		a = a * (1 - (1 - waypointsprite_crosshairfadealpha) * (1 - bound(0, crosshairdistance/CVAR(g_waypointsprite_crosshairfadedistance), 1)));
		t = t * (1 - (1 - waypointsprite_crosshairfadescale) * (1 - bound(0, crosshairdistance/CVAR(g_waypointsprite_crosshairfadedistance), 1)));
	}
	draw_picture_rotate(o, rot * 90 * MATH_DEG2RAD, spriteimage, SPRITE_SIZE * t, SPRITE_HOTSPOT * t, '1 1 1', a, DRAWFLAG_MIPMAP);
	if (self.build_finished) {
		if (time < self.build_finished + 0.25) {
			if (time < self.build_started)
				self.health = self.build_starthealth;
			else if(time < self.build_finished)
				self.health = (time - self.build_started) / (self.build_finished - self.build_started) * (1 - self.build_starthealth) + self.build_starthealth;
			else
				self.health = 1;
		} else
			self.health = -1;
	}

	if (self.health >= 0) {
		float align;
		if (self.build_finished)
			align = 0.5;
		else
			align = 0;

		waypointsprite_healthbar_draw(o, rot * 90 * MATH_DEG2RAD, self.health, SPRITE_SIZE * t, SPRITE_HOTSPOT * t, SPRITE_HEALTHBAR_WIDTH * t, SPRITE_HEALTHBAR_HEIGHT * t, SPRITE_HEALTHBAR_MARGIN * t, SPRITE_HEALTHBAR_BORDER * t, align, self.teamradar_color, a * SPRITE_HEALTHBAR_BORDERALPHA, self.teamradar_color, a * SPRITE_HEALTHBAR_HEALTHALPHA, DRAWFLAG_NORMAL);
	}
}

void(void) waypointsprite_remove {
	if (self.netname)
		strunzone(self.netname);

	if (self.netname2)
		strunzone(self.netname2);

	if (self.netname3)
		strunzone(self.netname3);
}

void(float ignore) waypointsprite_read {
	float sendflags, f, t;
	sendflags = net_read_byte();
	if not(self.spawntime)
		self.spawntime = time;

	self.draw2d = waypointsprite_draw;
	self.draw2dflag = 1;
	interpolate_undo();
	if (sendflags & 0x80) {
		t = net_read_byte();
		if (t < 192) {
			self.health = t / 191.0;
			self.build_finished = 0;
		} else {
			t = (t - 192) * 256 + net_read_byte();
			self.build_started = server_time;
			if (self.build_finished)
				self.build_starthealth = bound(0, self.health, 1);
			else
				self.build_starthealth = 0;

			self.build_finished = server_time + t / 32;
			//print("build: ", ftos(self.build_finished - self.build_started), "\n");
		}
	} else {
		self.health = -1;
		self.build_finished = 0;
	}
	if (sendflags & 64) {
		// unfortunately, this needs to be exact (for the 3D display)
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
	}
	if (sendflags & 1) {
		self.team = net_read_byte();
		self.rule = net_read_byte();
	}
	if (sendflags & 2) {
		if (self.netname)
			strunzone(self.netname);

		self.netname = strzone(net_read_string());
		self.cnt = 0;
	}
	if (sendflags & 4) {
		if (self.netname2)
			strunzone(self.netname2);

		self.netname2 = strzone(net_read_string());
		self.cnt = 0;
	}

	if (sendflags & 8) {
		if (self.netname3)
			strunzone(self.netname3);

		self.netname3 = strzone(net_read_string());
		self.cnt = 0;
	}
	if (sendflags & 16) {
		self.lifetime = net_read_coord();
		self.fadetime = net_read_coord();
		self.maxdistance = net_read_short();
		self.hideflags = net_read_byte();
	}
	if (sendflags & 32) {
		f = net_read_byte();
		self.teamradar_icon = (f & 0x7F);
		if (f & 0x80) {
			self.(teamradar_times[self.teamradar_time_index]) = time;
			self.teamradar_time_index = math_mod(self.teamradar_time_index + 1, MAX_TEAMRADAR_TIMES);
		}
		self.teamradar_color_x = net_read_byte() / 255.0;
		self.teamradar_color_y = net_read_byte() / 255.0;
		self.teamradar_color_z = net_read_byte() / 255.0;
	}
	interpolate_note();
	self.entremove = waypointsprite_remove;
}

void(void) waypointsprite_init {
	waypointsprite_fadedistance = vlen(world_max - world_min);
	waypointsprite_edgefadealpha = CVAR_OR(g_waypointsprite_edgefadealpha, 1);
	waypointsprite_edgefadescale = CVAR_OR(g_waypointsprite_edgefadescale, 1);
	waypointsprite_crosshairfadealpha = CVAR_OR(g_waypointsprite_crosshairfadealpha, 1);
	waypointsprite_crosshairfadescale = CVAR_OR(g_waypointsprite_crosshairfadescale, 1);
	waypointsprite_distancefadealpha = CVAR_OR(g_waypointsprite_distancefadealpha, 1);
	waypointsprite_distancefadescale = CVAR_OR(g_waypointsprite_distancefadescale, 1);
	waypointsprite_distancefadedistance = vlen(world_max - world_min) * CVAR_OR(g_waypointsprite_distancefadedistancemultiplier, 1);
	float dh, n, i, o, f;
	string s, sname, sframes;
	dh = search_begin("models/sprites/*_frame*.tga", FALSE, FALSE);
	n = search_getsize(dh);
	for (i = 0; i < n; ++i) {
		s = search_getfilename(dh, i);
		if (substring(s, 0, 15) != "models/sprites/")
			continue;

		if (substring(s, strlen(s) - 4, 4) != ".tga")
			continue;

		s = substring(s, 15, strlen(s) - 19);
		o = strstrofs(s, "_frame", 0);
		sname = strcat("/spriteframes/", substring(s, 0, o));
		sframes = substring(s, o + 6, strlen(s) - o - 6);
		f = stof(sframes) + 1;
		db_put(db_temp, sname, ftos(max(f, stof(db_get(db_temp, sname)))));
	}
	search_end(dh);
	entity e = NULL;
	while ((e = nextent(e))) {
		if (e.draw2d == waypointsprite_draw) {
			e.cnt = 0;
		}
	}
}
