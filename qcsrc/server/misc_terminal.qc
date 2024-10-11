entity misc_terminal_chain;
.entity terminal_progress;
float g_terminals_auth_range;
float g_terminals_auth_damage_delay;
float g_terminals_auth_time;
float g_terminals_auth_cooldown;

var void(float killed) misc_terminal_player_clear_next;
void(float killed) misc_terminal_player_clear {
	if (self.terminal_progress) {
		if (self.terminal_progress.enemy)
			progressbar_remove(self.terminal_progress.enemy);

		remove(self.terminal_progress);
		self.terminal_progress = NULL;
	}
	misc_terminal_player_clear_next(killed);
}

var void(void) misc_terminal_player_think_next;
void(void) misc_terminal_player_think {
	entity e;
	float found = FALSE;
	if (time - self.lastdamage < g_terminals_auth_damage_delay || self.hg_stealth) {
		goto finish;
	}
	for (e = misc_terminal_chain; e; e = e.enemy)
		if (vlen(self.origin - e.origin) < g_terminals_auth_range) {
			makevectors(e.angles);
			if (normalize(e.origin - self.origin + self.view_ofs) * v_right > 0) {
				continue;
			}
			found = TRUE;
			break;
		}
	if not(found) {
		if (self.terminal_progress) {
			self.terminal_progress.cnt = self.terminal_progress.dmg = 0;
			if (self.terminal_progress.enemy) {
				progressbar_remove(self.terminal_progress.enemy);
				self.terminal_progress.enemy = NULL;
			}
		}
	} else {
		if not(self.terminal_progress && self.terminal_progress.dmg) {
			if not(self.terminal_progress) {
				self.terminal_progress = spawn();
			}
			if (time < self.terminal_progress.phase) {
				print_to_spec(self, PRINT_CENTER, "You must wait {1} seconds before authenticating again", ftos(ceil(self.terminal_progress.phase - time)), "", "");
				self.terminal_progress.dmg = TRUE;
				goto finish;
			}
			if not(self.terminal_progress.enemy) {
				self.terminal_progress.enemy = progressbar_create("Hacking...", self);
			}
			self.terminal_progress.cnt = approach(self.terminal_progress.cnt, 1, frametime / g_terminals_auth_time);
			progressbar_set(self.terminal_progress.enemy, self.terminal_progress.cnt);
			if (self.terminal_progress.cnt == 1) {
				self.terminal_progress.cnt = 0;
				self.terminal_progress.dmg = TRUE;
				self.terminal_progress.phase = time + g_terminals_auth_cooldown;
				self.buffs = 0;
				self.buff_cdoverride = -1;
				sound(self, CHAN_TRIGGER, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
				progressbar_remove(self.terminal_progress.enemy);
				self.terminal_progress.enemy = NULL;
				nadget_ShowMenu(TRUE);
				//if (g_start_weapon_selectable)
				//	weapon_selectable_send();
				//if(g_weaponarena_secondary && !self.w_secondary) {
				//	W_SetSecondary(self, self.w_secondary_picked);
				//}
			}
		}
	}
:finish
	misc_terminal_player_think_next();
}

float misc_terminal_init_done;
void(void) misc_terminal_init {
	precache_model("models/it/pc.md3");
	precache_model("models/it/lcd.md3");
	precache_model("models/it/keyboard.md3");
	precache_sound("weapons/rocket_mode.wav");
	CVAR_CACHE(g_terminals_auth_range);
	CVAR_CACHE(g_terminals_auth_damage_delay);
	CVAR_CACHE(g_terminals_auth_time);
	CVAR_CACHE(g_terminals_auth_cooldown);
	misc_terminal_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = misc_terminal_player_think;
	misc_terminal_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = misc_terminal_player_clear;
}

void(void) misc_terminal_reset {
}

void(void) spawnfunc_misc_terminal {
	if (!rm_active || !cvar("g_terminals")) {
		remove(self);
		return;
	}
	if not(misc_terminal_init_done) {
		misc_terminal_init_done = TRUE;
		misc_terminal_init();
	}
	vector o;
	self.angles_x = 0;
	self.angles_z = 0;
	self.reset = misc_terminal_reset;
	makevectors(self.angles);
	self.angles_y += 90;
	self.classname = "misc_terminal";
	self.scale = 1.5;
	setmodel(self, "models/it/pc.md3");
	self.mins_x = self.mins_y;
	self.maxs_x = self.maxs_y;
	setsize(self, self.mins * self.scale, self.maxs * self.scale);
	self.solid = SOLID_BBOX;
	entity_move_out_of_solid(self);
	entity_droptofloor_handler();
	entity e = spawn();
	e.owner = self;
	e.angles = self.angles;
	setmodel(e, "models/it/lcd.md3");
	e.mins_y = e.mins_x;
	e.maxs_y = e.maxs_x;
	e.scale = 1.1;
	setsize(e, e.mins * e.scale, e.maxs * e.scale);
	setorigin(e, self.origin + v_up * self.maxs_z);
	o = e.origin;
	e.solid = SOLID_BBOX;
	//e.skin = 1;
	//e.glow_size = 150;
	//e.glow_color = 0x7C;
	e = spawn();
	setorigin(e, o + v_forward * 40 + v_up * 30);
	e.light_lev = 128;
	e.color = '0.6 0.7 0.7';
	e.pflags = PFLAGS_FULLDYNAMIC;
	//setmodel(e, "models/runematch/rune.mdl");
	e = spawn();
	e.owner = self;
	e.angles = self.angles;
	setorigin(e, self.origin + v_forward * 30 + v_up * self.maxs_z);
	setmodel(e, "models/it/keyboard.md3");
	e.mins_y = e.mins_x;
	e.maxs_y = e.maxs_x;
	e.scale = 1.1;
	setsize(e, e.mins * e.scale, e.maxs * e.scale);
	e.solid = SOLID_BBOX;
	self.enemy = misc_terminal_chain;
	misc_terminal_chain = self;
}
