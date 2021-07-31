float g_teleport_projectiles;
float g_teleport_keep_velocity;
float g_telefrags;

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
	for(head = findradius(player.origin, deathradius); head; head = head.chain)
		if(head != player)
			if(head.takedamage)
				if(math_boxes_overlap(deathmin, deathmax, head.absmin, head.absmax))
				{
					if ((player.classname == "player") && (player.health >= 1))
					{
						if(head.classname == "player")
						if(head.health >= 1)
						if not(team_mode && head.team == player.team) {
							++teleport_death_hit;
							damage (head, teleporter, telefragger, _damage, WEP_PORTO, head.origin, '0 0 0');
						}
					}
					else if (telefragger.health < 1) // corpses gib
						damage (head, teleporter, telefragger, _damage, WEP_PORTO, head.origin, '0 0 0');
					else // dead bodies and monsters gib themselves instead of telefragging
						damage (telefragger, teleporter, telefragger, 10000, WEP_PORTO, telefragger.origin, '0 0 0');
				}
}

void(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float _damage) teleport {
	entity telefragger;
	vector from;
	if(teleporter.owner)
		telefragger = teleporter.owner;
	else
		telefragger = player;

	makevectors (to_angles);
	if(self.pushltime < time) // only show one teleport effect per teleporter per 0.2 seconds, for better fps
	{
		sound (player, CHAN_TRIGGER, "misc/teleport.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("teleport"), player.origin, '0 0 0', 1);
		pointparticles(particleeffectnum("teleport"), to + v_forward * 32, '0 0 0', 1);
		self.pushltime = time + 0.2;
	}
	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
	from = player.origin;
	setorigin (player, to);
	player.oldorigin = to; // don't undo the teleport by unsticking
	player.angles = to_angles;
	player.fixangle = TRUE;
	player.velocity = to_velocity;
	BITXOR_ASSIGN(player.effects, EFFECT_TELEPORT_BIT);
	antilag_teleported(player);
	projectile_update_after_teleport(player);
	physics_mark_as_teleported(player, 0.1);
	if(player.classname == "player") {
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
		if(player.isbot)
			player.lastteleporttime = time;
	}
}

void(void) teleport_use {
	if (team_mode)
		self.team = activator.team;
}

void(void) teleport_touch {
	entity oldself, e;
	vector v;
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
	if(self.team)
		if((self.spawnflags & 4 == 0) == (self.team != other.team))
			return;

	TRIGGER_EXACT_TOUCH;
	if(other.classname == "player")
		hook_remove(other);

	if(self.enemy) {
		e = self.enemy;
	} else {
		random_selection_init();
		for(e = world; (e = find(e, targetname, self.target)); )
		{
			if(e.cnt)
				random_selection_add(e, 0, NULL, e.cnt, 0);
			else
				random_selection_add(e, 0, NULL, 1, 0);
		}
		e = random_selection_chosen_ent;
	}
	if(!e) {
		sprint(other, "Teleport destination vanished. Sorry... please complain to the mapper.\n");
	}
	makevectors(e.angles);
	if(e.speed)
		if(vlen(other.velocity) > e.speed)
			other.velocity = normalize(other.velocity) * max(0, e.speed);

	if (g_teleport_keep_velocity > 0)
		v = v_forward * min(g_teleport_keep_velocity, vlen(other.velocity));
	else if (g_teleport_keep_velocity < 0)
		v = v_forward * vlen(other.velocity);
	else
		v = '0 0 0';

	teleport(self, other, e.origin + '0 0 1' * (1 - other.mins_z - 24), e.angles, v, '0 0 0', '0 0 0', 10000);
	if(e.target) {
		oldself = self;
		activator = other;
		self = e;
		trigger_use_targets();
		self = oldself;
	}
}

void(void) teleport_findtarget {
	entity e;
	float n;

	n = 0;
	for(e = world; (e = find(e, targetname, self.target)); )
	{
		++n;
		if(e.movetype == MOVETYPE_NONE)
			waypoint_spawnforteleporter(self, e.origin, 0);
	}

	if(n == 0)
	{
		// no dest!
		entity_abort("Teleporter with nonexistant target");
		return;
	}
	else if(n == 1)
	{
		// exactly one dest - bots love that
		self.enemy = find(e, targetname, self.target);
		self.dest = self.enemy.origin;
	}
	else
	{
		// have to use random selection every single time
		self.enemy = world;
	}

	// now enable touch
	self.touch = teleport_touch;
}

void(void) teleport_init {
	CVAR_CACHE(g_teleport_keep_velocity);
	CVAR_CACHE(g_teleport_projectiles);
	CVAR_CACHE(g_telefrags);
}

void(void) teleport_setup {
	self.angles = '0 0 0';
	trigger_solid_brush_init();
	self.use = teleport_use;
	// this must be called to spawn the teleport waypoints for bots
	entity_initialize(self, teleport_findtarget, INITPRIO_FINDTARGET);
	if (!self.target) {
		entity_abort("Teleporter with no target");
		return;
	}
}
