
.vector zapper_shotorg;
.float zapper_akimbo;

vector(float t) zapper_beam_rgb {
    switch(t) {
	case COLOR_TEAM1:            return '5.0   1.0   0.5';
	case COLOR_TEAM2: default:   return '0.5   1.0   5.0';
	case COLOR_TEAM3:            return '4.0   2.5   0.5';
	case COLOR_TEAM4:            return '5.0   0.7   3.0';
    }
}

float zapper_beam_width;
float zapper_particles_trace_callback_beamoffs;

void zapper_particles_trace_callback(vector from, vector to, vector ignore) {
    vector rgb = zapper_beam_rgb(self.team);
    string tex = "particles/zapper";
    float t = self.cnt + time;
    float _alpha = self.alpha;
    rgb *= _alpha;
	draw_cylindric_line(from, to, zapper_beam_width, tex, 0.03, zapper_particles_trace_callback_beamoffs, rgb, _alpha, DRAWFLAG_ADDITIVE, warpzone_find_nearest_origin((from + to) * 0.5, view_camera_origin, FALSE));
    zapper_particles_trace_callback_beamoffs += 0.03 * vlen(from - to) / zapper_beam_width;

}

void(void) zapper_interpolate {
	InterpolateOrigin_Do();
	if (CVAR(chase_active) && !view_spectatee_status && self.sv_entnum == player_localentnum)
		self.enemy.origin = self.enemy.iorigin2 + (physics_end_origin - physics_start_origin);
	else {
		entity e = self;
		self = self.enemy;
		InterpolateOrigin_Do();
		self = e;
	}
}

void(void) zapper_draw {
    vector start, real_start;
	vector end;
    float me = ((view_spectatee_status > 0) ? view_spectatee_status : player_localentnum);
    float first_person = FALSE;
    zapper_beam_width = 12;
	vector zapper_shotorigin = self.zapper_shotorg;
    if (self.sv_entnum == me) {
		if not(CVAR(chase_active)) {
			view_camera_correction_needed = TRUE;
			start = view_origin + view_forward * zapper_shotorigin_x + view_right * zapper_shotorigin_y + view_up * zapper_shotorigin_z;
			zapper_beam_width = 8;
			first_person = TRUE;
			if (self.zapper_akimbo)
				end = (start + view_forward * (vlen(start - self.origin)));
			else
				end = (view_origin + view_forward * (vlen(start - self.origin)));

			real_start = view_origin;
		} else {
			zapper_interpolate();
			end = self.origin;
			start = self.enemy.origin;
			real_start = start;
		}
    } else {
		zapper_interpolate();
        end = self.origin;
		real_start = start = self.enemy.origin;
	}
    zapper_particles_trace_callback_beamoffs = -time * 5;
    vector dynlight_org = start;
    if (first_person) {
        dynlight_org = start + view_forward;
        zapper_particles_trace_callback(start - view_forward * zapper_shotorigin_x, start, start);
    }
    //R_AddDynamicLight(dynlight_org, 50 * self.alpha, zapper_beam_rgb(self.team));
	warpzone_draw_effect_triangle(real_start, start, end, zapper_particles_trace_callback);
	//zapper_particles_trace_callback(self.zapper_start, end);
	vector v = warpzone_transform_velocity(warpzone_trace_transform, normalize(end - start));
	end = warpzone_transform_origin(warpzone_trace_transform, end);
	end = end - v;
    pointparticles(particles_rm_effectnum_team("RM_ZAPPER", self.team, 2), end, v, frametime * 300);
	pointparticles(particles_rm_effectnum_team("RM_ZAPPER_MUZZLEFLASH", self.team, 2), start, '0 0 0', frametime * 300);
}

void(void) zapper_draw_shield {
    float me = ((view_spectatee_status > 0) ? view_spectatee_status : player_localentnum);
	vector start, end;
	if (!CVAR(chase_active) && self.sv_entnum == me) {
        vector zapper_shotorigin = self.zapper_shotorg;
        start = view_origin + view_forward * (zapper_shotorigin_x - 1) + view_right * zapper_shotorigin_y + view_up * zapper_shotorigin_z;
		end = start + view_forward * 30;
    } else {
		zapper_interpolate();
		start = self.enemy.origin;
		end = self.origin;
	}
    string tex = "particles/zapper";
    vector rgb = zapper_beam_rgb(self.team) * 0.5;
	draw_cylindric_line(end, start,  12, tex, 0.03, 5 * time, rgb, self.alpha, DRAWFLAG_ADDITIVE, view_origin);
    if (self.alpha < 1)
        return;

    float eff_zap = particles_rm_effectnum_team("RM_ZAPPER", self.team, 2);
    float eff_muz = particles_rm_effectnum_team("RM_ZAPPER_MUZZLEFLASH", self.team, 2);
    float pcount = frametime * 300;
    pointparticles(eff_zap, end, '0 0 0', pcount);
    pointparticles(eff_muz, start, end - start, pcount);
}

.float snd_looping;
void Zapper_Remove(void) {
	if (self.enemy) {
		remove(self.enemy);
		self.enemy = world;
	}
    sound(self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);
}

void(float t) zapper_read {
    float sf = ReadByte();
    if (sf & 1) {
        float vol, attn;
		vol = VOL_BASE;
		attn = ATTN_NORM;
        if (t == NET_CSQC_ZAPPER_SHIELD) {
            self.draw = zapper_draw_shield;
            dlc_sound(self, CHAN_PROJECTILE, "weapons/zapper_shield_loop.wav", 1, attn);
        } else {
            self.draw = zapper_draw;
            dlc_sound(self, CHAN_PROJECTILE, "weapons/zapper_fly.wav", vol, attn);
        }
		if not(self.enemy)
			self.enemy = spawn();

        self.entremove = Zapper_Remove;
        if (sf & 16) {
            self.sv_entnum = 0;
            self.team = ReadByte();
        } else {
            self.sv_entnum = ReadByte();
            self.team = player_color(self.sv_entnum - 1);
        }
        self.alpha = 1;
        self.cnt = random() * 1000;
    }
    if (sf & 2) {
		entity e = self;
		if not(self.enemy)
			self.enemy = spawn();

		self = self.enemy;
        self.origin_x = ReadCoord();
        self.origin_y = ReadCoord();
        self.origin_z = ReadCoord();
        InterpolateOrigin_Note();
		if (sf & 64)
			InterpolateOrigin_Note();

		self = e;
    }
    if (sf & 4) {
        self.origin_x = ReadCoord();
        self.origin_y = ReadCoord();
        self.origin_z = ReadCoord();
        InterpolateOrigin_Note();
		if (sf & 64)
			InterpolateOrigin_Note();
    }
	if (sf & 8) {
		self.zapper_akimbo = 1;
	} else
		self.zapper_akimbo = 0;

	if (sf & 32) {
		self.zapper_shotorg_x = ReadCoord();
		self.zapper_shotorg_y = ReadCoord();
		self.zapper_shotorg_z = ReadCoord();
	}
}

void zapper_beam_read(float ignore) {
	zapper_read(NET_CSQC_ZAPPER);
}

void(float ignore) zapper_shield_read {
	zapper_read(NET_CSQC_ZAPPER_SHIELD);
}

void zapper_lightning_arc_draw(void) {
    string tex;
    switch(self.team) {
	case COLOR_TEAM1: tex = "particles/hook_red";       break;
	case COLOR_TEAM2: tex = "particles/hook_blue";      break;
	case COLOR_TEAM3: tex = "particles/hook_yellow";    break;
	case COLOR_TEAM4: tex = "particles/hook_pink";      break;
	default         : tex = "particles/hook_green";     break;
    }
    float i; for(i = 0; i < 5; ++i)
		draw_cylindric_line(self.origin, self.velocity, 25 * self.alpha, tex, 0.02, random(), '1 1 1', self.alpha, DRAWFLAG_ADDITIVE, view_origin);

    self.alpha = self.alpha - frametime * 3;
    if (self.alpha < 0)
        remove(self);
}

void zapper_lightning_arc_segment(vector start, vector end, float ateam) {
    entity e = spawn();
    e.alpha = 1;
    e.origin = start;
    e.velocity = end;
    e.draw = zapper_lightning_arc_draw;
    e.team = ateam;
    trailparticles(world, particles_rm_effectnum_team("RM_LIGHTNING", ateam, 2), start, end);
}

void(void) zapper_lightning_read {
    vector from, to;
    float zapper_lightning_ateam  = ReadByte();
    from_x = ReadCoord(); from_y = ReadCoord(); from_z = ReadCoord();
    to_x   = ReadCoord(); to_y   = ReadCoord(); to_z   = ReadCoord();
    //if(!rm_teamlasers)
    //    zapper_lightning_ateam = COLOR_TEAM2;

    pointparticles(particles_rm_effectnum_team("RM_HG_PLASMA_SHARD_EXPLODE", zapper_lightning_ateam, 2), to, '0 0 0', 1);
    zapper_lightning_arc_segment(from, to, zapper_lightning_ateam);
    pointparticles(particleeffectnum("electro_muzzleflash"), from, normalize(to - from) * 1000, 1);
}
