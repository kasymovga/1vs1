float view_camera_script_active;
entity view_camera_script_current;
entity view_camera_script_chain;
float view_camera_script_position;
float view_camera_script_speed;
float view_camera_script_wait;

void(void) view_camera_script {
	if (!view_camera_script_current || !view_camera_script_current.enemy) {
		if (view_camera_script_current) {
			R_SetView(VF_ANGLES, view_camera_script_current.angles);
			R_SetView(VF_ORIGIN, view_camera_script_current.origin);
		}
		if (view_camera_script_wait >= 0) {
			view_camera_script_wait -= frametime;
		} else {
			view_camera_script_active = FALSE;
			cvar_set("camera_enable", "0");
		}
		return;
	}
	entity p1 = view_camera_script_current;
	entity p2 = view_camera_script_current.enemy;
	while (p1.angles_x - p2.angles_x < -180) p2.angles_x -= 360;
	while (p1.angles_x - p2.angles_x > 180) p2.angles_x += 360;
	while (p1.angles_y - p2.angles_y < -180) p2.angles_y -= 360;
	while (p1.angles_y - p2.angles_y > 180) p2.angles_y += 360;
	while (p1.angles_z - p2.angles_z < -180) p2.angles_z -= 360;
	while (p1.angles_z - p2.angles_z > 180) p2.angles_z += 360;
	vector a = p1.angles * (1 - view_camera_script_position) + p2.angles * view_camera_script_position;
	vector o = p1.origin * (1 - view_camera_script_position) + p2.origin * view_camera_script_position;
	R_SetView(VF_ANGLES, a);
	R_SetView(VF_ORIGIN, o);
	float spd = (p1.cnt ? p1.cnt : view_camera_script_speed);
	if (view_camera_script_position >= 1) {
		view_camera_script_current = p2;
		view_camera_script_position = 0;
		if (p2)
			view_camera_script_wait = p2.float1;
	} else {
		if (view_camera_script_wait >= 0)
			view_camera_script_wait -= frametime;
		else
			view_camera_script_position = bound(0, view_camera_script_position + (spd * frametime) / vlen(p1.origin - p2.origin), 1);
	}
}

void(void) view_camera_script_cmd_help {
	print("Usage:\n"
			"cl_cmd camera_script play [speed]\n"
			"                     stop\n"
			"                     add [speed] [roll] [wait]\n"
			"                     clear\n"
			"                     save <name>\n"
			"                     load <name>\n"
			);
}

void(void) view_camera_script_clear {
	entity e;
	while (view_camera_script_chain) {
		e = view_camera_script_chain.enemy;
		remove(view_camera_script_chain);
		view_camera_script_chain = e;
	}
}

void(float argc) view_camera_script_cmd {
	if (argc < 2) {
		view_camera_script_cmd_help();
		return;
	}
	entity e;
	string s = argv(1);
	float f;
	if (s == "play" && argc <= 3) {
		if (!view_camera_script_chain || !view_camera_script_chain.enemy) {
			print("nothing to play\n");
		} else {
			view_camera_script_current = view_camera_script_chain;
			view_camera_script_position = 0;
			view_camera_script_active = TRUE;
			view_camera_script_wait = view_camera_script_current.float1;
			cvar_set("camera_enable", "1");
		}
		if (argc >= 3)
			view_camera_script_speed = stof(argv(2));
		else
			view_camera_script_speed = 400;
	} else if (s == "stop" && argc == 2) {
		if not(view_camera_script_active) {
			print("nothing to stop\n");
		} else {
			view_camera_script_active = FALSE;
			cvar_set("camera_enable", "0");
		}
	} else if (s == "add" && argc <= 5) {
		if (view_camera_script_active) {
			print("can't add while playing script\n");
			return;
		}
		e = spawn();
		e.angles = view_camera_angles;
		e.origin = view_origin;
		if (argc >= 3)
			e.cnt = stof(argv(2));

		if (argc >= 4)
			e.angles_z = stof(argv(3));

		if (argc >= 5)
			e.float1 = stof(argv(4));

		if not(view_camera_script_chain)
			view_camera_script_chain = e;
		else {
			entity e2;
			for (e2 = view_camera_script_chain; e2.enemy; e2 = e2.enemy);
			e2.enemy = e;
		}
	} else if (s == "clear" && argc == 2) {
		if (view_camera_script_active) {
			print("can't clear while playing script\n");
			return;
		}
		view_camera_script_clear();
	} else if (s == "save" && argc == 3) {
		s = strcat(argv(2), ".csc");
		f = fopen(s, FILE_WRITE);
		if (f >= 0) {
			for (e = view_camera_script_chain; e; e = e.enemy) {
				fputs(f, strcat(ftos(e.origin_x), " "));
				fputs(f, strcat(ftos(e.origin_y), " "));
				fputs(f, strcat(ftos(e.origin_z), " "));
				fputs(f, strcat(ftos(e.angles_x), " "));
				fputs(f, strcat(ftos(e.angles_y), " "));
				fputs(f, strcat(ftos(e.angles_z), " "));
				fputs(f, strcat(ftos(e.cnt/*speed*/), " "));
				fputs(f, strcat(ftos(e.float1/*wait*/), "\n"));
			}
			fclose(f);
		} else
			print("Can't open file: ", s, "\n");
	} else if (s == "load" && argc == 3) {
		view_camera_script_clear();
		s = strcat(argv(2), ".csc");
		f = fopen(s, FILE_READ);
		if (f >= 0) {
			while ((s = fgets(f))) {
				e = spawn();
				argc = tokenize_console(s);
				if (argc < 8) {
					print("not enough arguments in line\n");
					break;
				}
				e.origin_x = stof(argv(0));
				e.origin_y = stof(argv(1));
				e.origin_z = stof(argv(2));
				e.angles_x = stof(argv(3));
				e.angles_y = stof(argv(4));
				e.angles_z = stof(argv(5));
				e.cnt = stof(argv(6));
				e.float1 = stof(argv(7));
				if not(view_camera_script_chain)
					view_camera_script_chain = e;
				else {
					entity e2;
					for (e2 = view_camera_script_chain; e2.enemy; e2 = e2.enemy);
					e2.enemy = e;
				}
			}
			fclose(f);
		} else
			print("Can't open file: ", s, "\n");
	} else {
		view_camera_script_cmd_help();
	}
}
