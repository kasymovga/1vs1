.float buffs;
.float buffstat;
.float buff_active;
.float lightlev;
.float lightflags;
.vector lightcolor;
.vector buff_offset;

string rm_buffs_modelnames[RM_BUFFS_COUNT];
.entity buffmdl[RM_BUFFS_COUNT];
.entity buff_ring;

void(entity ment, float thebuffs) rm_buffs_model_set;

void(void) rm_buffs_models_load {
	if not(g_buffs_enabled) return;
	precache_model("models/buffs/buff_ring.md3");
	float i, b;
	for (i = 0, b = 1; i < RM_BUFFS_COUNT; ++i, b *= 2) if(b & g_buffs_enabled) {
		str_unzone_ifneeded(rm_buffs_modelnames[i]);
		string n = rm_buffs_TypeToName(b);
		string s = strcat("models/buffs/buff_", n, ".md3");
		if not(file_exists(s)) {
			s = "models/buffs/buff.md3";
			print("No model found for the ", rm_buffs_TypeToName(b), " Buff! Falling back to default.\n");
		}
		rm_buffs_modelnames[i] = strzone(s);
		precache_model(rm_buffs_modelnames[i]);
	}
}

void(void) rm_buffs_model_draw {
	vector org;
	float rendermodel = FALSE;
	if (!(self.effects & EFFECT_NODRAW))
	if (self.alpha > 0)
		rendermodel = TRUE;

	interpolate_do();
	if (self.sv_entnum && extension_DP_CSQC_QUERYRENDERENTITY) {
		if (getentity(self.sv_entnum, E_ACTIVE)) {
			org = getentityvec(self.sv_entnum, E_ORIGIN) + self.buff_offset;
		} else {
			//FIXME
			//if(fps_friendly)
			//    return;

			rendermodel = FALSE;
			org = self.origin;
		}
	} else {
		org = self.origin;
	}
	if (rendermodel)
		R_AddEntity(self);

	//FIXME
	//if(self.lightlev)
	//    R_AddDynamicLightEx(org, self.lightlev, self.lightcolor, -1, NULL, self.lightflags);
	if (self.effects & EFFECT_STARDUST)
		pointparticles(particleeffectnum("EF_STARDUST"), org, '0 0 0', frametime);
}

void(void) rm_buffs_model_multi_think {
	if (!self.owner || wasfreed(self.owner) || self.owner.buffs != self.buffstat) {
		remove(self);
		return;
	}
	self.effects = self.owner.effects;
	self.effects &= ~EFFECT_NODRAW;
	self.lightlev = self.owner.lightlev * 0.7;
	self.alpha = self.owner.alpha;
	if (self.buffs == RM_BUFFS_MEODP) {
		self.lightcolor = '1 0 0';
		self.effects &= ~EFFECT_ADDITIVE;
	}
	vector ang = '0 0 0';
	ang_y = math_mod(time * 120 + self.cnt, 360);
	makevectors(ang);
	vector ofs = v_forward * 10 + v_up * 3 * sin(time * 0.32 + self.cnt);
	setorigin(self, self.owner.origin + ofs);
	self.buff_offset = self.owner.buff_offset + ofs;
	self.angles_y = ang_y + 90;
	self.nextthink = time;
}

void(void) rm_buffs_model_think {
	if(self.sv_entnum) {
		// this is an overhead buff model

		self.effects |= EFFECT_ADDITIVE;
		self.alpha = 1;
		float me = player_localentnum/* - 1*/;

		if(self.sv_entnum == me)
		if(!CVAR(chase_active))
			self.alpha = -1;

		self.angles_y = 200 * time;
	} else {
		if (!self.buff_active) {
			// this is an inactive buff pickup model
			self.alpha = 0.3;
			self.effects &= ~(EFFECT_FULLBRIGHT | EFFECT_ADDITIVE);
			self.lightlev = 0;
		} else {
			// this is an active buff pickup model

			self.alpha = 1;
			self.effects |= (EFFECT_FULLBRIGHT | EFFECT_ADDITIVE);
			
			self.lightlev = 220 + 36 * sin(time);
		}
		self.angles_y = time * 110.1;
	}

	if (self.buffs == RM_BUFFS_MEODP)
		self.effects &= ~EFFECT_ADDITIVE;
			
	self.nextthink = time;
}

void(entity bmdl, entity parent, float offs) rm_buffs_model_multi_set {
	bmdl.owner = parent;
	float bi = rm_buffs_TypeToIndex(bmdl.buffs);
	rm_buffs_model_set(bmdl, bmdl.buffs);
	bmdl.owner = parent;
	bmdl.draw = rm_buffs_model_draw;
	bmdl.scale = (parent.scale ? parent.scale : 1); // * 0.90;
	bmdl.cnt = offs;
	bmdl.think = rm_buffs_model_multi_think;
	bmdl.buffstat = parent.buffs;
	bmdl.sv_entnum = parent.sv_entnum;
	bmdl.nextthink = time;
}

void(entity ment) rm_buffs_model_color_update {
	ment.lightcolor = ment.colormod = rm_buffs_TypeToColor(ment.buffs);
	if(ment.buffs == RM_BUFFS_MEODP)
		ment.lightcolor = '1 0 0';

	if(ment.buff_ring)
		ment.buff_ring.colormod = (ment.team ? (team_rgb(ment.team) + '0.1 0.1 0.1') : ment.colormod);
}

void(entity ment, float thebuffs) rm_buffs_model_set {
	float idx = rm_buffs_TypeToIndex(thebuffs);
	float i, j, b;
	if not(g_buffs_enabled & thebuffs) {
		g_buffs_enabled |= thebuffs;
		rm_buffs_models_load();
	}
	ment.buffs = thebuffs;
	if(idx >= 0) {
		// single model - use ment to display it
		for(i = 0; i < RM_BUFFS_COUNT; ++i) {
			if(ment.(buffmdl[i])) {
				remove(ment.(buffmdl[i]));
				ment.(buffmdl[i]) = NULL;
			}
		}
		ment.effects &= ~EFFECT_NODRAW;
		vector omins = ment.mins;
		vector omaxs = ment.maxs;
		setmodel(ment, rm_buffs_modelnames[rm_buffs_TypeToIndex(thebuffs)]);
		setsize(ment, omins, omaxs);
	} else {
		// multiple buffs - hide ment and use additional models
		ment.effects |= EFFECT_NODRAW;
		for(i = 0, b = 1; b <= RM_BUFFS_LAST; b *= 2) if(thebuffs & b) {
			if(!ment.(buffmdl[i]) || wasfreed(ment.(buffmdl[i])))
				ment.(buffmdl[i]) = spawn();
			ment.(buffmdl[i]).buffs = b;
			++i;
		}
		for(j = 0; j < RM_BUFFS_COUNT; ++j) {
			if(j >= i) {
				if(ment.(buffmdl[j])) {
					remove(ment.(buffmdl[j]));
					ment.(buffmdl[j]) = world;
				}
			} else rm_buffs_model_multi_set(ment.(buffmdl[j]), ment, (j/i)*360);
		}
	}
	rm_buffs_model_color_update(ment);
}

void(void) rm_buffs_model_remove {
	float i;
	for (i = 0; i < RM_BUFFS_COUNT; ++i) {
		if (self.(buffmdl[i])) {
			remove(self.(buffmdl[i]));
			self.(buffmdl[i]) = world;
		}
	}
	if (self.buff_ring) {
		remove(self.buff_ring);
	}
}

void(void) rm_buffs_model_ring_think {
	self.nextthink = time;
	self.angles_y = time * -110.1;
	self.alpha = self.owner.alpha;
	self.effects = self.owner.effects;
	self.effects &= ~(EFFECT_STARDUST | EFFECT_NODRAW);
	if (self.owner.team)
		self.effects &= ~EFFECT_ADDITIVE;

	setorigin(self, self.owner.origin + '0 0 15');
}

void(entity bmdl) rm_buffs_model_ring_attach {
	if (bmdl.buff_ring)
		return;

	entity e = spawn();
	e.owner = bmdl;
	e.effects = bmdl.effects;
	e.alpha = bmdl.alpha;
	e.scale = bmdl.scale * 1.2;
	e.draw = rm_buffs_model_draw;
	e.think = rm_buffs_model_ring_think;
	e.nextthink = time;
	setsize(e, bmdl.mins, bmdl.maxs);
	setorigin(e, bmdl.origin + bmdl.maxs * 0.5 * bmdl.scale);
	setmodel(e, "models/buffs/buff_ring.md3");
	bmdl.buff_ring = e;
}

void(float ignore) rm_buffs_model_read {
	float sf = net_read_byte();
	if (sf & 1) {
		self.sv_entnum = net_read_byte(); // the buff owner
		self.entremove = rm_buffs_model_remove;
		self.draw = rm_buffs_model_draw;
		self.think = rm_buffs_model_think;
		self.effects = (EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_NOSHADOW);
		self.lightlev = 200;
		self.nextthink = time;
		//FIXME
		//self.lightflags = PFLAGS_FULLDYNAMIC;
		if (self.sv_entnum) {
			// this is an overhead buff model

			self.buff_offset = RM_BUFFS_MODEL_OVERHEAD_OFFSET;
			setsize(self, '0 0 -40', '0 0 40');
		} else {
			// this is a buff pickup model
			self.buff_offset = '0 0 0';
			self.solid = SOLID_TRIGGER;
			self.movetype = MOVETYPE_TOSS;
			self.scale = 1.5;
			setsize(self, '-15 -15 -40', '15 15 40');
			self.gravity = 100;
			self.effects |= EFFECT_STARDUST;
			//FIXME
			//if(!CVAR(gl_flashblend))
			//    self.lightflags |= PFLAGS_CORONA;
			rm_buffs_model_ring_attach(self);
		}
	}
	if (sf & 2) {
		self.buff_active = net_read_byte();
	}
	if (sf & 4) {
		rm_buffs_model_set(self, net_read_coord());
	}
	if (sf & 8) {
		vector o;
		o_x = net_read_coord();
		o_y = net_read_coord();
		o_z = net_read_coord();
		setorigin(self, o);
	}
	if (sf & 16) {
		self.team = max(0, net_read_byte()-1);
		rm_buffs_model_color_update(self);
	}
	interpolate_note();
}

float rm_buffs_draw_buffval;
float rm_buffs_draw_updatetime;
string rm_buffs_draw_str;
vector rm_draw_buffs_pos;
void(void) rm_buffs_draw {
	float buffs = getstati(STAT_RM_BUFFS), sw, a;
	if (rm_buffs_draw_buffval != buffs) {
		rm_buffs_draw_updatetime = time;
		rm_buffs_draw_buffval =  buffs;
		str_unzone_ifneeded(rm_buffs_draw_str);
		rm_buffs_draw_str = NULL;
		if (buffs) {
			rm_buffs_draw_str = str_zone_ifneeded(rm_buffs_TypeToExpandedName(buffs, " ", 1));
			sw = stringwidth(rm_buffs_draw_str, TRUE) * sbar_fontsize_x;
			rm_draw_buffs_pos_y = CVAR(vid_conheight) - CVAR(vid_conheight) / 7 - sbar_fontsize_y;
			rm_draw_buffs_pos_x = (CVAR(vid_conwidth) - sw) * 0.5;
		}
	}
	if not(buffs)
		return;

	a = 1 - bound(0, time - rm_buffs_draw_updatetime, 1);
	drawcolorcodedstring(rm_draw_buffs_pos, rm_buffs_draw_str, sbar_fontsize, 0.3 + 0.7 * a, DRAWFLAG_NORMAL);
}
