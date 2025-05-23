float marker_fadedistance;
float marker_edgefadealpha;
float marker_edgefadescale;
float marker_crosshairfadealpha;
float marker_crosshairfadescale;
float marker_distancefadealpha;
float marker_distancefadescale;
float marker_distancefadedistance;

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
.vector text_color1;
.vector text_color2;
.vector text_color3;

const vector MARKER_SIZE = '288 36 0';
const vector MARKER_HOTSPOT = '144 36 0';
const float MARKER_HEALTHBAR_WIDTH = 144;
const float MARKER_HEALTHBAR_HEIGHT = 9;
const float MARKER_HEALTHBAR_MARGIN = 6;
const float MARKER_HEALTHBAR_BORDER = 2;
const float MARKER_HEALTHBAR_BORDERALPHA = 1;
const float MARKER_HEALTHBAR_HEALTHALPHA = 0.5;

void(vector org, float rot, float h, vector sz, vector hotspot, float width, float height, float margin, float border, float align, vector rgb, float a, vector hrgb, float ha, float f) marker_healthbar_draw {
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

float marker_draw_team;
void(void) marker_draw {
	string spriteimage;
	float t = 0;
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

	if (marker_draw_team != team_my) {
		marker_draw_team = team_my;
		entity e;
		for (e = self; e; e = find(e, classname, "waypointsprite")) {
			e.cnt = 0;
			e.model = "";
		}
	}
	interpolate_do();
	spriteimage = "";
	string toptext = "";
	// choose the sprite
	float dist;
	dist = vlen(self.origin - view_origin);
	float a;
	a = self.alpha * sbar_alpha_fg;
	if (self.maxdistance > CVAR(g_waypointsprite_normdistance))
		a *= pow(bound(0, (self.maxdistance - dist) / (self.maxdistance - CVAR(g_waypointsprite_normdistance)), 1), CVAR(g_waypointsprite_distancealphaexponent));
	else if (self.maxdistance > 0)
		a *= pow(bound(0, (marker_fadedistance - dist) / (marker_fadedistance - CVAR(g_waypointsprite_normdistance)), 1), CVAR(g_waypointsprite_distancealphaexponent)) * (1 - CVAR(g_waypointsprite_minalpha)) + CVAR(g_waypointsprite_minalpha);

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
		if not(self.team) {
			self.model = self.netname;
			self.colormod = self.text_color1;
		} else if (team_my == TEAM_COLOR_SPECTATOR) { //spectator
			self.model = self.netname3;
			self.colormod = self.text_color3;
		} else if (self.team == team_my) {
			if (self.text_color1 != '0 0 0' && self.netname3 != "") {
				self.model = self.netname3;
				self.colormod = self.text_color3;
			} else {
				self.model = self.netname2;
				self.colormod = self.text_color2;
			}
		} else {
			if (self.text_color1 != '0 0 0' && self.netname3 != "") {
				self.model = self.netname3;
				self.colormod = self.text_color3;
			} else {
				self.model = self.netname;
				self.colormod = self.text_color1;
			}
		}
		if (self.text_color1 != '0 0 0') {
			t = -1;
			self.cnt = -1;
		} else {
			t = stof(db_get(db_temp, strcat("/spriteframes/", self.model)));
			self.cnt = t + 1;
		}
	} else
		t = self.cnt - 1;

	if (self.model == "")
		return;

	if (t == 0)
		spriteimage = strcat("models/sprites/", self.model);
	else if (t > 0)
		spriteimage = strcat("models/sprites/", self.model, "_frame", ftos(math_mod(floor((max(0, time - self.spawntime)) * 2), t)));

	float edgedistance_min, crosshairdistance;
	edgedistance_min = min4(o_y, o_x,CVAR(vid_conwidth) - o_x, CVAR(vid_conheight) - o_y);
	crosshairdistance = sqrt( pow(o_x - CVAR(vid_conwidth)/2, 2) + pow(o_y - CVAR(vid_conheight)/2, 2) );
	t = CVAR_OR(g_waypointsprite_scale, 1) * (1 - CVAR(_menu_alpha)) * vidscale;
	a = a * (1 - (1 - marker_distancefadealpha) * (bound(0, dist/marker_distancefadedistance, 1)));
	t = t * (1 - (1 - marker_distancefadescale) * (bound(0, dist/marker_distancefadedistance, 1)));
	if (edgedistance_min < CVAR(g_waypointsprite_edgefadedistance)) {
		a = a * (1 - (1 - marker_edgefadealpha) * (1 - bound(0, edgedistance_min/CVAR(g_waypointsprite_edgefadedistance), 1)));
		t = t * (1 - (1 - marker_edgefadescale) * (1 - bound(0, edgedistance_min/CVAR(g_waypointsprite_edgefadedistance), 1)));
	}
	if (crosshairdistance < CVAR(g_waypointsprite_crosshairfadedistance)) {
		a = a * (1 - (1 - marker_crosshairfadealpha) * (1 - bound(0, crosshairdistance/CVAR(g_waypointsprite_crosshairfadedistance), 1)));
		t = t * (1 - (1 - marker_crosshairfadescale) * (1 - bound(0, crosshairdistance/CVAR(g_waypointsprite_crosshairfadedistance), 1)));
	}
	float txty = 0;
	if (self.cnt < 0) {
		drawfont = sbar_bigfont;
		vector fs = '30 30 0' * t;
		float sw = stringwidth(self.model, FALSE) * fs_x;
		vector oc = o - '0.5 0 0' * sw + '0 -20 0';
		oc_x = bound(10, oc_x, CVAR(vid_conwidth) - sw - 10);
		oc_y = bound(10, oc_y, CVAR(vid_conheight) - fs_y - 10);
		txty = oc_y;
		drawstring(oc, self.model, fs, self.colormod, a, DRAWFLAG_NORMAL);
		toptext = (self.team ? ((self.team == team_my) ? self.netname2 : self.netname) : "");
		if (toptext != "" && toptext != self.model) {
			fs += '1 1 0' * 2 * sin(time*3);
			sw = stringwidth(toptext, FALSE) * fs_x;
			oc_y = bound(10 + fs_y*1.5, oc_y - fs_y*1.5, CVAR(vid_conheight) - fs_y*3 - 10);
			oc_x = bound(10, o_x - sw * 0.5, CVAR(vid_conwidth) - sw - 10);
			drawstring(oc, toptext, fs, ((self.team == team_my) ? self.text_color2 : self.text_color1), a/* * self.topalpha*/, DRAWFLAG_NORMAL);
		}
		drawfont = sbar_font;
    } else
		draw_picture_rotate(o, rot * 90 * MATH_DEG2RAD, spriteimage, MARKER_SIZE * t, MARKER_HOTSPOT * t, '1 1 1', a, DRAWFLAG_MIPMAP);

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

		if (self.cnt < 0) {
			float w = MARKER_HEALTHBAR_WIDTH * t;
			float h = MARKER_HEALTHBAR_HEIGHT * t;
			rot = 0;
			o_x = bound(10 + w * 0.5, o_x, CVAR(vid_conwidth) - w * 0.5 - 10);
			o_y = bound(10 + h * 0.5, txty + h*5, CVAR(vid_conheight) - h * 0.5);
		}
		marker_healthbar_draw(o, rot * 90 * MATH_DEG2RAD, self.health, MARKER_SIZE * t, MARKER_HOTSPOT * t, MARKER_HEALTHBAR_WIDTH * t, MARKER_HEALTHBAR_HEIGHT * t, MARKER_HEALTHBAR_MARGIN * t, MARKER_HEALTHBAR_BORDER * t, align, self.radar_color, a * MARKER_HEALTHBAR_BORDERALPHA, self.radar_color, a * MARKER_HEALTHBAR_HEALTHALPHA, DRAWFLAG_NORMAL);
	}
}

void(void) marker_remove {
	str_unzone_ifneeded(self.netname);
	str_unzone_ifneeded(self.netname2);
	str_unzone_ifneeded(self.netname3);
}

void(float isnew) marker_read {
	float sendflags, f, t;
	sendflags = net_read_byte();
	if not(self.spawntime)
		self.spawntime = time;

	self.draw2d = marker_draw;
	self.draw2dflag = 1;
	self.classname = "waypointsprite";
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
	}
	if (sendflags & 2) {
		str_unzone_ifneeded(self.netname);
		self.netname = str_zone_ifneeded(net_read_string());
		self.cnt = 0;
		self.model = "";
	}
	if (sendflags & 4) {
		str_unzone_ifneeded(self.netname2);
		self.netname2 = str_zone_ifneeded(net_read_string());
		self.cnt = 0;
		self.model = "";
	}

	if (sendflags & 8) {
		str_unzone_ifneeded(self.netname3);
		self.netname3 = str_zone_ifneeded(net_read_string());
		self.cnt = 0;
		self.model = "";
	}
	if (sendflags & 16) {
		self.lifetime = net_read_coord();
		self.fadetime = net_read_coord();
		self.maxdistance = net_read_short();
		self.hideflags = net_read_byte();
	}
	if (sendflags & 32) {
		f = net_read_byte();
		self.radar_icon = (f & 0x7F);
		if (f & 0x80)
			radar_ping(self.origin);

		self.radar_color = net_read_color();
		self.text_color1 = net_read_color();
		self.text_color2 = net_read_color();
		self.text_color3 = net_read_color();
		if (self.text_color1 != '0 0 0'
				|| self.text_color2 != '0 0 0'
				|| self.text_color3 != '0 0 0') {
			self.cnt = 0;
			self.model = "";
		}
	}
	interpolate_note();
	self.entremove = marker_remove;
}

void(void) marker_init {
	marker_fadedistance = vlen(world_max - world_min);
	marker_edgefadealpha = CVAR_OR(g_waypointsprite_edgefadealpha, 1);
	marker_edgefadescale = CVAR_OR(g_waypointsprite_edgefadescale, 1);
	marker_crosshairfadealpha = CVAR_OR(g_waypointsprite_crosshairfadealpha, 1);
	marker_crosshairfadescale = CVAR_OR(g_waypointsprite_crosshairfadescale, 1);
	marker_distancefadealpha = CVAR_OR(g_waypointsprite_distancefadealpha, 1);
	marker_distancefadescale = CVAR_OR(g_waypointsprite_distancefadescale, 1);
	marker_distancefadedistance = vlen(world_max - world_min) * CVAR_OR(g_waypointsprite_distancefadedistancemultiplier, 1);
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
	while ((e = find(e, classname, "waypointsprite"))) {
		e.cnt = 0;
		e.model = "";
	}
}
