.vector hook_shootorg;
entity hook_pull;
float hook_pull_length_readed;

string hook_draw_cb_tex;
void(vector start, vector end, vector to) hook_draw_cb {
	draw_cylindric_line(start, end, 8, hook_draw_cb_tex, 0.25, random(), '1 1 1', 1, DRAWFLAG_NORMAL, WarpZone_TransformOrigin(WarpZone_trace_transform, view_camera_origin));
}

void(void) hook_draw {
	vector a = '0 0 0', b;
	vector rgb;
	float t;
	InterpolateOrigin_Do();
	float owner_entnum = self.sv_entnum;
	if (hook_pull == self) {
		physics_hook_old_length = hook_pull_length_readed;
	}
	b = self.origin;
	if (!CVAR(chase_active) && (owner_entnum == player_localentnum || owner_entnum == view_spectatee_status)) {
		vector hook_shotorigin = self.hook_shootorg;
		a = view_origin + view_forward * hook_shotorigin_x + view_right * hook_shotorigin_y + view_up * hook_shotorigin_z;
		if (warpzone_view)
			a = WarpZone_UnTransformOrigin(warpzone_view, a);
	} else {
		entity e = self;
		self = self.enemy;
		if (CVAR(chase_active) && !view_spectatee_status && owner_entnum == player_localentnum) {
			a = self.iorigin2 + (physics_end_origin - physics_start_origin);
		} else if (self) {
			InterpolateOrigin_Do();
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
	WarpZone_DrawEffectTriangle(a, a, b, hook_draw_cb);
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
	g_balance_grapplehook_airfriction = ReadCoord();
	g_balance_grapplehook_dontpull = ReadCoord();
	g_balance_grapplehook_force_rubber = ReadCoord();
	g_balance_grapplehook_force_rubber_overstretch = ReadCoord();
	g_balance_grapplehook_length_min = ReadCoord();
	g_balance_grapplehook_speed_pull = ReadCoord();
	g_balance_grapplehook_stretch = ReadCoord();
	g_grappling_hook_tarzan = ReadCoord();
	physics_hook_enable();
}

void(float ignore) hook_read {
	float f = ReadByte();
	float owner_num;
	if (f & 1) {
		owner_num = ReadByte();
		self.sv_entnum = owner_num;
		self.draw = hook_draw;
		self.entremove = Remove_GrapplingHook;
		if not(self.enemy)
			self.enemy = spawn();
	}
	if (f & 2) {
		self.hook_shootorg_x = ReadChar();
		self.hook_shootorg_y = ReadChar();
		self.hook_shootorg_z = ReadChar();
	}
	if (f & 4) {
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		InterpolateOrigin_Note();
		if (f & 16)
			InterpolateOrigin_Note();
	}
	if (f & 8) {
		entity e = self;
		if not(self.enemy)
			self.enemy = spawn();

		self = self.enemy;
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		InterpolateOrigin_Note();
		if (f & 16)
			InterpolateOrigin_Note();

		self = e;
	}
	if (f & 16) {
		hook_pull = self;
		hook_pull_length_readed = ReadCoord();
	} else
		hook_pull = world;
}
