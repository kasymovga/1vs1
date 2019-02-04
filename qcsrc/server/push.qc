float g_push_damage;
float g_push_damage_speed;
float g_push_trampledamage;
float g_push_trampledamage_speed;

void(void) push_touch {
	if not(other)
		return;

	float _pushfactor = min(1, other.pushfactor * (0.5 / self.pushfactor));

	if not(_pushfactor > 0)
	if not(other.takedamage)
		return;

	float damage, damage_speed;
	vector velocity_norm = normalize(self.velocity);
	if (velocity_norm * trace_plane_normal >= 0) //wrong direction
		return;

	vector push_velocity = self.velocity * _pushfactor - velocity_norm * max(0, velocity_norm * other.velocity);
	if (normalize(push_velocity) * trace_plane_normal >= 0) //wrong direction
		return;

	if (trace_plane_normal == '0 0 1') {
		damage = g_push_trampledamage;
		damage_speed = g_push_trampledamage_speed;
		push_velocity_x = 0;
		push_velocity_y = 0;
	} else {
		damage = g_push_damage;
		damage_speed = g_push_damage_speed;
	}
	float push_speed = vlen(push_velocity);
	if (push_speed > damage_speed * _pushfactor && damage > 0 && other.takedamage)
		Damage(other, self, self, damage * (push_speed / damage_speed), DEATH_FALL, other.origin, push_velocity);
	else
		other.velocity = other.velocity + push_velocity;
}

void(void) push_init {
	CACHE_CVAR(g_push_damage);
	CACHE_CVAR(g_push_damage_speed);
	CACHE_CVAR(g_push_trampledamage);
	CACHE_CVAR(g_push_trampledamage_speed);
}
