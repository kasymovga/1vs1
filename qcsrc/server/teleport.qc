float g_teleport_projectiles;
float g_teleport_keep_velocity;
float g_teleport_time;
float g_teleport_prediction;
float g_telefrags;

void(entity e, vector v, float t) teleport_origin_set {
	setorigin(e, v);
	// don't reset back to last position, even if new position is stuck in solid
	e.oldorigin = e.origin;
	antilag_teleported(e);
	plugin_chain_teleport_origin_set(e);
	physics_mark_as_teleported(e, t);
	BITXOR_ASSIGN(e.effects, EFFECT_TELEPORT_BIT);
	projectile_update_after_teleport(e);
	navigation_teleported(e);
}

void(entity player, entity teleporter, entity telefragger, vector telefragmin, vector telefragmax, float _damage) teleport_death {
	entity head;
	vector deathmin;
	vector deathmax;
	float deathradius;
	deathmin = player.absmin;
	deathmax = player.absmax;
	if(telefragmin != telefragmax) {
		if(deathmin_x > telefragmin_x) deathmin_x = telefragmin_x;
		if(deathmin_y > telefragmin_y) deathmin_y = telefragmin_y;
		if(deathmin_z > telefragmin_z) deathmin_z = telefragmin_z;
		if(deathmax_x < telefragmax_x) deathmax_x = telefragmax_x;
		if(deathmax_y < telefragmax_y) deathmax_y = telefragmax_y;
		if(deathmax_z < telefragmax_z) deathmax_z = telefragmax_z;
	}
	deathradius = max(vlen(deathmin), vlen(deathmax));
	for (head = findradius(player.origin, deathradius); head; head = head.chain)
		if (head != player)
			if (head.takedamage)
				if(math_boxes_overlap(deathmin, deathmax, head.absmin, head.absmax)) {
					if ((player.classname == "player") && (player.health >= 1)) {
						if(head.classname == "player")
						if(head.health >= 1)
						if not(team_mode && head.team == player.team) {
							++teleport_death_hit;
							damage (head, teleporter, telefragger, _damage, WEAPON_PORTO, head.origin, '0 0 0');
						}
					} else if (telefragger.health < 1) // corpses gib
						damage (head, teleporter, telefragger, _damage, WEAPON_PORTO, head.origin, '0 0 0');
					else // dead bodies and monsters gib themselves instead of telefragging
						damage (telefragger, teleporter, telefragger, 10000, WEAPON_PORTO, telefragger.origin, '0 0 0');
				}
}

void(entity teleporter, entity to, vector to_angles) teleport_teleportation_send {
	msg_entity = to;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_TELEPORTATION);
	net_write_coord(MSG_ONE, num_for_edict(teleporter));
	net_write_coord(MSG_ONE, to_angles_x);
	net_write_coord(MSG_ONE, to_angles_y);
}

void(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float _damage) teleport {
	entity telefragger;
	vector from;
	if (teleporter && teleporter.owner)
		telefragger = teleporter.owner;
	else
		telefragger = player;

	makevectors (to_angles);
	if (self.pushltime < time) { // only show one teleport effect per teleporter per 0.2 seconds, for better fps
		sound (player, CHAN_TRIGGER, "misc/teleport.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("teleport"), player.origin, '0 0 0', 1);
		pointparticles(particleeffectnum("teleport"), to + v_forward * 32, '0 0 0', 1);
		self.pushltime = time + 0.2;
	}
	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
	from = player.origin;
	setorigin (player, to);
	teleport_origin_set(player, to, g_teleport_time);
	//player.angles = to_angles;
	if (g_teleport_prediction && teleporter)
		teleport_teleportation_send(teleporter, player, to_angles);
	else
		client_view_angles_set(player, to_angles);

	player.velocity = to_velocity;
	if (player.classname == "player") {
		if (g_telefrags)
		if (player.takedamage)
		if (player.deadflag == DEAD_NO)
			teleport_death(player, teleporter, telefragger, telefragmin, telefragmax, _damage);

		// player no longer is on ground
		player.flags &= ~FL_ONGROUND;
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		player.oldvelocity = player.velocity;
		// reset tracking of who pushed you into a hazard (for kill credit)
		if(teleporter.owner) {
			player.pusher = teleporter.owner;
			player.pushltime = time + g_maxpushtime;
		} else {
			player.pushltime = 0;
		}
	} else if (player.flags & FL_PROJECTILE) {
		player.lastpushtime = time;
	}
}

void(void) teleport_use {
	if (team_mode)
		self.team = activator.team;
}

void(void) teleport_touch {
	entity oldself, e;
	float f;
	if (other.iscreature)
	if (other.health < 1)
		return;

	if not(other.iscreature || (g_teleport_projectiles && (other.flags & FL_PROJECTILE)))
		return;

	if (other.classname != "player") {
		if (other.mins_x < PL_MIN_x)
			return;

		if (other.mins_y < PL_MIN_y)
			return;

		if (other.mins_z < PL_MIN_z)
			return;

		if (other.maxs_x > PL_MAX_x)
			return;

		if (other.maxs_y > PL_MAX_y)
			return;

		if (other.maxs_z > PL_MAX_z)
			return;
	}
	if (self.team)
		if (((self.spawnflags & 4) == 0) == (self.team != other.team))
			return;

	TRIGGER_EXACT_TOUCH;
	if (self.enemy) {
		e = self.enemy;
	} else {
		random_selection_init();
		for(e = world; (e = find(e, targetname, self.target)); ) {
			if(e.cnt)
				random_selection_add(e, 0, NULL, e.cnt, 0);
			else
				random_selection_add(e, 0, NULL, 1, 0);
		}
		e = random_selection_chosen_ent;
	}
	if (!e) {
		sprint(other, "Teleport destination vanished. Sorry... please complain to the mapper.\n");
	}
	makevectors(e.angles);
	f = vlen(other.velocity);
	if (e.speed_str != "" || self.speed)
		f = min(f, max(0, e.speed));

	if (self.spawnflags & 2)
		f = min(f, vlen(other.velocity_x * '1 0 0' + other.velocity_y * '0 1 0'));
	else if (g_teleport_keep_velocity > 0)
		f = min(g_teleport_keep_velocity, vlen(other.velocity));
	else if (g_teleport_keep_velocity == 0)
		f = 0;

	teleport(self, other, e.origin + '0 0 1' * (1 - other.mins_z - 24), e.angles, v_forward * f, '0 0 0', '0 0 0', 10000);
	if (e.target) {
		oldself = self;
		activator = other;
		self = e;
		trigger_use_targets();
		self = oldself;
	}
}

float(entity to, float sf) teleport_prediction_send {
	entity o = self.owner;
	net_write_byte(MSG_ENTITY, NET_CSQC_TELEPORT_PREDICTION);
	net_write_coord(MSG_ENTITY, num_for_edict(o));
	net_write_coord(MSG_ENTITY, o.modelindex);
	net_write_coord(MSG_ENTITY, o.origin_x);
	net_write_coord(MSG_ENTITY, o.origin_y);
	net_write_coord(MSG_ENTITY, o.origin_z);
	net_write_coord(MSG_ENTITY, o.mins_x);
	net_write_coord(MSG_ENTITY, o.mins_y);
	net_write_coord(MSG_ENTITY, o.mins_z);
	net_write_coord(MSG_ENTITY, o.maxs_x);
	net_write_coord(MSG_ENTITY, o.maxs_y);
	net_write_coord(MSG_ENTITY, o.maxs_z);
	if (o.spawnflags & 2)
		net_write_coord(MSG_ENTITY, -2);
	else
		net_write_coord(MSG_ENTITY, ((o.speed_str == "") ? -1 : o.speed));

	net_write_coord(MSG_ENTITY, o.enemy.origin_x);
	net_write_coord(MSG_ENTITY, o.enemy.origin_y);
	net_write_coord(MSG_ENTITY, o.enemy.origin_z);
	net_write_coord(MSG_ENTITY, o.enemy.angles_x);
	net_write_coord(MSG_ENTITY, o.enemy.angles_y);
	net_write_coord(MSG_ENTITY, g_teleport_keep_velocity);
	net_write_coord(MSG_ENTITY, g_teleport_time);
	return TRUE;
}

void(void) teleport_findtarget {
	entity e;
	float n;
	n = 0;
	for (e = world; (e = find(e, targetname, self.target)); ) {
		++n;
		if (e.movetype == MOVETYPE_NONE)
			waypoint_spawnforteleporter(self, e.origin, 0);
	}
	if (n == 0) {
		// no dest!
		entity_abort("Teleporter with nonexistant target");
		return;
	} else if (n == 1) {
		// exactly one dest - bots love that
		self.enemy = find(e, targetname, self.target);
		self.dest = self.enemy.origin;
	} else {
		// have to use random selection every single time
		self.enemy = world;
	}
	// now enable touch
	self.touch = teleport_touch;
	if (g_teleport_prediction && self.enemy && self.enemy.movetype == MOVETYPE_NONE) {
		entity e = spawn();
		e.owner = self;
		e.existsonlyfor = self.existsonlyfor;
		setsize(e, e.owner.mins, e.owner.maxs);
		net_link_entity(e, TRUE, 0, teleport_prediction_send);
		e.culltracemode = CULLTRACEMODE_NONE;
	}
}

void(void) teleport_init {
	CVAR_CACHE(g_teleport_keep_velocity);
	CVAR_CACHE(g_teleport_projectiles);
	CVAR_CACHE(g_teleport_time);
	CVAR_CACHE(g_telefrags);
	CVAR_CACHE(g_teleport_prediction);
}

void(void) teleport_setup {
	self.angles = '0 0 0';
	trigger_solid_brush_init();
	self.use = teleport_use;
	// this must be called to spawn the teleport waypoints for bots
	if (self.target == "") {
		entity_abort("Teleporter with no target");
		return;
	}
	entity_initialize(self, teleport_findtarget, INITPRIO_FINDTARGET);
}
