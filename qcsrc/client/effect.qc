void(vector from, vector to,float seglength,float drifts,float drifte,float branchfactor,float branchfactor_add) effect_lightningarc {
	vector direction,dirnew, pos, pos_l;
	float length, steps, steplength, i,drift;
	length     = vlen(from - to);
	if(length < 1)
		return;

	steps      = floor(length / seglength);
	if (steps < 1) {
		builtin_te_lightning1(world,from,to);
		return;
	}
	steplength = length / steps;
	direction  = normalize(to - from);
	pos_l = from;
	if (length > seglength) {
		for (i = 1; i < steps; i += 1) {
			drift = drifts * (1 - (i / steps)) + drifte * (i / steps);
			dirnew = normalize(direction * (1 - drift) + randomvec() * drift);
			pos = pos_l +  dirnew * steplength;
			builtin_te_lightning1(world,pos_l,pos);
			if (random() < branchfactor)
				effect_lightningarc(pos, pos + (dirnew * length * 0.25),seglength,drifts,drifte,min(branchfactor + branchfactor_add,1),branchfactor_add);

			pos_l = pos;
		}
		builtin_te_lightning1(world,pos_l,to);
	} else
		builtin_te_lightning1(world,from,to);
}

void(void) effect_lightningarc_read {
	vector from, to;
	from_x = net_read_coord(); from_y = net_read_coord(); from_z = net_read_coord();
	to_x   = net_read_coord(); to_y   = net_read_coord(); to_z   = net_read_coord();
	if (CVAR(cl_effects_lightningarc_simple)) {
		builtin_te_lightning1(world,from,to);
	} else {
		effect_lightningarc(from,to,
				CVAR(cl_effects_lightningarc_segmentlength),
				CVAR(cl_effects_lightningarc_drift_start),
				CVAR(cl_effects_lightningarc_drift_end),
				CVAR(cl_effects_lightningarc_branchfactor_start),
				CVAR(cl_effects_lightningarc_branchfactor_add));
	}
}

void(void) effect_blast_read {
	vector loc;
	loc_x = net_read_coord(); loc_y = net_read_coord(); loc_z = net_read_coord();
	pointparticles(particleeffectnum("TE_TEI_BIGEXPLOSION"), loc, '0 0 0', 1);
	entity e = spawn();
	setorigin(e, loc);
	sound(e, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	remove(e);
}

void(void) effect_lightningarc_big_read {
	vector from, to;
	from_x = net_read_coord(); from_y = net_read_coord(); from_z = net_read_coord();
	to_x   = net_read_coord(); to_y   = net_read_coord(); to_z   = net_read_coord();
	vector vd = to - from;
	vector v1 = from;
	vector v2;
	float pert = vlen(v1) * 0.05;
	float en = particleeffectnum("RM_LIGHTNING_TEAM2");
	float i;
	for (i = 1; i <= 4; i++) {
		v2 = from + (vd * 0.2 * i) + randomvec() * pert;
		trailparticles(world, en, v1, v2);
		v1 = v2;
	}
	trailparticles(world, en, v1, to);
}

.float frame1time;
.float lifetime, fadetime;
.float scale1, scale2;

void(void) effect_model_draw {
	self.angles = self.angles + frametime * self.avelocity;
	self.origin = self.origin + frametime * self.velocity;
	self.scale = self.scale1 + (self.scale2 - self.scale1) * (time - self.teleport_time) / (self.lifetime + self.fadetime - self.teleport_time);
	self.alpha = self.cnt * bound(0, 1 - (time - self.lifetime) / self.fadetime, 1);
	if (self.alpha < EFFECT_ALPHA_MIN_VISIBLE) {
		remove(self);
		return;
	}
	if (self.scale <= 0)
		return;

	R_AddEntity(self);
}

void(float isNew) effect_model_read {
	float f;
	entity e;
	self.classname = "modeleffect_spawner";
	f = net_read_byte();
	e = spawn();
	e.classname = "modeleffect";
	e.model = "from network";
	e.modelindex = net_read_short();
	e.skin = net_read_byte();
	e.frame = net_read_byte();
	e.frame1time = time;
	e.origin_x = net_read_coord();
	e.origin_y = net_read_coord();
	e.origin_z = net_read_coord();
	if (f & 1) {
		e.velocity_x = net_read_coord();
		e.velocity_y = net_read_coord();
		e.velocity_z = net_read_coord();
	}
	if (f & 2) {
		e.angles_x = net_read_angle();
		e.angles_y = net_read_angle();
		e.angles_z = net_read_angle();
	}
	if (f & 4) {
		e.avelocity_x = net_read_angle();
		e.avelocity_y = net_read_angle();
		e.avelocity_z = net_read_angle();
	}
	e.scale1 = net_read_short() / 256.0;
	e.scale2 = net_read_short() / 256.0;
	e.lifetime = time + net_read_byte() * 0.01;
	e.fadetime = net_read_byte() * 0.01;
	e.teleport_time = time;
	e.cnt = net_read_byte() / 255.0; // actually alpha
	e.draw = effect_model_draw;
	if (!isNew)
		remove(e); // yes, this IS stupid, but I don't need to duplicate all the read* stuff then
}
