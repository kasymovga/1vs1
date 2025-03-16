entity warpzone_passed;
float warpzone_prediction_init_done;
var void(entity w) warpzone_predict_next;
void(entity w) warpzone_predict {
	if (w.classname != "trigger_warpzone") {
		if (warpzone_predict_next)
			warpzone_predict_next(w);

		return;
	}
	w.solid = SOLID_BSP;
	float ss = self.solid;
	self.solid = SOLID_NOT;
	trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NORMAL, NULL);
	self.solid = ss;
	w.solid = SOLID_NOT;
	if not(trace_ent == w) return;
	vector v = '0 0 0';
	if ((view_observer_status || physics_is_player) && self.classname == "physics_player") {
		v = self.view_ofs;
		v_z = bound(self.mins_z, v_z, self.maxs_z);
	} else {
		v = (self.mins + self.maxs) * .5;
	}
	vector org = self.origin + v;
	if (warpzone_plane_dist(w, org) >= 0) // wrong side of the trigger_warpzone (don't teleport yet)
		return;

	//this code must be synced with warpzone_teleport in server code
	org = warpzone_transform_origin(w, org);
	entity w2 = warpzone_find(org, org);
	if (w2 && w2 == w.enemy) {
		float d = warpzone_plane_dist(w2, org);
		org += w2.warpzone_forward * (0.125 - min(d, 0));
	}
	if (view_observer_status) {
		setorigin(self, org - v);
	} else {
		if (warpzone_move_out_of_solid(w, self, org - v, v)) {
			setorigin(self, warpzone_move_out_of_solid_origin);
		} else
			return;
	}
	physics_velocity = warpzone_transform_velocity(w, physics_velocity);
	self.velocity = warpzone_transform_velocity(w, self.velocity);
	if (w.enemy) {
		if (w.enemy.warpzone_forward_z != 0) {
			float s = sv_gravity * .5;
			float s2 = physics_velocity * w.enemy.warpzone_forward;
			if (s2 < s) {
				physics_velocity += w.enemy.warpzone_forward * (s - s2);
			}
			s2 = self.velocity * w.enemy.warpzone_forward;
			if (s2 < s) {
				self.velocity += w.enemy.warpzone_forward * (s - s2);
			}
		}
	}
	self.angles = warpzone_transform_angles(w, self.angles); //for vehicles
	physics_was_teleported = TRUE;
	if (warpzone_predicted != w || time - warpzone_predicted_time > 0.5) {
		warpzone_predicted = w;
		view_angles = warpzone_transform_vangles(w, view_angles);
		R_SetView(VF_CL_VIEWANGLES, view_angles);
	}
	warpzone_predicted_time = time;
}

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
	self.sv_entnum = net_read_coord();
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
	if not(warpzone_prediction_init_done)
	if not(main_isdemo) {
		warpzone_predict_next = physics_plug_frame_end;
		physics_plug_frame_end = warpzone_predict;
		warpzone_prediction_init_done = 1;
	}
}

void(float isnew) warpzone_teleported_read {
	vector v, v2;
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = net_read_coord();
	v2_x = net_read_coord();
	v2_y = net_read_coord();
	v2_z = 0;
	float entnum = net_read_coord();
	if (!isnew)
		return;

	physics_was_teleported = TRUE;
	if (main_isdemo || (view_spectatee_status && !view_observer_status)) {
		teleport_fix_angles(v2);
	} else if (!warpzone_predicted || time - warpzone_predicted_time > 0.5 || warpzone_predicted.sv_entnum != entnum) {
		entity w;
		for (w = warpzone_chain_begin; w; w = w.warpzone_chain) {
			if (w.sv_entnum == entnum) break;
		}
		warpzone_passed = w;
	}
	warpzone_predicted = NULL;
}

float warpzone_fixangles;
void(void) warpzone_view_fix_real {
	if (warpzone_passed) {
		view_angles = warpzone_transform_vangles(warpzone_passed, view_angles);
		R_SetView(VF_CL_VIEWANGLES, view_angles);
		warpzone_passed = NULL;
	}
	float tx = tan(view_fovx);
	float ty = tan(view_fovy);
	float clipdist = sqrt(tx * tx + ty * ty + CVAR(r_nearclip) * CVAR(r_nearclip)) * 1.125;
	entity w = warpzone_find(view_origin - '1 1 1' * clipdist, view_origin + '1 1 1' * clipdist);
	if (w) {
		float f = warpzone_plane_dist(w, view_origin);
		if (f < clipdist)
			view_origin += (clipdist - f) * w.warpzone_forward;
	}
	if (view_angles_z != 0) {
		view_angles_z = approach_angle(view_angles_z, 0, frametime * 360);
		R_SetView(VF_CL_VIEWANGLES, view_angles);
	}
}

void() warpzone_init_hook {
	warpzone_sound_transition = CVAR(cl_warpzone_sound_transition);
}

void() warpzone_shutdown_hook {
}

void() warpzone_enable_hook {
	warpzone_view_fix = warpzone_view_fix_real;
}
