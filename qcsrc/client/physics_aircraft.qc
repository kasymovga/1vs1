entity physics_aircraft_entity;
vector physics_aircraft_start_angles;
vector physics_aircraft_start_origin;
vector physics_aircraft_start_velocity;

float(void) physics_aircraft_hook {
	entity e = self;
	self = physics_aircraft_entity;
	physics_aircraft();
	self = e;
	return 1;
}

void(void) physics_aircraft_pre {
	setorigin(physics_aircraft_entity, physics_aircraft_start_origin);
	physics_aircraft_entity.velocity = physics_aircraft_start_velocity;
	physics_aircraft_entity.angles = physics_aircraft_start_angles;
}

void(void) physics_aircraft_post {
	physics_vehicle_common_post(physics_aircraft_entity);
}

void(void) physics_aircraft_remove {
	physics_aircraft_entity = world;
	physics_plug_pre = NULL;
	physics_plug = NULL;
	physics_plug_post = NULL;
	if (physics_plug_adjust_view == physics_vehicle_adjust_view)
		physics_plug_adjust_view = NULL;

	physics_player_ent = 0;
}

void(float isnew) physics_aircraft_read {
	float f = net_read_short();
	if (isnew) {
		physics_plug = physics_aircraft_hook;
		physics_plug_pre = physics_aircraft_pre;
		physics_plug_post = physics_aircraft_post;
		if not(physics_plug_adjust_view)
			physics_plug_adjust_view = physics_vehicle_adjust_view;

		self.entremove = physics_aircraft_remove;
		physics_aircraft_entity = self;
		physics_aircraft_entity.solid = SOLID_BBOX;
		physics_aircraft_entity.movetype = MOVETYPE_QCWALK;
		physics_aircraft_entity.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	}
	if (f & 1) {
		physics_vehicle_read_common();
		g_vehicle_aircraft_accel_up = net_read_coord();
		g_vehicle_aircraft_speed = net_read_coord();
		g_vehicle_aircraft_speed_stop = net_read_coord();
		g_vehicle_aircraft_turnspeed = net_read_coord();
		g_vehicle_aircraft_movement_inertia = net_read_coord();
		physics_player_ent = net_read_short();
	}
	if (f & 2) {
		physics_aircraft_start_angles_x = net_read_coord();
		physics_aircraft_start_angles_y = net_read_coord();
		physics_aircraft_start_angles_z = net_read_coord();
		physics_aircraft_start_origin_x = net_read_coord();
		physics_aircraft_start_origin_y = net_read_coord();
		physics_aircraft_start_origin_z = net_read_coord();
		physics_aircraft_start_velocity_x = net_read_coord();
		physics_aircraft_start_velocity_y = net_read_coord();
		physics_aircraft_start_velocity_z = net_read_coord();
	}
}
