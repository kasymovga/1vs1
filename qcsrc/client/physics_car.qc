entity physics_car_entity;
vector physics_car_start_angles;
vector physics_car_start_origin;
vector physics_car_start_velocity;

float(void) physics_car_hook {
	entity e = self;
	self = physics_car_entity;
	physics_car();
	self = e;
	return 1;
}

void(void) physics_car_pre {
	setorigin(physics_car_entity, physics_car_start_origin);
	physics_car_entity.velocity = physics_car_start_velocity;
	physics_car_entity.angles = physics_car_start_angles;
}

void(void) physics_car_post {
	physics_vehicle_common_post(physics_car_entity);
}

void(void) physics_car_remove {
	physics_car_entity = world;
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	if (physics_plug_adjust_view == physics_vehicle_adjust_view)
		physics_plug_adjust_view = NULL;

	physics_player_ent = 0;
}

void(float isnew) physics_car_read {
	float f = ReadShort();
	if (isnew) {
		physics_plug = physics_car_hook;
		physics_plug_pre = physics_car_pre;
		physics_plug_post = physics_car_post;
		vehicle_adjust_view_up = CAR_VIEW_UP;
		vehicle_adjust_view_back = CAR_VIEW_BACK;
		vehicle_adjust_view_start_offs = CAR_VIEW_START_OFFSET;
		if not(physics_plug_adjust_view)
			physics_plug_adjust_view = physics_vehicle_adjust_view;

		self.entremove = physics_car_remove;
		physics_car_entity = self;
		physics_car_entity.solid = SOLID_BBOX;
		physics_car_entity.movetype = MOVETYPE_QCWALK;
		physics_car_entity.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
		setsize(physics_car_entity, car_MIN, car_MAX);
	}
	if (f & 1) {
		g_vehicle_car_speed_stop = ReadCoord();
		g_vehicle_car_speed = ReadCoord();
		g_vehicle_car_turnspeed = ReadCoord();
		g_vehicle_car_movement_inertia = ReadCoord();
		g_vehicle_car_speed_drift = ReadCoord();
		physics_player_ent = ReadShort();
	}
	if (f & 2) {
		physics_car_start_angles_x = ReadCoord();
		physics_car_start_angles_y = ReadCoord();
		physics_car_start_angles_z = ReadCoord();
		physics_car_start_origin_x = ReadCoord();
		physics_car_start_origin_y = ReadCoord();
		physics_car_start_origin_z = ReadCoord();
		physics_car_start_velocity_x = ReadCoord();
		physics_car_start_velocity_y = ReadCoord();
		physics_car_start_velocity_z = ReadCoord();
	}
}

