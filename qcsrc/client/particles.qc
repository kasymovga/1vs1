vector particles_point_in_brush_vec;
entity particles_point_in_brush_brush;

float(void) particles_point_in_brush_recursive {
	float s;
	entity se;
	float f;
	traceline(particles_point_in_brush_vec, particles_point_in_brush_vec, 0, world);
	if not(trace_ent)
		return 0;

	if(trace_ent == particles_point_in_brush_brush)
		return 1;

	se = trace_ent;
	s = se.solid;
	se.solid = SOLID_NOT;
	f = particles_point_in_brush_recursive();
	se.solid = s;
	return f;
}

float(entity brush, vector point) particles_point_in_brush {
	float f, s;
	if not(brush.modelindex)
		return 1;

	s = brush.solid;
	brush.solid = SOLID_BSP;
	particles_point_in_brush_vec = point;
	particles_point_in_brush_brush = brush;
	f = particles_point_in_brush_recursive();
	brush.solid = s;
	return f;
}

.float cnt; // effect number
.vector velocity; // particle velocity
.float count; // count multiplier
.float impulse; // density
.string noise; // sound
.float atten;
.float volume;
.float absolute; // 1 = count per second is absolute, 2 = only spawn at toggle

void(void) particles_point_draw {
	float n, i, fail;
	vector p;
	vector sz;
	vector o;
	o = self.origin;
	sz = self.maxs - self.mins;
	n = BGMScript(self);
	if (self.absolute == 2) {
		if(n >= 0)
			n = self.just_toggled ? self.impulse : 0;
		else
			n = self.impulse * view_drawframetime;
	} else {
		n *= self.impulse * view_drawframetime;
		if (self.just_toggled)
			if (n < 1)
				n = 1;
	}
	if (n == 0)
		return;

	fail = 0;
	for (i = random(); i <= n && fail <= 64*n; ++i) {
		p = o + self.mins;
		p_x += random() * sz_x;
		p_y += random() * sz_y;
		p_z += random() * sz_z;
		if (particles_point_in_brush(self, p)) {
			if (self.movedir != '0 0 0') {
				traceline(p, p + normalize(self.movedir) * 4096, 0, world);
				p = trace_endpos;
				pointparticles(self.cnt, p, trace_plane_normal * vlen(self.movedir) + self.velocity + randomvec() * self.waterlevel, self.count);
			} else {
				pointparticles(self.cnt, p, self.velocity + randomvec() * self.waterlevel, self.count);
			}
			if (self.noise != "") {
				self.origin = p;
				sound(self, CHAN_AUTO, self.noise, VOL_BASE * self.volume, self.atten);
			}
			self.just_toggled = 0;
		} else if(self.absolute) {
			++fail;
			--i;
		}
	}
	self.origin = o;
}

void(void) particles_point_remove {
	if(self.noise)
		strunzone(self.noise);

	self.noise = NULL;
	if(self.bgmscript)
		strunzone(self.bgmscript);

	self.bgmscript = NULL;
}

void(float ignore) particles_point_read {
	float f, i;
	vector v;
	f = net_read_byte();
	if (f & 2) {
		i = net_read_coord(); // density (<0: point, >0: volume)
		if(i && !self.impulse && self.cnt) // self.cnt check is so it only happens if the ent already existed
			self.just_toggled = 1;
		self.impulse = i;
	}
	if (f & 4) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
	}
	if (f & 1) {
		self.modelindex = net_read_short();
		if (f & 0x80) {
			if(self.modelindex) {
				self.mins_x = net_read_coord();
				self.mins_y = net_read_coord();
				self.mins_z = net_read_coord();
				self.maxs_x = net_read_coord();
				self.maxs_y = net_read_coord();
				self.maxs_z = net_read_coord();
			} else {
				self.mins    = '0 0 0';
				self.maxs_x = net_read_coord();
				self.maxs_y = net_read_coord();
				self.maxs_z = net_read_coord();
			}
		} else {
			self.mins = self.maxs = '0 0 0';
		}
		self.cnt = net_read_short(); // effect number
		if (f & 0x20) {
			self.velocity = net_decompress_vec(net_read_short());
			self.movedir = net_decompress_vec(net_read_short());
		} else {
			self.velocity = self.movedir = '0 0 0';
		}
		if (f & 0x40) {
			self.waterlevel = net_read_short() / 16.0;
			self.count = net_read_byte() / 16.0;
		} else {
			self.waterlevel = 0;
			self.count = 1;
		}
		if (self.noise)
			strunzone(self.noise);

		if (self.bgmscript)
			strunzone(self.bgmscript);

		self.noise = strzone(net_read_string());
		if (self.noise != "") {
			self.atten = net_read_byte() / 64.0;
			self.volume = net_read_byte() / 255.0;
		}
		self.bgmscript = strzone(net_read_string());
		if (self.bgmscript != "") {
			self.bgmscriptattack = net_read_byte() / 64.0;
			self.bgmscriptdecay = net_read_byte() / 64.0;
			self.bgmscriptsustain = net_read_byte() / 255.0;
			self.bgmscriptrelease = net_read_byte() / 64.0;
		}
		BGMScript_InitEntity(self);
	}
	if (f & 2) {
		self.absolute = (self.impulse >= 0);
		if (!self.absolute) {
			v = self.maxs - self.mins;
			self.impulse *= -v_x * v_y * v_z / 262144; // relative: particles per 64^3 cube
		}
	}
	if(f & 0x10)
		self.absolute = 2;

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	self.draw = particles_point_draw;
	self.entremove = particles_point_remove;
}

.float glow_color; // palette index
vector particles_snow_or_rain_mins, particles_snow_or_rain_maxs;
float particles_snow_or_rain_count;
void(float d) particles_snow_or_rain_set_bbox {
	particles_snow_or_rain_count = 0;
	if (time < self.cnt)
		return;

	self.cnt = max(time, self.cnt + 0.1);
	particles_snow_or_rain_mins = self.mins + self.origin;
	particles_snow_or_rain_maxs= self.maxs + self.origin;
	particles_snow_or_rain_mins_x = max(view_origin_x - d, particles_snow_or_rain_mins_x);
	particles_snow_or_rain_mins_y = max(view_origin_y - d, particles_snow_or_rain_mins_y);
	particles_snow_or_rain_maxs_x = min(view_origin_x + d, particles_snow_or_rain_maxs_x);
	particles_snow_or_rain_maxs_y = min(view_origin_y + d, particles_snow_or_rain_maxs_y);
	if (particles_snow_or_rain_mins_x >= particles_snow_or_rain_maxs_x)
		return;

	if (particles_snow_or_rain_mins_y >= particles_snow_or_rain_maxs_y)
		return;

	float skyz = view_origin_z + d * 0.5;
	if (particles_snow_or_rain_maxs_z > skyz) {
		tracebox('0 0 0', particles_snow_or_rain_mins, particles_snow_or_rain_maxs, '0 0 1' * (skyz - particles_snow_or_rain_maxs_z), TRACE_MOVE_WORLDONLY, world);
		particles_snow_or_rain_maxs = particles_snow_or_rain_maxs + trace_endpos;
		particles_snow_or_rain_mins = particles_snow_or_rain_mins + trace_endpos;
	}
	particles_snow_or_rain_count = self.count * (((particles_snow_or_rain_maxs_x - particles_snow_or_rain_mins_x) * (particles_snow_or_rain_maxs_y -
			particles_snow_or_rain_mins_y)) / ((self.maxs_x - self.mins_x) * (self.maxs_y - self.mins_x))) * 0.1;
}

void(void) particles_rain_draw {
	particles_snow_or_rain_set_bbox(CVAR(cl_particles_rain_distance));
	if (particles_snow_or_rain_count)
		te_particlerain(particles_snow_or_rain_mins, particles_snow_or_rain_maxs, self.velocity, particles_snow_or_rain_count, self.glow_color);
}

void(void) particles_snor_draw {
	particles_snow_or_rain_set_bbox(CVAR(cl_particles_snow_distance));
	if (particles_snow_or_rain_count)
		te_particlesnow(particles_snow_or_rain_mins, particles_snow_or_rain_maxs, self.velocity, particles_snow_or_rain_count, self.glow_color);
}

void(float ignore) particles_rain_or_snow_read {
	self.impulse = net_read_byte(); // Rain, Snow, or Whatever
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.maxs_x = net_read_coord();
	self.maxs_y = net_read_coord();
	self.maxs_z = net_read_coord();
	self.velocity = net_decompress_vec(net_read_short());
	self.count = net_read_short() * 10;
	self.glow_color = net_read_byte(); // color
	self.mins    = -0.5 * self.maxs;
	self.maxs    =  0.5 * self.maxs;
	self.origin  = self.origin - self.mins;
	self.cnt = 0;
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	if (self.impulse)
		self.draw = particles_rain_draw;
	else
		self.draw = particles_snor_draw;
}

entity particles_zcurve_entity;
void particles_zcurve(float effectnum, vector start, vector end, float end_dz, float speed, float depth) {
	// end_dz:
	//   IF IT WERE A STRAIGHT LINE, it'd end end_dz above end
	vector mid;
	mid = (start + end) * 0.5;
	end_dz *= 0.25;
	mid_z += end_dz;
	--depth;
	if(depth < 0 || normalize(mid - start) * normalize(end - start) > 0.999999) {
		// TODO make this a variable threshold
		// currently: 0.081 degrees
		// 0.99999 would be 0.256 degrees and is visible
		particles_zcurve_entity.velocity = speed * normalize(end - start);
		trailparticles(particles_zcurve_entity, effectnum, start, end);
	} else {
		particles_zcurve(effectnum, start, mid, end_dz, speed, depth);
		particles_zcurve(effectnum, mid, end, end_dz, speed, depth);
	}
}

void(void) particles_zcurve_read {
	vector start, end;
	float end_dz;
	float effectnum, speed;
	if (!particles_zcurve_entity) {
		particles_zcurve_entity = spawn();
		particles_zcurve_entity.classname = "zcurve";
	}
	effectnum = net_read_short();
	start_x = net_read_coord();
	start_y = net_read_coord();
	start_z = net_read_coord();
	do {
		end_x = net_read_coord();
		end_y = net_read_coord();
		end_z = net_read_coord();
		end_dz = net_read_coord();
		speed = net_read_short();
		particles_zcurve(effectnum, start, end, end_dz, 16 * (speed & 0x7FFF), 5); // at most 32 segments
	} while(!(speed & 0x8000));
}

void(void) particles_nex_beam_read {
	vector shotorg, endpos;
	shotorg_x = net_read_coord(); shotorg_y = net_read_coord(); shotorg_z = net_read_coord();
	endpos_x = net_read_coord(); endpos_y = net_read_coord(); endpos_z = net_read_coord();
	pointparticles(particleeffectnum("nex_muzzleflash"), shotorg, normalize(endpos - shotorg) * 1000, 1);
	//draw either the old v2.3 beam or the new beam
	if (CVAR(cl_particles_oldnexbeam))
		trailparticles(world, particleeffectnum("TE_TEI_G3"), shotorg, endpos);
	else
		trailparticles(world, particleeffectnum("nex_beam"), shotorg, endpos);
}

#define particles_rm_effectnum_team(p,t,d) particleeffectnum(strcat(p "_TEAM", ftos(team_index_def(t, d))))
