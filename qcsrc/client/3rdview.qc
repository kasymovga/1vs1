float thirdview_save_back;
float thirdview_save_up;
float thirdview_save_chase;
entity thirdview_restore;
void(float ignore, float f) thirdview_read {
	float back = ReadShort();
	float up = ReadShort();
	float t = ReadCoord();
	if not(thirdview_restore) {
		thirdview_restore = spawn();
		thirdview_save_back = CVAR(chase_back);
		thirdview_save_up = CVAR(chase_up);
		thirdview_save_chase = CVAR(chase_active);
		thirdview_restore.think = inline void(void) {
			cvar_set("chase_active", ftos(thirdview_save_chase));
			CVAR(chase_active) = thirdview_save_chase;
			cvar_set("chase_back", ftos(thirdview_save_back));
			CVAR(chase_back) = thirdview_save_back;
			cvar_set("chase_up", ftos(thirdview_save_up));
			CVAR(chase_up) = thirdview_save_up;
			remove(self);
			thirdview_restore = world;
		};
	}
	thirdview_restore.nextthink = time + t;
	cvar_set("chase_active", "1");
	CVAR(chase_active) = 1;
	cvar_set("chase_back", ftos(back));
	CVAR(chase_back) = back;
	cvar_set("chase_up", ftos(up));
	CVAR(chase_up) = up;
}
