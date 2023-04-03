// RED - INPUT
// BLUE - OUTPUT
float g_balance_porto_primary_animtime;
float g_balance_porto_primary_lifetime;
float g_balance_porto_primary_refire;
float g_balance_porto_primary_speed;
float g_balance_porto_old;
float g_balance_porto_remove_on_death;
float g_balance_powerup_strength_force;
string sv_announcer_extra_telefrag;

.entity porto_current_in;
.entity porto_current_out;
.vector right_vector;

void(void) weapon_porto_success {
	if (self.owner == world) {
		entity_abort("Cannot succeed successfully: no owner\n");
		return;
	}
	if (self.effects & EFFECT_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;

	if (!g_balance_porto_old || (self.projectiledeathtype & HITTYPE_BOUNCE)) {
		remove(self);
	} else {
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		BITXOR_ASSIGN(self.effects, EFFECT_RED);
		projectile_update_with_type(self, ((self.effects & EFFECT_RED) ? PROJECTILE_PORTO_RED : PROJECTILE_PORTO_BLUE));
	}
}

void(void) weapoon_porto_fail {
	if (self.owner == world) {
		entity_abort("Cannot fail successfully: no owner\n");
		return;
	}
	if (self.effects & EFFECT_RED)
		self.owner.porto_current_in = world;
	else
		self.owner.porto_current_out = world;

	remove(self);
}

void(entity p) weapon_porto_remove {
	entity oldself;
	oldself = self;
	if (p.porto_current_in) {
		self = p.porto_current_in;
		weapoon_porto_fail();
	}
	if (p.porto_current_out) {
		self = p.porto_current_out;
		weapoon_porto_fail();
	}
	self = oldself;
}

void(void) weapon_porto_think {
	trace_plane_normal = '0 0 0';
	if (self.owner.playerid != self.playerid)
		remove(self);
	else
		weapoon_porto_fail();
}

void(void) weapon_porto_touch {
	PROJECTILE_SKIPNONSOLID
	vector norm;
	// do not use PROJECTILE_TOUCH here
	if (other.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if (other) {
		if (other.iscreature) {
			trace_line(other.origin + '0 0 1' * other.mins_z + '0 0 1', other.origin + '0 0 1' * other.mins_z + '0 0 -1', TRACE_MOVE_WORLDONLY, self);
			if (trace_fraction >= 1)
				return;

			if ((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP))
				return;

			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
				return;
		} else if (trace_dphitcontents == 0) //something touching projectile
			return;
	}
	if (self.owner.playerid != self.playerid) {
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		remove(self);
	} else if ((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP)) {
		sound_spam(self, CHAN_PROJECTILE, "porto/bounce.wav", VOL_BASE, ATTN_NORM);
		// just reflect
		self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * trace_plane_normal);
		self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * trace_plane_normal));
	} else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) {
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		weapoon_porto_fail();
	} else if (self.effects & EFFECT_RED) {
		if (portal_spawn_in_portal_at_trace(self.owner, self.right_vector)) {
			self.portal_id = self.owner.portal_in.portal_id;
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			centerprint(self.owner, "^1In^7-portal created.");
			weapon_porto_success();
		} else {
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			weapoon_porto_fail();
		}
	} else {
		if (portal_spawn_out_portal_at_trace(self.owner, self.right_vector)) {
			//self.portal_id = self.owner.portal_out.portal_id;
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			centerprint(self.owner, "^4Out^7-portal created.");
			weapon_porto_success();
		} else {
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			weapoon_porto_fail();
		}
	}
}

void(float out) weapon_porto_attack {
	entity gren;
	weapon_setup_shot (self, 4, "porto/fire.wav", 0);
	// always shoot from the eye
	weapon_shotdir = v_forward;
	weapon_shotorg = self.origin + self.view_ofs + ((weapon_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	gren = projectile(TRUE, (out ? PROJECTILE_PORTO_BLUE : PROJECTILE_PORTO_RED), TRUE, self);
	gren.movetype = MOVETYPE_BOUNCEMISSILE;
	gren.playerid = self.playerid;
	gren.classname = "porto";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = 200;
	PROJECTILE_MAKETRIGGER(gren);
	if (out) {
		gren.effects = EFFECT_BLUE;
		self.porto_current_out = gren;
	} else {
		gren.effects = EFFECT_RED;
		self.porto_current_in = gren;
	}
	gren.scale = 4;
	setorigin(gren, weapon_shotorg);
	gren.nextthink = time + g_balance_porto_primary_lifetime;
	gren.think = weapon_porto_think;
	gren.touch = weapon_porto_touch;
	gren.velocity = weapon_shotdir * g_balance_porto_primary_speed;
	if (self.items & IT_STRENGTH)
		gren.velocity = gren.velocity * g_balance_powerup_strength_force;

	weapon_setup_projectile_velocity(gren);
	gren.playerid = self.playerid;
	makevectors(vectoangles(gren.velocity));
	gren.right_vector = v_right;
	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

void(void) spawnfunc_weapon_porto {
	weapon_defaultspawnfunc(WEAPON_PORTO);
}

float(float req) weapon_porto {
	if (req == WEAPON_REQUEST_AIM) {
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if (bot_aim(g_balance_porto_primary_speed, 0, g_balance_porto_primary_lifetime, FALSE))
			self.BUTTON_ATCK = TRUE;
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.BUTTON_ATCK)
		if (!self.porto_current_in)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire)) {
			weapon_porto_attack(FALSE);
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_porto_primary_animtime, weapon_ready);
		}
		if (self.BUTTON_ATCK2)
		if (!self.porto_current_out)
		if (weapon_prepareattack(0, g_balance_porto_primary_refire)) {
			weapon_porto_attack(TRUE);
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_porto_primary_animtime, weapon_ready);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_model("models/portal.md3");
		precache_sound("porto/bounce.wav");
		precache_sound("porto/create.wav");
		precache_sound("porto/expire.wav");
		precache_sound("porto/explode.wav");
		precache_sound("porto/fire.wav");
		precache_sound("porto/unsupported.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_fragprefix = "^6TELE";
		weapon_deathtypestring = "was telefragged by";
		weapon_fragannounce = sv_announcer_extra_telefrag;
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		self.porto_current_in = world;
		self.porto_current_out = world;
	} else if (req == WEAPON_REQUEST_CLEAR) {
		if (g_balance_porto_remove_on_death)
			weapon_porto_remove(self);
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_porto_primary_animtime);
		CVAR_CACHE(g_balance_porto_primary_lifetime);
		CVAR_CACHE(g_balance_porto_primary_refire);
		CVAR_CACHE(g_balance_porto_primary_speed);
		CVAR_CACHE(g_balance_porto_old);
		CVAR_CACHE(g_balance_porto_remove_on_death);
		CVAR_CACHE(g_balance_powerup_strength_force);
		CVAR_CACHE_STR(sv_announcer_extra_telefrag);
		if (sv_announcer_extra_telefrag != "")
			precache_sound(sv_announcer_extra_telefrag);

		projectile_init(PROJECTILE_PORTO_RED);
		projectile_init(PROJECTILE_PORTO_BLUE);
	}
	return TRUE;
}
