entity physics_spiderbot_entity;
vector physics_spiderbot_start_angles;
vector physics_spiderbot_start_origin;
vector physics_spiderbot_start_velocity;

float(void) physics_spiderbot_hook {
	entity e = self;
	self = physics_spiderbot_entity;
	physics_spiderbot();
	self = e;
	return 1;
}

void(void) physics_spiderbot_pre {
	setorigin(physics_spiderbot_entity, physics_spiderbot_start_origin);
	physics_spiderbot_entity.velocity = physics_spiderbot_start_velocity;
	physics_spiderbot_entity.angles = physics_spiderbot_start_angles;
}

void(void) physics_spiderbot_post {
	physics_vehicle_common_post(physics_spiderbot_entity);
}

void(void) physics_spiderbot_remove {
	physics_spiderbot_entity = world;
	physics_plug_pre = NULL;
	physics_plug = NULL;
	physics_plug_post = NULL;
	if (physics_plug_adjust_view == physics_vehicle_adjust_view)
		physics_plug_adjust_view = NULL;

	physics_player_ent = 0;
}

void(float isnew) physics_spiderbot_read {
	float f = net_read_short();
	if (isnew) {
		physics_plug = physics_spiderbot_hook;
		physics_plug_pre = physics_spiderbot_pre;
		physics_plug_post = physics_spiderbot_post;
		if not(physics_plug_adjust_view)
			physics_plug_adjust_view = physics_vehicle_adjust_view;

		self.entremove = physics_spiderbot_remove;
		physics_spiderbot_entity = self;
		physics_spiderbot_entity.solid = SOLID_BBOX;
		physics_spiderbot_entity.movetype = MOVETYPE_QCWALK;
		physics_spiderbot_entity.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	}
	if (f & 1) {
		physics_vehicle_read_common();
		g_vehicle_spiderbot_jump_accel = net_read_coord();
		g_vehicle_spiderbot_jump_up = net_read_coord();
		g_vehicle_spiderbot_speed_stop = net_read_coord();
		g_vehicle_spiderbot_speed_strafe = net_read_coord();
		g_vehicle_spiderbot_speed_walk = net_read_coord();
		g_vehicle_spiderbot_turnspeed = net_read_coord();
		g_vehicle_spiderbot_movement_inertia = net_read_coord();
		physics_player_ent = net_read_short();
	}
	if (f & 2) {
		physics_spiderbot_start_angles_x = net_read_coord();
		physics_spiderbot_start_angles_y = net_read_coord();
		physics_spiderbot_start_angles_z = net_read_coord();
		physics_spiderbot_start_origin_x = net_read_coord();
		physics_spiderbot_start_origin_y = net_read_coord();
		physics_spiderbot_start_origin_z = net_read_coord();
		physics_spiderbot_start_velocity_x = net_read_coord();
		physics_spiderbot_start_velocity_y = net_read_coord();
		physics_spiderbot_start_velocity_z = net_read_coord();
	}
}
