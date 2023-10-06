float func_portable_init_done;
entity func_portable_chain;
.entity func_portable_caried;

var float(float f) func_portable_weapon_switch_mod_next;
float(float f) func_portable_weapon_switch_mod {
	if (self.func_portable_caried)
		return 0;

	return func_portable_weapon_switch_mod_next(f);
}

void(void) func_portable_drop {
	entity e = self.func_portable_caried.enemy;
	vector from = self.origin + self.view_ofs - (e.mins + e.maxs) * 0.5;
	makevectors(self.v_angle);
	trace_box(from, e.mins, e.maxs, from + v_forward * self.maxs_x * 4, TRACE_MOVE_NORMAL, self);
	vector pos = trace_endpos;
	remove(self.func_portable_caried);
	remove(self.func_portable_caried.weaponentity);
	self.func_portable_caried = spawn();
	self.func_portable_caried.cnt = -1;
	setorigin(e, pos);
	e.solid = SOLID_BSP;
	e.movetype = MOVETYPE_TOSS;
	e.effects &= ~EFFECT_NODRAW;
	e.flags = 0;
}

void(void) func_portable_decolorize {
	self.effects &= ~(EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);
}

void(entity e) func_portable_pick {
	float tag_found;
	entity _body = self.body;
	entity e2 = spawn();
	e2.enemy = e;
	e.velocity = '0 0 0';
	e.effects |= EFFECT_NODRAW;
	e.movetype = MOVETYPE_NONE;
	e.groundentity = NULL;
	e.flags = 0;
	e.solid = SOLID_NOT;
	if (substring(e.model, 0, 1) != "*") {
		setmodel(e2, e.model);
		if ((tag_found = gettagindex(_body, "tag_weapon"))) {
			setattachment(e2, _body, "tag_weapon");
		} else
			setattachment(e2, _body, "bip01 r hand");

		setorigin(e2, -0.5 * (e.mins + e.maxs));
	}
	self.func_portable_caried = e2;
	e2.weaponentity = spawn();
	setmodel(e2.weaponentity, e.model);
	e2.weaponentity.viewmodelforclient = self;
	setorigin(e2.weaponentity, -0.5 * (e.mins + e.maxs) + '20 0 -20');
}

var void(void) func_portable_player_think_next;
void(void) func_portable_player_think {
	if (self.func_portable_caried) {
		if (self.func_portable_caried.cnt == -1) {
			if not(self.BUTTON_ATCK) {
				remove(self.func_portable_caried);
				self.func_portable_caried = NULL;
			}
		} else {
			if (self.BUTTON_ATCK) {
				if (self.func_portable_caried.cnt)
					func_portable_drop();
			} else
				self.func_portable_caried.cnt = 1;
		}
	} else {
		vector o = self.origin + self.view_ofs;
		makevectors(self.v_angle);
		trace_line(o, o + self.maxs_x * 4 * v_forward, TRACE_MOVE_NORMAL, self);
		if (trace_ent && trace_ent.classname == "func_portable") {
			trace_ent.effects |= (EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);
			trace_ent.nextthink = time + sys_ticrate * 2;
			trace_ent.think = func_portable_decolorize;
			if (self.BUTTON_ATCK) {
				func_portable_pick(trace_ent);
			}
		}
	}
	func_portable_player_think_next();
}

var void(float killed) func_portable_player_clear_next;
void(float killed) func_portable_player_clear {
	if (self.func_portable_caried)
		func_portable_drop();

	func_portable_player_clear_next(killed);
}

void(void) spawnfunc_func_portable {
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_TOSS;
	self.pushfactor = (self.pushfactor ? self.pushfactor : 1);
	model_init(SOLID_BSP);
	if (!func_portable_init_done) {
		func_portable_init_done = 1;
		func_portable_player_think_next = plugin_chain_player_think;
		plugin_chain_player_think = func_portable_player_think;
		func_portable_weapon_switch_mod_next = plugin_chain_weapon_frame_switch_mod;
		plugin_chain_weapon_frame_switch_mod = func_portable_weapon_switch_mod;
		func_portable_player_clear_next = plugin_chain_player_clear;
		plugin_chain_player_clear = func_portable_player_clear;
	}
}

void(void) spawnfunc_func_portable_model {
	self.classname = "func_portable";
	spawnfunc_func_portable();
}
