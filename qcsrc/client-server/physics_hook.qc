var float(float maxspd_mod) physics_hook_next;
float(float maxspd_mod) physics_hook {
	vector v, v0, dir;
	float dist;
	float newlength;
	vector end;
	entity _hook = hook_get();
	float r = (physics_hook_next ? physics_hook_next(maxspd_mod) : 0);
	float spd;
	if not(_hook)
		return r;

	hook_physics_pre(_hook, self);
	dist = vlen(_hook.origin - self.origin);
	dir = normalize(_hook.origin - self.origin);
	if (g_grappling_hook_tarzan) {
		if (physics_hook_old_length < 0)
			physics_hook_old_length = dist;

		v0 = v = physics_velocity;
		// first pull the rope...
		if not(physics_button_crouch)
			newlength = max(physics_hook_old_length - g_balance_grapplehook_speed_pull * frametime, g_balance_grapplehook_length_min);
		else
			newlength = physics_hook_old_length;

		// then pull the player
		spd = bound(0, (dist - newlength) / g_balance_grapplehook_stretch, 1);
		physics_hook_old_length = newlength;
		if not(g_balance_grapplehook_dontpull) {
			v = v * (1 - frametime * g_balance_grapplehook_airfriction);
			if (v * dir < 0) {
				v = v + dir * (frametime * spd * g_balance_grapplehook_force_rubber_overstretch);
			}
			v = v + dir * (frametime * spd * g_balance_grapplehook_force_rubber);
		}
		if (g_grappling_hook_tarzan >= 2) {
			hook_pull_aiment(_hook, v, v0, dir);
		}
		physics_velocity = v;
	} else {
		end = _hook.origin - dir * 50;
		dist = vlen(end - _hook.origin);
		if(dist < 200)
			spd = dist * (g_balance_grapplehook_speed_pull / 200);
		else
			spd = g_balance_grapplehook_speed_pull;

		if(spd < 50)
			spd = 0;

		physics_velocity = dir * spd;
	}
	physics_velocity = v;
	hook_physics_post(_hook, self);
	return r;
}

float physics_hook_enabled;
void(void) physics_hook_enable {
	if (physics_hook_enabled)
		return;

	physics_hook_enabled = 1;
	physics_hook_next = physics_player_plug;
	physics_player_plug = physics_hook;
}
