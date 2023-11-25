void(float isnew) warpzone_read {
	if not(self.enemy) {
		self.enemy = spawn();
		self.enemy.classname = "warpzone_from";
	}
	self.classname = "trigger_warpzone";
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.modelindex = net_read_short();
	self.mins_x = net_read_coord();
	self.mins_y = net_read_coord();
	self.mins_z = net_read_coord();
	self.maxs_x = net_read_coord();
	self.maxs_y = net_read_coord();
	self.maxs_z = net_read_coord();
	self.scale = net_read_byte() / 16;
	self.enemy.oldorigin_x = net_read_coord();
	self.enemy.oldorigin_y = net_read_coord();
	self.enemy.oldorigin_z = net_read_coord();
	self.enemy.avelocity_x = net_read_coord();
	self.enemy.avelocity_y = net_read_coord();
	self.enemy.avelocity_z = net_read_coord();
	self.oldorigin_x = net_read_coord();
	self.oldorigin_y = net_read_coord();
	self.oldorigin_z = net_read_coord();
	self.avelocity_x = net_read_coord();
	self.avelocity_y = net_read_coord();
	self.avelocity_z = net_read_coord();
	// common stuff
	warpzone_setup(self, self.enemy.oldorigin, self.enemy.avelocity, self.oldorigin, self.avelocity);
	// engine currently wants this
	self.avelocity = anglestransform_turn_direction_fr(self.avelocity);
	self.drawmask = MASK_NORMAL;
	// link me
	//setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	warpzone_chain_add(self);
	if (!cvar("r_water"))
		cvar_clientsettemp("r_water", "1");

	if(cvar("r_water_resolutionmultiplier") < 1)
		cvar_clientsettemp("r_water_resolutionmultiplier", "1");

	warpzone_enable();
}

void(void) warpzone_teleported_draw2d {
	if (server_time != self.cnt) {
		remove(self);
		return;
	}
	view_fixangle = 1;
	view_fixed_angles = self.origin;
	makevectors(view_fixed_angles);
	view_forward = v_forward; //hack for crosshair position
}

void(float isnew) warpzone_teleported_read {
	vector v, v2;
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = net_read_coord();
	v2_x = net_read_coord();
	v2_y = net_read_coord();
	v2_z = 0;
	if (!isnew)
		return;

	if (warpzone_passed)
		remove(warpzone_passed);

	physics_was_teleported = TRUE;
	warpzone_passed = spawn();
	warpzone_passed.warpzone_transform = v;
	if (main_isdemo || (view_spectatee_status && !view_observer_status)) {
		entity e = spawn();
		e.origin = v2;
		e.draw2dflag = 1;
		e.draw2d = warpzone_teleported_draw2d;
		e.cnt = server_time;
		view_fixangle = 1;
		view_fixed_angles = v2;
		remove(warpzone_passed);
		warpzone_passed = NULL;
		return;
	}
}

float warpzone_fixingview;
float warpzone_fixingview_drawexteriormodel;
//float warpzone_fixingview_sidespeed;
//float warpzone_fixingview_forwardspeed;
void WarpZone_Inside()
{
	if(warpzone_fixingview)
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
	if(!warpzone_fixingview)
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
	e = warpzone_find(mi, ma);
	if(e) {
		if (warpzone_plane_dist(e, o) < 0)
			return '0 0 0'; // can't really be, though, but if it is, this is not my warpzone, but a random different one in the same mins/maxs

		pd = min(
				warpzone_plane_dist(e, c0), min(
				warpzone_plane_dist(e, c1), min(
				warpzone_plane_dist(e, c2),
				warpzone_plane_dist(e, c3)))
			);
		if (pd < 0)
			return e.warpzone_forward * -pd;
	}
	return '0 0 0';
}

float warpzone_fixangles;
void(void) warpzone_view_fix_real {
	entity e;
	vector org, nearclip, corner0, corner1, corner2, corner3;
	float f;
	vector orig_angles = view_angles;
	org = view_origin;
	e = warpzone_find(org, org);
	if (e) {
		org = warpzone_transform_origin(e, org);
		if (warpzone_view != e) {
			if (warpzone_view)
				view_angles = warpzone_untransform_vangles(warpzone_view, view_angles);

			view_angles = warpzone_transform_vangles(e, view_angles);
		}
		WarpZone_Inside();
		if not(warpzone_view)
			warpzone_view_commandframe = physics_lastcommandframe;
	} else {
		WarpZone_Outside();
		if (warpzone_view) {
			if not(warpzone_passed) {
				view_angles = warpzone_untransform_vangles(warpzone_view, view_angles);
				warpzone_fixangles = TRUE;
			} else
				view_angles = view_angles;
		} else
			view_angles = view_angles;

		if (warpzone_passed) {
			if not(warpzone_view)
				view_angles = warpzone_transform_vangles(warpzone_passed, view_angles);

			warpzone_fixangles = TRUE;
			remove(warpzone_passed);
			warpzone_passed = NULL;
		}
	}
	warpzone_view = e;
	if (warpzone_fixangles || orig_angles != view_angles) {
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
	if (view_origin != org) { //This code MUST be duplicated for cs_unproject
		R_SetView(VF_ORIGIN, org);
		view_origin = org;
	}
	nearclip = '0 0 1' * (CVAR(r_nearclip) * 1.125);
	corner0 = cs_unproject('0 0 0' + nearclip);
	corner1 = cs_unproject('1 0 0' * CVAR(vid_conwidth) + nearclip);
	corner2 = cs_unproject('0 1 0' * CVAR(vid_conheight) + nearclip);
	corner3 = cs_unproject('1 0 0' * CVAR(vid_conwidth) + '0 1 0' * CVAR(vid_conheight) + nearclip);
	vector v = WarpZone_FixNearClip(org, corner0, corner1, corner2, corner3);
	if (v != '0 0 0') {
		org = org + v;
		R_SetView(VF_ORIGIN, org); //This code MUST be duplicated for cs_unproject
		view_origin = org;
	}
}

void() warpzone_init_hook {
	warpzone_sound_transition = CVAR(cl_warpzone_sound_transition);
}

void() warpzone_shutdown_hook {
	WarpZone_Outside();
}

void() warpzone_enable_hook {
	warpzone_view_fix = warpzone_view_fix_real;
	WarpZone_Outside();
}
