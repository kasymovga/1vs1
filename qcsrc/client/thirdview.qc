float thirdview_save_back;
float thirdview_save_up;
float thirdview_save_chase;
entity thirdview_restore;
void(void) thirdview_restore_think {
	cvar_set("chase_active", ftos(thirdview_save_chase));
	CVAR(chase_active) = thirdview_save_chase;
	cvar_set("chase_back", ftos(thirdview_save_back));
	CVAR(chase_back) = thirdview_save_back;
	cvar_set("chase_up", ftos(thirdview_save_up));
	CVAR(chase_up) = thirdview_save_up;
	remove(self);
	thirdview_restore = world;
}

void(float ignore) thirdview_read {
	float back = net_read_short();
	float up = net_read_short();
	float t = net_read_coord();
	if not(thirdview_restore) {
		thirdview_restore = spawn();
		thirdview_save_back = CVAR(chase_back);
		thirdview_save_up = CVAR(chase_up);
		thirdview_save_chase = CVAR(chase_active);
		thirdview_restore.think = thirdview_restore_think;
	}
	thirdview_restore.nextthink = time + t;
	cvar_set("chase_active", "1");
	CVAR(chase_active) = 1;
	cvar_set("chase_back", ftos(back));
	CVAR(chase_back) = back;
	cvar_set("chase_up", ftos(up));
	CVAR(chase_up) = up;
}
