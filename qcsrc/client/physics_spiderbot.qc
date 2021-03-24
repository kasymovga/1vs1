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
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	if (physics_plug_adjust_view == physics_vehicle_adjust_view)
		physics_plug_adjust_view = NULL;

	physics_player_ent = 0;
}

void(float isnew) physics_spiderbot_read {
	float f = ReadShort();
	if (isnew) {
		physics_plug = physics_spiderbot_hook;
		physics_plug_pre = physics_spiderbot_pre;
		physics_plug_post = physics_spiderbot_post;
		vehicle_adjust_view_up = SPIDERBOT_VIEW_UP;
		vehicle_adjust_view_back = SPIDERBOT_VIEW_BACK;
		vehicle_adjust_view_start_offs = SPIDERBOT_VIEW_START_OFFSET;
		if not(physics_plug_adjust_view)
			physics_plug_adjust_view = physics_vehicle_adjust_view;

		self.entremove = physics_spiderbot_remove;
		physics_spiderbot_entity = self;
		physics_spiderbot_entity.solid = SOLID_BBOX;
		physics_spiderbot_entity.movetype = MOVETYPE_QCWALK;
		physics_spiderbot_entity.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
		setsize(physics_spiderbot_entity, spiderbot_MIN, spiderbot_MAX);
	}
	if (f & 1) {
		g_vehicle_spiderbot_jump_accel = ReadCoord();
		g_vehicle_spiderbot_jump_up = ReadCoord();
		g_vehicle_spiderbot_speed_stop = ReadCoord();
		g_vehicle_spiderbot_speed_strafe = ReadCoord();
		g_vehicle_spiderbot_speed_walk = ReadCoord();
		g_vehicle_spiderbot_turnspeed = ReadCoord();
		g_vehicle_spiderbot_movement_inertia = ReadCoord();
		physics_player_ent = ReadShort();
	}
	if (f & 2) {
		physics_spiderbot_start_angles_x = ReadCoord();
		physics_spiderbot_start_angles_y = ReadCoord();
		physics_spiderbot_start_angles_z = ReadCoord();
		physics_spiderbot_start_origin_x = ReadCoord();
		physics_spiderbot_start_origin_y = ReadCoord();
		physics_spiderbot_start_origin_z = ReadCoord();
		physics_spiderbot_start_velocity_x = ReadCoord();
		physics_spiderbot_start_velocity_y = ReadCoord();
		physics_spiderbot_start_velocity_z = ReadCoord();
	}
}
