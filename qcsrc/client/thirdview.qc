entity thirdview_restore;

vector(void) thirdview_adjust_view {
	return chase_adjust_view(thirdview_restore.origin_x, thirdview_restore.origin_y);
}

void(void) thirdview_restore_think {
	chase_unlock();
	if (physics_plug_adjust_view == thirdview_adjust_view)
		physics_plug_adjust_view = NULL;

	remove(self);
	thirdview_restore = NULL;
}

void(float ignore) thirdview_read {
	float back = net_read_short();
	float up = net_read_short();
	float t = net_read_coord();
	if not(thirdview_restore) {
		thirdview_restore = spawn();
		thirdview_restore.think = thirdview_restore_think;
		chase_lock();
	}
	thirdview_restore.nextthink = time + t;
	thirdview_restore.origin_x = back;
	thirdview_restore.origin_y = up;
	if not(physics_plug_adjust_view)
		physics_plug_adjust_view = thirdview_adjust_view;

}

void(void) thirdview_shutdown {
	if (thirdview_restore) {
		entity oldself = self;
		self = thirdview_restore;
		self.think();
		self = oldself;
	}
}
