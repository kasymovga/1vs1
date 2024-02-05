entity camera;

vector(void) camera_adjust_view {
	if (camera)
		return camera.origin;

	return view_origin;
}

void(void) camera_draw {
	if not(CVAR(chase_active))
		cvar_set("chase_active", "1");

	view_fixangle = 1;
	view_fixed_angles = self.angles;
	physics_plug_adjust_view = camera_adjust_view;
	view_crosshair = FALSE;
}

void(void) camera_remove {
	camera = find(NULL, classname, "camera"); //maybe other camera available
	cvar_set("chase_active", "0");
	if (physics_plug_adjust_view == camera_adjust_view)
		physics_plug_adjust_view = NULL;
}

void(float ignore) camera_read {
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.angles_x = net_read_coord();
	self.angles_y = net_read_coord();
	self.angles_z = net_read_coord();
	self.draw = camera_draw;
	self.entremove = camera_remove;
	self.classname = "camera";
	camera = self;
	physics_plug_adjust_view = camera_adjust_view;
}

void(void) camera_shutdown {
	if (find(NULL, classname, "camera")) {
		cvar_set("chase_active", "0");
	}
}
