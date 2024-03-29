.float silent;
entity gib_oldest, gib_latest;
float gib_count;

void(void) gib_remove {
	if (self == gib_oldest)
		gib_oldest = self.sort_next;

	if (self == gib_latest)
		gib_latest = self.sort_prev;

	if (self.sort_next)
		self.sort_next.sort_prev = self.sort_prev;

	if (self.sort_prev)
		self.sort_prev.sort_next = self.sort_next;

	remove(self);
	gib_count--;
}

string(float specnum) gib_species_prefix {
	switch (specnum) {
	case SPECIES_HUMAN:       return "";
	case SPECIES_ALIEN:       return "alien_";
	case SPECIES_ROBOT_SHINY: return "robot_";
	case SPECIES_ROBOT_RUSTY: return "robot_"; // use the same effects, only different gibs
	case SPECIES_ROBOT_SOLID: return "robot_"; // use the same effects, only different gibs
	case SPECIES_ANIMAL:      return "animal_";
	case SPECIES_RESERVED:    return "reserved_";
	default:         return "";
	}
}

void(entity gib, string mdlname, float specnum) gib_model_set {
	switch (specnum) {
	case SPECIES_ROBOT_RUSTY:
	case SPECIES_ROBOT_SHINY:
	case SPECIES_ROBOT_SOLID:
		if (specnum != SPECIES_ROBOT_SOLID || mdlname == "models/gibs/chunk.mdl") {
			if (mdlname == "models/gibs/bloodyskull.md3")
				setmodel(gib, "models/gibs/robo.md3");
			else
				setmodel(gib, strcat("models/gibs/robo", ftos(floor(random() * 8) + 1), ".md3"));

			if (specnum == SPECIES_ROBOT_SHINY) {
				gib.skin = 1;
				gib.colormod = '2 2 2';
			}
			gib.scale = 1;
			break;
		}
	default:
		setmodel(gib, mdlname);
		gib.skin = specnum;
		break;
	}
}

void(float ef, vector org, float explosionspeed, float howmany) gib_blood {
	float i;
	for (i = 0; i < 10; ++i)
		pointparticles(ef, org, randomvec() * explosionspeed, howmany / 250);
}

void(void) gib_remove_on_noimpact {
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		self.nextthink = time;
}

void(void) gib_touch {
	// TODO maybe bounce of walls, make more gibs, etc.
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) {
		self.nextthink = time;
		return;
	}
	if (!self.silent)
		sound(self, CHAN_PAIN, strcat("misc/gib_splat0", ftos(floor(prandom() * 4 + 1)), ".wav"), VOL_BASE, ATTN_NORM);

	pointparticles(particleeffectnum(strcat(gib_species_prefix(self.cnt), "blood")), self.origin + '0 0 1', '0 0 30', 10);
	self.nextthink = time;
}

void(void) gib_draw {
	vector oldorg;
	oldorg = self.origin;
	physics_move_no_match_server();
	self.renderflags = 0;
	self.alpha = bound(0, self.nextthink - time, 1);
	if (self.alpha < EFFECT_ALPHA_MIN_VISIBLE)
		gib_remove();
	else
		R_AddEntity(self);
}

void(string mdlname, vector org, vector vconst, vector vrand, float specnum, float destroyontouch, float issilent) gib_toss {
	entity gib = spawn();
	if not(gib_oldest)
		gib_oldest = gib;

	if (gib_latest)
		gib_latest.sort_next = gib;

	gib.sort_prev = gib_latest;
	gib_latest = gib;
	gib_count++;
	gib.classname = "gib";
	gib.move_movetype = MOVETYPE_BOUNCE;
	gib.gravity = 1;
	gib.solid = SOLID_TRIGGER;
	gib.cnt = specnum;
	gib.silent = issilent;
	gib_model_set(gib, mdlname, specnum);
	setsize (gib, '-8 -8 -8', '8 8 8');
	gib.draw = gib_draw;
	if (destroyontouch)
		gib.move_touch = gib_touch;
	else
		gib.move_touch = gib_remove_on_noimpact;

	gib.move_origin = gib.origin = org;
	gib.move_velocity = vconst * CVAR_OR(cl_gibs_velocity_scale, 1) + vrand * CVAR_OR(cl_gibs_velocity_random, 1) + '0 0 1' * CVAR(cl_gibs_velocity_up);
	gib.move_avelocity = prandomvec() * vlen(gib.move_velocity);
	gib.move_time = time;
	gib.nextthink = time + CVAR_OR(cl_gibs_lifetime, 14) * (1 + prandom() * 0.15);
	if (gib_count > CVAR_OR(cl_gibs_maxcount,100)) {
		entity oldself = self;
		self = gib_oldest;
		gib_remove();
		self = oldself;
	}
}

void(void) gib_read {
	float amount, type, specnum;
	float i;
	vector org, vel;
	string specstr;
	float issilent;
	string gentle_prefix = "";
	float c, randomvalue;
	type = net_read_byte(); // gibbage type
	amount = net_read_byte() / 16.0; // gibbage amount
	org_x = net_read_short() * 4 + 2;
	org_y = net_read_short() * 4 + 2;
	org_z = net_read_short() * 4 + 2;
	vel = net_decompress_vec(net_read_short());
	if not(CVAR(cl_gentle))
		amount *= 1 - CVAR(cl_nogibs);

	if (amount <= 0)
		return;

	if (CVAR(cl_gentle))
		type |= 0x80; // set gentle bit

	if (type & 0x80) {
		if (CVAR(cl_gentle) > 1)
			gentle_prefix = "";
		else
			gentle_prefix = "morphed_";
	} else if (CVAR(cl_particlegibs)) {
		type |= 0x80;
		gentle_prefix = "particlegibs_";
	}
	specnum = (type & 0x78) / 8; // blood/gibmodel type: using four bits (0..7, bit indexes 3,4,5)
	issilent = (type & 0x40);
	type = type & 0x87; // remove the species bits: bit 7 = gentle, bit 0,1,2 = kind of gib
	specstr = gib_species_prefix(specnum);
	switch (type) {
	case 0x01:
		if (!issilent)
			builtin_pointsound(org, "misc/gib.wav", VOL_BASE, ATTN_NORM);

		if (prandom() < amount)
			gib_toss("models/gibs/eye.md3", org, vel, prandomvec() * 150, specnum, 0, issilent);

		float p = particleeffectnum(strcat(specstr, "bloodshower"));
		for (i = 0; i < 10; i++)
			pointparticles(p, org, randomvec() * 1200, amount);

		if (prandom() < amount)
			gib_toss("models/gibs/bloodyskull.md3", org + 16 * prandomvec(), vel, prandomvec() * 100, specnum, 0, issilent);

		for (c = 0; c < amount; ++c) {
			randomvalue = amount - c;
			if (prandom() < randomvalue)
				gib_toss("models/gibs/arm.md3", org + 16 * prandomvec() + '0 0 8', vel, prandomvec() * (prandom() * 120 + 90), specnum,0, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/arm.md3", org + 16 * prandomvec() + '0 0 8', vel, prandomvec() * (prandom() * 120 + 90), specnum,0, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/chest.md3", org + 16 * prandomvec(), vel, prandomvec() * (prandom() * 120 + 80), specnum,0, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/smallchest.md3", org + 16 * prandomvec(), vel, prandomvec() * (prandom() * 120 + 80), specnum,0, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/leg1.md3", org + 16 * prandomvec() + '0 0 -5', vel, prandomvec() * (prandom() * 120 + 85), specnum,0, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/leg2.md3", org + 16 * prandomvec() + '0 0 -5', vel, prandomvec() * (prandom() * 120 + 85), specnum,0, issilent);

			// these splat on impact
			if (prandom() < randomvalue)
				gib_toss("models/gibs/chunk.mdl", org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/chunk.mdl", org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/chunk.mdl", org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);

			if (prandom() < randomvalue)
				gib_toss("models/gibs/chunk.mdl", org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);
		}
		break;
	case 0x02:
		pointparticles(particleeffectnum(strcat(specstr, "blood")), org, vel, amount * 16);
		break;
	case 0x03:
		if (prandom() < amount)
			gib_toss("models/gibs/chunk.mdl", org, vel, prandomvec() * (prandom() * 30 + 20), specnum, 1, issilent); // TODO maybe adjust to more randomization?

		break;
	case 0x81:
		pointparticles(particleeffectnum(strcat(gentle_prefix, "damage_dissolve")), org, vel, amount);
		break;
	case 0x82:
		pointparticles(particleeffectnum(strcat(gentle_prefix, "damage_hit")), org, vel, amount * 16);
		break;
	case 0x83:
		// no gibs in gentle mode, sorry
		break;
	}
}

void(void) gib_precache {
	precache_model("models/gibs/chunk.mdl");
	precache_model("models/gibs/leg1.md3");
	precache_model("models/gibs/leg2.md3");
	precache_model("models/gibs/chest.md3");
	precache_model("models/gibs/smallchest.md3");
	precache_model("models/gibs/arm.md3");
	precache_model("models/gibs/bloodyskull.md3");
	precache_model("models/gibs/eye.md3");
	precache_model("models/gibs/robo.md3");
	precache_model("models/gibs/robo1.md3");
	precache_model("models/gibs/robo2.md3");
	precache_model("models/gibs/robo3.md3");
	precache_model("models/gibs/robo4.md3");
	precache_model("models/gibs/robo5.md3");
	precache_model("models/gibs/robo6.md3");
	precache_model("models/gibs/robo7.md3");
	precache_model("models/gibs/robo8.md3");
	precache_sound("misc/gib.wav");
	precache_sound("misc/gib_splat01.wav");
	precache_sound("misc/gib_splat02.wav");
	precache_sound("misc/gib_splat03.wav");
	precache_sound("misc/gib_splat04.wav");
}
