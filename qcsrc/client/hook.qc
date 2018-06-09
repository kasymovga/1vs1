.vector hook_shootorg;
void Draw_CylindricLine(vector from, vector to, float thickness, string texture, float aspect, float shift, vector rgb, float alpha, float drawflag, vector view_org)
{
	// I want to draw a quad...
	// from and to are MIDPOINTS.
	
	vector axis, thickdir, A, B, C, D;
	float length_tex;

	axis = normalize(to - from);
	length_tex = aspect * vlen(to - from) / thickness;

	// direction is perpendicular to the view normal, and perpendicular to the axis
	thickdir = normalize(cross(axis, view_org - from));

	A = from - thickdir * (thickness / 2);
	B = from + thickdir * (thickness / 2);
	C = to + thickdir * (thickness / 2);
	D = to - thickdir * (thickness / 2);

	R_BeginPolygon(texture, drawflag);
	R_PolygonVertex(A, '0 0 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(B, '0 1 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(C, '0 1 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_PolygonVertex(D, '0 0 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_EndPolygon();
}

string Draw_GrapplingHook_cb_tex;
void Draw_GrapplingHook_cb(vector start, vector end, vector to) {
	Draw_CylindricLine(start, end, 8, Draw_GrapplingHook_cb_tex, 0.25, random(), '1 1 1', 1, DRAWFLAG_NORMAL, WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin));
}

void Draw_GrapplingHook()
{
	vector a, b;
	vector rgb;
	float t;
	InterpolateOrigin_Do();
	float owner_entnum = self.sv_entnum;

	b = self.origin;
	if(!CVAR(chase_active) && (owner_entnum == player_localentnum || owner_entnum == spectatee_status)) {
		vector hook_shotorigin = self.hook_shootorg;
		a = view_origin + view_forward * hook_shotorigin_x + view_right * hook_shotorigin_y + view_up * hook_shotorigin_z;
		if (warpzone_view)
			a = WarpZone_UnTransformOrigin(warpzone_view, a);
	} else {
		entity e = self;
		self = self.enemy;
		if (self)
			InterpolateOrigin_Do();

		a = self.origin;
		self = e;
	}

	t = GetPlayerColorForce(owner_entnum - 1);

	if(t == COLOR_TEAM1)
	{
		Draw_GrapplingHook_cb_tex = "particles/hook_red";
		rgb = '1 .3 .3';
	}
	else if(t == COLOR_TEAM2)
	{
		Draw_GrapplingHook_cb_tex = "particles/hook_blue";
		rgb = '.3 .3 1';
	}
	else if(t == COLOR_TEAM3)
	{
		Draw_GrapplingHook_cb_tex = "particles/hook_yellow";
		rgb = '1 1 .3';
	}
	else if(t == COLOR_TEAM4)
	{
		Draw_GrapplingHook_cb_tex = "particles/hook_pink";
		rgb = '1 .3 1';
	}
	else
	{
		Draw_GrapplingHook_cb_tex = "particles/hook_green";
		rgb = '.3 1 .3';
	}
	WarpZone_DrawEffectTriangle(a, a, b, Draw_GrapplingHook_cb);
}

void Remove_GrapplingHook() {
	if (self.enemy) {
		remove(self.enemy);
		self.enemy = world;
	}
}

void Ent_GrapplingHook(float ignore) {
	float f = ReadByte();
	float owner_num;
	if (f & 1) {
		owner_num = ReadByte();
		self.sv_entnum = owner_num;
		self.draw = Draw_GrapplingHook;
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
		self = self.enemy;
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		InterpolateOrigin_Note();
		if (f & 16)
			InterpolateOrigin_Note();

		self = e;
	}
}
