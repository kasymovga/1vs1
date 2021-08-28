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
	physics_plug_pre = NULL;
	physics_plug = NULL;
	physics_plug_post = NULL;
	if (physics_plug_adjust_view == physics_vehicle_adjust_view)
		physics_plug_adjust_view = NULL;

	physics_player_ent = 0;
}

void(float isnew) physics_car_read {
	float f = net_read_short();
	if (isnew) {
		physics_plug = physics_car_hook;
		physics_plug_pre = physics_car_pre;
		physics_plug_post = physics_car_post;
		if not(physics_plug_adjust_view)
			physics_plug_adjust_view = physics_vehicle_adjust_view;

		self.entremove = physics_car_remove;
		physics_car_entity = self;
		physics_car_entity.solid = SOLID_BBOX;
		physics_car_entity.movetype = MOVETYPE_QCWALK;
		physics_car_entity.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	}
	if (f & 1) {
		physics_vehicle_read_common();
		g_vehicle_car_speed_stop = net_read_coord();
		g_vehicle_car_speed = net_read_coord();
		g_vehicle_car_turnspeed = net_read_coord();
		g_vehicle_car_movement_inertia = net_read_coord();
		g_vehicle_car_speed_drift = net_read_coord();
		physics_player_ent = net_read_short();
		g_vehicle_car_align = net_read_byte();
	}
	if (f & 2) {
		physics_car_start_angles_x = net_read_coord();
		physics_car_start_angles_y = net_read_coord();
		physics_car_start_angles_z = net_read_coord();
		physics_car_start_origin_x = net_read_coord();
		physics_car_start_origin_y = net_read_coord();
		physics_car_start_origin_z = net_read_coord();
		physics_car_start_velocity_x = net_read_coord();
		physics_car_start_velocity_y = net_read_coord();
		physics_car_start_velocity_z = net_read_coord();
	}
}

