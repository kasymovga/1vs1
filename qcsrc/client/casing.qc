.float silent;
float casing_count;
entity casing_latest;
entity casing_oldest;

void(void) casing_delete {
	if (self == casing_oldest)
		casing_oldest = self.sort_next;

	if (self == casing_latest)
		casing_latest = self.sort_prev;

	if (self.sort_next)
		self.sort_next.sort_prev = self.sort_prev;

	if (self.sort_prev)
		self.sort_prev.sort_next = self.sort_next;

    remove(self);
	casing_count--;
}

void(void) casing_draw {
	if (self.move_flags & FL_ONGROUND) {
		self.move_angles_x = 0;
		self.move_angles_z = 0;
		self.flags &= ~FL_ONGROUND;
	}
	physics_move_no_match_server();
	self.renderflags = 0;
	self.alpha = bound(0, self.cnt - time, 1);
	if (self.alpha < EFFECT_ALPHA_MIN_VISIBLE)
		casing_delete();
	else
		R_AddEntity(self);
}

void(void) casing_touch {
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) {
		self.cnt = time;
		return;
	}
	if (!self.silent)
	if (!trace_ent || trace_ent.solid == SOLID_BSP) {
		if (vlen(self.velocity) > 50) {
			if (time >= self.nextthink) {
				string s;
				float f;
				f = floor(prandom() * 3) + 1;
				switch (self.state) {
				case 1:
					s = strcat("weapons/casings", ftos(f), ".wav");
					break;
				default:
					s = strcat("weapons/brass", ftos(f), ".wav");
					break;
				}
				sound (self, CHAN_PROJECTILE, s, VOL_BASE, ATTN_NORM);
			}
		}
	}
	self.nextthink = time + 0.2;
}

void(void) casing_read {
	entity casing = spawn();
	casing.classname= "casing";
	casing.state = net_read_byte();
	casing.silent = (casing.state & 0x80);
	casing.state = (casing.state & 0x7F);
	casing.origin_x = net_read_coord();
	casing.origin_y = net_read_coord();
	casing.origin_z = net_read_coord();
	casing.velocity = net_decompress_vec(net_read_short());
	casing.angles_x = net_read_byte() * 360 / 256;
	casing.angles_y = net_read_byte() * 360 / 256;
	casing.angles_z = net_read_byte() * 360 / 256;
	if (CVAR(cl_casings) && CVAR(cl_casings_maxcount)) {
		if not(casing_oldest)
			casing_oldest = casing;

		if (casing_latest)
			casing_latest.sort_next = casing;

		casing.sort_prev = casing_latest;
		casing_latest = casing;
		casing_count++;
		casing.draw = casing_draw;
		casing.move_origin = casing.origin;
		casing.move_velocity = casing.velocity + 2 * prandomvec();
		casing.move_angles = casing.angles;
		casing.move_avelocity = '0 250 0' + 100 * prandomvec();
		casing.move_movetype = MOVETYPE_BOUNCE;
		casing.move_touch = casing_touch;
		casing.move_time = time;
		casing.solid = SOLID_TRIGGER;
		switch (casing.state) {
		case 1:
			setmodel(casing, "models/casing_shell.mdl");
			casing.cnt = time + CVAR(cl_casings_shell_time);
			break;
		default:
			setmodel(casing, "models/casing_bronze.mdl");
			casing.cnt = time + CVAR(cl_casings_bronze_time);
			break;
		}
		setsize(casing, '0 0 -1', '0 0 -1');
	} else
        remove(casing);

	if (casing_count > CVAR(cl_casings_maxcount)) {
		entity oldself = self;
		self = casing_oldest;
		casing_delete();
		self = oldself;
	}
}

void(void) casing_precache {
	precache_model("models/casing_shell.mdl");
	precache_model("models/casing_bronze.mdl");
	precache_sound("weapons/brass1.wav");
	precache_sound("weapons/brass2.wav");
	precache_sound("weapons/brass3.wav");
	precache_sound("weapons/casings1.wav");
	precache_sound("weapons/casings2.wav");
	precache_sound("weapons/casings3.wav");
}
