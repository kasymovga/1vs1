void WarpZone_Read(float isnew)
{
	if not(self.enemy)
	{
		self.enemy = spawn();
		self.enemy.classname = "warpzone_from";
	}
	self.classname = "trigger_warpzone";
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	self.modelindex = ReadShort();
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.scale = ReadByte() / 16;
	self.enemy.oldorigin_x = ReadCoord();
	self.enemy.oldorigin_y = ReadCoord();
	self.enemy.oldorigin_z = ReadCoord();
	self.enemy.avelocity_x = ReadCoord();
	self.enemy.avelocity_y = ReadCoord();
	self.enemy.avelocity_z = ReadCoord();
	self.oldorigin_x = ReadCoord();
	self.oldorigin_y = ReadCoord();
	self.oldorigin_z = ReadCoord();
	self.avelocity_x = ReadCoord();
	self.avelocity_y = ReadCoord();
	self.avelocity_z = ReadCoord();

	// common stuff
	WarpZone_SetUp(self, self.enemy.oldorigin, self.enemy.avelocity, self.oldorigin, self.avelocity);

	// engine currently wants this
	self.avelocity = AnglesTransform_TurnDirectionFR(self.avelocity);
	self.drawmask = MASK_NORMAL;

	// link me
	//setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);

	WarpZone_ChainAdd(self);

    if(!cvar("r_water"))
        cvar_clientsettemp("r_water", "1");

    if(cvar("r_water_resolutionmultiplier") < 1)
        cvar_clientsettemp("r_water_resolutionmultiplier", "1");

	WarpZone_Enable();
}

entity warpzone_passed;
void WarpZone_Teleported_Read(float isnew)
{
	vector v;
	v_x = ReadCoord();
	v_y = ReadCoord();
	v_z = ReadCoord();
	if(!isnew)
		return;

	if (warpzone_passed)
		remove(warpzone_passed);

	warpzone_passed = spawn();
	warpzone_passed.warpzone_transform = v;
}

float warpzone_fixingview;
float warpzone_fixingview_drawexteriormodel;
//float warpzone_fixingview_sidespeed;
//float warpzone_fixingview_forwardspeed;
void WarpZone_Inside()
{
	if(warpzone_fixingview || !warpzone_newstyle)
		return;
	warpzone_fixingview = 1;
	warpzone_fixingview_drawexteriormodel = cvar("r_drawexteriormodel");
	//warpzone_fixingview_sidespeed = cvar("cl_sidespeed");
	//warpzone_fixingview_forwardspeed = cvar("cl_forwardspeed");
	cvar_set("r_drawexteriormodel", "0");
	//cvar_set("cl_sidespeed", ftos(warpzone_fixingview_sidespeed / 100)); // just keep a bit of it in case player gets stuck
	//cvar_set("cl_forwardspeed", ftos(warpzone_fixingview_forwardspeed / 100)); // just keep a bit of it in case player gets stuck
}

void WarpZone_Outside()
{
	if(!warpzone_fixingview || !warpzone_newstyle)
		return;
	warpzone_fixingview = 0;
	cvar_set("r_drawexteriormodel", ftos(warpzone_fixingview_drawexteriormodel));
	//cvar_set("cl_sidespeed", ftos(warpzone_fixingview_sidespeed));
	//cvar_set("cl_forwardspeed", ftos(warpzone_fixingview_forwardspeed));
}

vector WarpZone_FixNearClip(vector o, vector c0, vector c1, vector c2, vector c3)
{
	vector mi, ma;
	entity e;
	float pd;

	mi_x = min(o_x, min(c0_x, min(c1_x, min(c2_x, c3_x))));
	ma_x = max(o_x, max(c0_x, max(c1_x, max(c2_x, c3_x))));
	mi_y = min(o_y, min(c0_y, min(c1_y, min(c2_y, c3_y))));
	ma_y = max(o_y, max(c0_y, max(c1_y, max(c2_y, c3_y))));
	mi_z = min(o_z, min(c0_z, min(c1_z, min(c2_z, c3_z))));
	ma_z = max(o_z, max(c0_z, max(c1_z, max(c2_z, c3_z))));

	e = WarpZone_Find(mi, ma);
	if(e)
	{
		if(WarpZone_PlaneDist(e, o) < 0)
			return '0 0 0';
			// can't really be, though, but if it is, this is not my warpzone, but a random different one in the same mins/maxs
		pd = min(
				WarpZone_PlaneDist(e, c0), min(
				WarpZone_PlaneDist(e, c1), min(
				WarpZone_PlaneDist(e, c2), 
				WarpZone_PlaneDist(e, c3)))
			);
		if(pd < 0)
			return e.warpzone_forward * -pd;
	}

	return '0 0 0';
}

float warpzone_fixangles;
void WarpZone_FixView_real()
{
	entity e;
	vector org, nearclip, corner0, corner1, corner2, corner3;
	float f;
	org = view_origin;
	e = WarpZone_Find(org, org);
	if(e)
	{
		org = WarpZone_TransformOrigin(e, org);
		if (warpzone_view != e) {
			if (warpzone_view)
				view_angles = WarpZone_UnTransformVAngles(warpzone_view, view_angles);

			view_angles = WarpZone_TransformVAngles(e, view_angles);
		}
		WarpZone_Inside();
		if not(warpzone_view)
			warpzone_view_commandframe = physics_lastcommandframe;
	}
	else {
		WarpZone_Outside();
		if (warpzone_view) {
			if not(warpzone_passed) {
				view_angles = WarpZone_UnTransformVAngles(warpzone_view, view_angles);
				warpzone_fixangles = TRUE;
			} else
				view_angles = view_angles;
		} else
			view_angles = view_angles;

		if (warpzone_passed) {
			if not(warpzone_view)
				view_angles = WarpZone_TransformVAngles(warpzone_passed, view_angles);

			warpzone_fixangles = TRUE;
			remove(warpzone_passed);
			warpzone_passed = world;
		}
	}
	warpzone_view = e;
	if (warpzone_fixangles || e) {
		if not(e) {
			f = max(0, (1 - frametime * 10));

			if (view_angles_z > 180)
				view_angles_z -= 360;
			else if (view_angles_z < -180)
				view_angles_z += 360;

			view_angles_z = view_angles_z * f;
			if (view_angles_z < 1)
			if (view_angles_z > -1)
				view_angles_z = 0;
		}
		warpzone_fixangles = view_angles_z;
		R_SetView(VF_ANGLES, view_angles);
		R_SetView(VF_CL_VIEWANGLES, view_angles);
	}

	if (e)
		R_SetView(VF_ORIGIN, org);

	nearclip = '0 0 1' * (CVAR(r_nearclip) * 1.125);
	corner0 = cs_unproject('0 0 0' + nearclip);
	corner1 = cs_unproject('1 0 0' * CVAR(vid_conwidth) + nearclip);
	corner2 = cs_unproject('0 1 0' * CVAR(vid_conheight) + nearclip);
	corner3 = cs_unproject('1 0 0' * CVAR(vid_conwidth) + '0 1 0' * CVAR(vid_conheight) + nearclip);
	vector v = WarpZone_FixNearClip(org, corner0, corner1, corner2, corner3);
	org = org + v;
	if (v != '0 0 0')
		R_SetView(VF_ORIGIN, org);

	view_origin = org;
}

void WarpZone_InitHook() {
	warpzone_sound_transition = CVAR(cl_warpzone_sound_transition);
	warpzone_newstyle = checkextension("DP_CSQC_ROTATEMOVES");
}

void WarpZone_ShutdownHook() {
	WarpZone_Outside();
}

void WarpZone_EnableHook() {
	WarpZone_FixView = WarpZone_FixView_real;
	WarpZone_Outside();
}
