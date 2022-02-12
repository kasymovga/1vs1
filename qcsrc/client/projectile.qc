.float spawntime;
.vector trail_oldorigin;
.float trail_oldtime;
.float trail_effect;
.vector server_angles;
.float use_server_angles;

void(void) projectile_touch_stop {
	self.move_velocity = self.move_avelocity = '0 0 0';
	self.move_movetype = MOVETYPE_NONE;
}

.float count; // set if clientside projectile
.float cnt; // sound index
.float gravity;
.float snd_looping;
.float silent;

void projectile_colormap_setup(float default_team) {
    if not(team_mode)
        self.team = default_team;

    self.colormap = 1024 + (self.team - 1) * 17;
}

.float nextparticle;
void(vector to) projectile_trail_draw {
	vector from;
	float t0;
	from = self.trail_oldorigin;
	t0 = self.trail_oldtime;
	self.trail_oldorigin = to;
	self.trail_oldtime = time;
	if (from == to) {
		switch (self.cnt) {
		case PROJECTILE_HG_NAPALMSHARD:
			goto flame;
		case PROJECTILE_HG_NAPALM:
		case PROJECTILE_FIREMINE:
			to_z += 1;
			break;
		case PROJECTILE_HG_TRANSLOC:
			to = from = self.origin;
			to_z += 1;
			break;
		case PROJECTILE_ELECTRO:
			trailparticles(self, particleeffectnum("TR_NEXUIZPLASMA"), from, to);
			return;
		case PROJECTILE_HG_PLASMA_SHARD:
			trailparticles(self, particles_rm_effectnum_team("RM_HG_PLASMA", self.team, 2), from, to);
			return;
		case PROJECTILE_HG_RAZE:
		case PROJECTILE_HG_PLASMA:
			break;
		default:
			return;
		}
	}
	if (self.trail_effect >= 0)
		trailparticles(self, self.trail_effect, from, to);

	if (self.cnt == PROJECTILE_HG_NAPALMSHARD) {
:flame
		vector v = randomvec();
		v_z = (v_z + 1) * 0.25;
		if (time >= self.nextparticle) {
			pointparticles(particles_rm_effectnum_team("RM_HG_NAPALM_FIRE", self.team, 1), self.origin + v/* * self.extradata * 0.7 */, '0 0 0', 1);
			self.nextparticle = time + 0.15 + random() * 0.10;
		}
	}
}

void(void) projectile_draw {
	vector rot;
	vector trailorigin;
	float f;
	float drawn;
	float t;
	f = self.move_flags;
	if (self.count & 0x80) {
		self.move_angles = self.angles;
		physics_move_match_server();
		if not(self.move_flags & FL_ONGROUND)
		if (self.velocity != '0 0 0') {
			self.angles = vectoangles(self.velocity);
		}
	} else {
		InterpolateOrigin_Do();
		if (self.use_server_angles) {
			self.angles = self.server_angles;
		} else if (self.cnt == PROJECTILE_HG_RAZE) {
			self.angles_x = -90;
		}
	}
	if (self.count & 0x80) {
		drawn = (time >= self.spawntime);
	} else {
		drawn = (self.iflags & IFLAG_VALID);
	}
	t = time;
	if ((!(f & FL_ONGROUND) || self.cnt == PROJECTILE_HG_RAZE) && !self.use_server_angles) {
		rot = '0 0 0';
		switch (self.cnt) {
		/*
		case PROJECTILE_GRENADE:
			rot = '-2000 0 0'; // forward
			break;
		*/
		case PROJECTILE_GRENADE_BOUNCING:
			rot = '0 -1000 0'; // sideways
			break;
		case PROJECTILE_HG_GENERIC:
		case PROJECTILE_HG_NAPALM:
			rot = '0 1000 0'; // sideways
			break;
		case PROJECTILE_HOOKBOMB:
			rot = '1000 0 0'; // forward
			break;
		case PROJECTILE_HG_TRANSLOC:
			rot = '700 643 721';
			break;
		case PROJECTILE_HG_RAZE:
		case PROJECTILE_HG_PLASMA:
			rot = '0 0 -1000';
			break;
		default:
			break;
		}
		self.angles = anglestransform_multiply(self.angles, rot * (t - self.spawntime));
	}
	makevectors(self.angles);
	trailorigin = self.origin;
	switch (self.cnt) {
	case PROJECTILE_GRENADE:
	case PROJECTILE_GRENADE_BOUNCING:
		trailorigin += v_right * 1 + v_forward * -10;
		break;
	default:
		break;
	}
	if (drawn)
		projectile_trail_draw(trailorigin);
	else {
		self.trail_oldorigin = trailorigin;
		self.trail_oldtime = time;
	}
	if (!drawn)
		return;

	self.renderflags = 0;
	R_AddEntity(self);
}

void(entity e, float ch, string samp, float vol, float attn) projectile_loopsound {
	if (self.silent)
		return;

	sound(e, ch, samp, vol, attn);
	e.snd_looping = 1;
}

void(void) projectile_remove {
	if (self.snd_looping)
		sound(self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);

	if (self.count & 0x80) {
		tracebox(self.origin, self.mins, self.maxs, self.origin + self.velocity * 0.05, TRACE_MOVE_NORMAL, self);
		projectile_trail_draw(trace_endpos);
	}
}

void(float ignore) projectile_read {
	float f;
	// projectile properties:
	//   kind (interpolated, or clientside)
	//
	//   modelindex
	//   origin
	//   scale
	//   if clientside:
	//     velocity
	//     gravity
	//   soundindex (hardcoded list)
	//   effects
	//
	// projectiles don't send angles, because they always follow the velocity
	f = net_read_byte();
	self.count = (f & 0x80);
	self.iflags = (self.iflags & IFLAG_INTERNALMASK);
    if (!self.use_server_angles)
        self.iflags |= IFLAG_ANGLES | IFLAG_AUTOANGLES;

	self.solid = SOLID_TRIGGER;
	//self.effects = EFFECT_NOMODELFLAGS;
	// this should make collisions with bmodels more exact, but it leads to
	// projectiles no longer being able to lie on a bmodel
	self.move_nomonsters = TRACE_MOVE_WORLDONLY;
	if (f & 0x40)
		self.move_flags |= FL_ONGROUND;
	else
		self.move_flags &= ~FL_ONGROUND;

	if (!self.move_time) {
		// for some unknown reason, we don't need to care for
		// sv_gameplayfix_delayprojectiles here.
		self.move_time = time;
		self.spawntime = time;
	} else
		self.move_time = max(self.move_time, time);

	if (!(self.count & 0x80))
		InterpolateOrigin_Undo();

	if (f & 1) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
		if (self.count & 0x80) {
			self.velocity_x = net_read_coord();
			self.velocity_y = net_read_coord();
			self.velocity_z = net_read_coord();
			self.gravity = net_read_coord();

			self.move_origin = self.origin;
			self.move_velocity = self.velocity;
		}
		if (time == self.spawntime || (self.count & 0x80)) {
			self.trail_oldorigin = self.origin;
		}
		if (f & 0x20)
		if not(f & 0x80) {
			self.trail_oldorigin = self.origin;
			InterpolateOrigin_Note();
		}
	}
	if (f & 2) {
		self.trail_effect = -1;
		self.cnt = net_read_byte();
		if (f & 16) {
			self.team = net_read_char();
		} else {
			self.team = 0;
		}
		self.silent = (self.cnt & 0x80);
		self.cnt = (self.cnt & 0x7F);
		self.scale = 1;
		switch (self.cnt) {
		case PROJECTILE_ELECTRO:
			setmodel(self, "models/ebomb.mdl");
			projectile_loopsound(self, CHAN_PROJECTILE, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
			self.trail_effect = particleeffectnum("TR_NEXUIZPLASMA");
			break;
		case PROJECTILE_ROCKET:
			projectile_loopsound(self, CHAN_PROJECTILE, "weapons/rocket_fly.wav", VOL_BASE, ATTN_NORM);
			setmodel(self, "models/rocket.md3");
			self.scale = 2;
			self.trail_effect = particleeffectnum("TR_ROCKET");
			break;
		case PROJECTILE_BULLET:
		case PROJECTILE_BULLET_GLOWING:
			if (self.cnt == PROJECTILE_BULLET)
				self.trail_effect = particleeffectnum("tr_bullet");
			else
				self.trail_effect = particleeffectnum("tr_rifle");

			setmodel(self, "models/tracer.mdl");
			break;
		case PROJECTILE_CRYLINK:
		case PROJECTILE_CRYLINK_BOUNCING:
			self.trail_effect = particleeffectnum("TR_CRYLINKPLASMA");
			setmodel(self, "models/plasmatrail.mdl");
			break;
		case PROJECTILE_GRENADE:
		case PROJECTILE_HOOKBOMB:
		case PROJECTILE_GRENADE_BOUNCING:
			self.trail_effect = particleeffectnum("TR_KNIGHTSPIKE");
			setmodel(self, "models/grenademodel.md3");
			break;
		case PROJECTILE_LASER: setmodel(self, "models/laser.mdl"); break;
		case PROJECTILE_HLAC: setmodel(self, "models/hlac_bullet.md3"); break;
		case PROJECTILE_PORTO_RED:
		case PROJECTILE_PORTO_BLUE:
			setmodel(self, "models/grenademodel.md3");
			self.scale = 4;
			self.trail_effect = particleeffectnum("TR_WIZSPIKE");
			self.alpha = 0.5;
			self.colormod = ((self.cnt == PROJECTILE_PORTO_RED) ? '2 1 1' : '1 1 2');
			break;
		case PROJECTILE_HAGAR:
		case PROJECTILE_HAGAR_BOUNCING:
			setmodel(self, "models/hagarmissile.mdl");
			self.scale = 0.4;
			self.trail_effect = particleeffectnum("TR_GRENADE");
			break;
		case PROJECTILE_FIREBALL:
		case PROJECTILE_HG_NAPALMSHARD:
		case PROJECTILE_FIREMINE:
			self.model = "";
			self.modelindex = 0;
			if (self.cnt == PROJECTILE_FIREBALL) {
				self.trail_effect = particleeffectnum("fireball");
				projectile_loopsound(self, CHAN_PROJECTILE, "weapons/fireball_fly2.wav", VOL_BASE, ATTN_NORM);
			} else {
				projectile_loopsound(self, CHAN_PROJECTILE, "weapons/fireball_fly.wav", VOL_BASE, ATTN_NORM);
				if (self.cnt == PROJECTILE_FIREMINE)
					self.trail_effect = particleeffectnum("firemine");
				else
					self.trail_effect = particles_rm_effectnum_team("RM_HG_NAPALM_TRAIL", self.team, 1);
			}
			break; // particle effect is good enough
		case PROJECTILE_BULLET_BIG:
		case PROJECTILE_BULLET_BIG_BOUNCING:
			setmodel(self, "models/tracer.mdl");
			self.scale = 3;
			break;
		case PROJECTILE_HG_GENERIC:
		case PROJECTILE_HG_NAPALM:
			setmodel(self, "models/handgrenade.iqm");
			projectile_colormap_setup(COLOR_TEAM1);
			break;
		case PROJECTILE_HG_PLASMA:
			setmodel(self, "models/plasmabomb.iqm");
			projectile_colormap_setup(COLOR_TEAM2);
			self.trail_effect = particles_rm_effectnum_team("RM_HG_PLASMA", self.team, 2);
			break;
		case PROJECTILE_HG_REMOTE:
			setmodel(self, "models/mine.md3");
			self.skin = team_index(self.team);
			break;
		case PROJECTILE_ELECTRO_BEAM:
		case PROJECTILE_RM_LASER:
		case PROJECTILE_HG_LASER:
			setmodel(self, "models/elaser.mdl");
			if (self.cnt == PROJECTILE_RM_LASER) {
				switch (self.team) {
				case COLOR_TEAM2:
					self.trail_effect = particleeffectnum("TE_TEI_G3BLUE_HIT");
					break;
				case COLOR_TEAM3:
					self.trail_effect = particleeffectnum("TE_TEI_G3YELLOW_HIT");
					break;
				case COLOR_TEAM4:
					self.trail_effect = particleeffectnum("TE_TEI_G3PINK_HIT");
					break;
				default:
					self.trail_effect = particleeffectnum("TE_TEI_G3RED_HIT");
					break;
				}
			} else if (self.cnt == PROJECTILE_HG_LASER)
				self.trail_effect = particles_rm_effectnum_team("RM_HG_PLASMA", self.team, 1);
			else
				self.trail_effect = particleeffectnum("TR_NEXUIZPLASMA");

			break;
		case PROJECTILE_HG_TRANSLOC:
			setmodel(self, "models/translocator.iqm");
			self.skin = team_index(self.team);
			projectile_colormap_setup(COLOR_TEAM4);
			switch (self.team) {
				case COLOR_TEAM1:           self.trail_effect = particleeffectnum("TE_TEI_G3RED_HIT"); break;
				case COLOR_TEAM2:           self.trail_effect = particleeffectnum("TE_TEI_G3BLUE_HIT"); break;
				case COLOR_TEAM3:           self.trail_effect = particleeffectnum("TE_TEI_G3YELLOW_HIT"); break;
				case COLOR_TEAM4: default:  self.trail_effect = particleeffectnum("TE_TEI_G3PINK_HIT"); break;
			}
			//self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
			break;
		case PROJECTILE_HG_PLASMA_SHARD:
			setmodel(self, "models/ebomb.mdl");
			projectile_colormap_setup(COLOR_TEAM2);
			self.skin = 2;
			self.trail_effect = particles_rm_effectnum_team("RM_HG_PLASMA", self.team, 2);
			//plasma_chain = findchainfloat_tofield(cnt, PROJECTILE_HG_PLASMA_SHARD, plasma_next);
			projectile_loopsound(self, CHAN_PROJECTILE, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
			break;
		case PROJECTILE_HG_RAZE:
			setmodel(self, "models/raze.md3");
			projectile_colormap_setup(COLOR_TEAM1);
			self.trail_effect = particles_rm_effectnum_team("RM_HG_PLASMA", self.team, 1);
			break;
		default:
			error("Received invalid CSQC projectile, can't work with this!");
			break;
		}
		self.colormod = '0 0 0';
		self.move_movetype = PROJECTILE_INFO_PROPERTY(self.cnt, movetype);
		if (self.move_movetype == MOVETYPE_BOUNCEMISSILE || self.move_movetype == MOVETYPE_BOUNCE)
			self.move_touch = NULL;
		else
			self.move_touch = projectile_touch_stop;

		projectile_set_size(self, self.cnt);
	}
	if (f & 4) {
		self.server_angles_x = net_read_coord();
		self.server_angles_y = net_read_coord();
		self.server_angles_z = net_read_coord();
		self.iflags &= ~(IFLAG_ANGLES | IFLAG_AUTOANGLES);
		self.use_server_angles = TRUE;
	}
	if (self.gravity) {
		if (self.move_movetype == MOVETYPE_FLY)
			self.move_movetype = MOVETYPE_TOSS;
		else if (self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			self.move_movetype = MOVETYPE_BOUNCE;
	} else {
		if (self.move_movetype == MOVETYPE_TOSS)
			self.move_movetype = MOVETYPE_FLY;
		else if (self.move_movetype == MOVETYPE_BOUNCE)
			self.move_movetype = MOVETYPE_BOUNCEMISSILE;
	}
	if (!(self.count & 0x80))
		InterpolateOrigin_Note();

	self.draw = projectile_draw;
	self.entremove = projectile_remove;
}

void(void) projectile_precache {
	precache_model("models/ebomb.mdl");
	precache_model("models/elaser.mdl");
	precache_model("models/grenademodel.md3");
	precache_model("models/hagarmissile.mdl");
	precache_model("models/hlac_bullet.md3");
	precache_model("models/laser.mdl");
	precache_model("models/plasmatrail.mdl");
	precache_model("models/rocket.md3");
	precache_model("models/tracer.mdl");
	precache_sound("weapons/electro_fly.wav");
	precache_sound("weapons/rocket_fly.wav");
	precache_sound("weapons/fireball_fly.wav");
	precache_sound("weapons/fireball_fly2.wav");
}

void(void) projectile_info_read {
	float phighest = net_read_byte();
	float i;
	for (i = 0; i < phighest; ++i) {
		float type = net_read_byte();
		float _movetype = net_read_byte();
		switch (type) {
		case PROJECTILE_INFO_TYPE_UNREGISTERED:
		case PROJECTILE_INFO_TYPE_POINT_000:
			projectile_register(i + 1, type, '0 0 0', _movetype);
			break;
		case PROJECTILE_INFO_TYPE_POINT_00n3:
			projectile_register(i + 1, type, '0 -3 -3', _movetype);
			break;
		case PROJECTILE_INFO_TYPE_POINT:
		case PROJECTILE_INFO_TYPE_CENTERED:
		case PROJECTILE_INFO_TYPE_UNCENTERED:
			projectile_info_type[i] = type;
			projectile_info_sizes[i] = net_read_coord();
			projectile_info_movetype[i] = _movetype;
			projectile_info_highest_registered = max(projectile_info_highest_registered, i + 1);
			break;
		default:
			error(strcat("Invalid ProjInfo type ", ftos(type)));
		}
	}
}
