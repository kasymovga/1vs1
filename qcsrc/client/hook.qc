.vector hook_shootorg;
entity hook_pull;
float hook_pull_length_readed;

string hook_draw_cb_tex;
void(vector start, vector end, vector to) hook_draw_cb {
	draw_cylindric_line(start, end, 8, hook_draw_cb_tex, 0.25, random(), '1 1 1', 1, DRAWFLAG_NORMAL, warpzone_transform_origin(warpzone_trace_transform, view_camera_origin));
}

void(void) hook_draw {
	vector a = '0 0 0', b;
	vector rgb;
	float t;
	interpolate_do();
	float owner_entnum = self.sv_entnum;
	if (hook_pull == self) {
		physics_hook_old_length = hook_pull_length_readed;
	}
	b = self.origin;
	if (!CVAR(chase_active) && (owner_entnum == player_localentnum || owner_entnum == view_spectatee_status)) {
		vector hook_shotorigin = self.hook_shootorg;
		a = view_origin + view_forward * hook_shotorigin_x + view_right * hook_shotorigin_y + view_up * hook_shotorigin_z;
		if (warpzone_view)
			a = warpzone_untransform_origin(warpzone_view, a);
	} else {
		entity e = self;
		self = self.enemy;
		if (CVAR(chase_active) && !view_spectatee_status && owner_entnum == player_localentnum) {
			a = self.iorigin2 + (physics_end_origin - physics_start_origin);
		} else if (self) {
			interpolate_do();
			a = self.origin;
		}
		self = e;
	}
	t = player_color_force(owner_entnum - 1);
	if (t == COLOR_TEAM1) {
		hook_draw_cb_tex = "particles/hook_red";
		rgb = '1 .3 .3';
	} else if(t == COLOR_TEAM2) {
		hook_draw_cb_tex = "particles/hook_blue";
		rgb = '.3 .3 1';
	} else if(t == COLOR_TEAM3) {
		hook_draw_cb_tex = "particles/hook_yellow";
		rgb = '1 1 .3';
	} else if(t == COLOR_TEAM4) {
		hook_draw_cb_tex = "particles/hook_pink";
		rgb = '1 .3 1';
	} else {
		hook_draw_cb_tex = "particles/hook_green";
		rgb = '.3 1 .3';
	}
	warpzone_draw_effect_triangle(a, a, b, hook_draw_cb);
}

void Remove_GrapplingHook() {
	if (self == hook_pull)
		hook_pull = world;

	if (self.enemy) {
		remove(self.enemy);
		self.enemy = world;
	}
}

entity(void) hook_get {
	return hook_pull;
}

void(entity _hook, vector v, vector v0, vector dir) hook_pull_aiment {
}

void(entity _hook, entity pl) hook_physics_pre {
}

void(entity _hook, entity pl) hook_physics_post {
}

void(float ignore) hook_physics_read {
	g_balance_grapplehook_airfriction = net_read_coord();
	g_balance_grapplehook_dontpull = net_read_coord();
	g_balance_grapplehook_force_rubber = net_read_coord();
	g_balance_grapplehook_force_rubber_overstretch = net_read_coord();
	g_balance_grapplehook_length_min = net_read_coord();
	g_balance_grapplehook_speed_pull = net_read_coord();
	g_balance_grapplehook_stretch = net_read_coord();
	g_grappling_hook_tarzan = net_read_coord();
	physics_hook_enable();
}

void(float ignore) hook_read {
	float f = net_read_byte();
	float owner_num;
	if (f & 1) {
		owner_num = net_read_byte();
		self.sv_entnum = owner_num;
		self.draw = hook_draw;
		self.entremove = Remove_GrapplingHook;
		if not(self.enemy)
			self.enemy = spawn();
	}
	if (f & 2) {
		self.hook_shootorg_x = net_read_char();
		self.hook_shootorg_y = net_read_char();
		self.hook_shootorg_z = net_read_char();
	}
	if (f & 4) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
		interpolate_note();
		if (f & 16)
			interpolate_note();
	}
	if (f & 8) {
		entity e = self;
		if not(self.enemy)
			self.enemy = spawn();

		self = self.enemy;
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
		interpolate_note();
		if (f & 16)
			interpolate_note();

		self = e;
	}
	if (f & 16) {
		hook_pull = self;
		hook_pull_length_readed = net_read_coord();
	} else
		hook_pull = world;
}
