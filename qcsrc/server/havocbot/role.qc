float bot_ai_friends_aware_pickup_radius;

.float max_armorvalue;
.float havocbot_role_timeout;

.void() havocbot_previous_role;
.void() havocbot_role;

void(float ratingscale, vector org, float sradius) havocbot_role_goalrating_items {
	entity head;
	entity player;
	float rating, d, discard, distance, friend_distance, enemy_distance;
	ratingscale = ratingscale * 0.0001; // items are rated around 10000 already
	head = findchainfloat(bot_pickup, TRUE);
	while (head) {
		distance = vlen(head.origin - org);
		friend_distance = 10000; enemy_distance = 10000;
		rating = 0;
		if (!head.solid || distance > sradius || (head == self.ignoregoal && time < self.ignoregoaltime) ) {
			head = head.chain;
			continue;
		}
		// Check if the item can be picked up safely
		if (head.classname == "droppedweapon") {
			trace_line(head.origin, head.origin + '0 0 -1500', TRUE, world);
			d = pointcontents(trace_endpos + '0 0 1');
			if (d & CONTENT_WATER || d & CONTENT_SLIME || d & CONTENT_LAVA) {
				head = head.chain;
				continue;
			}
			if (trigger_tracebox_hits_hurt(head.origin, head.mins, head.maxs, trace_endpos)) {
				head = head.chain;
				continue;
			}
		} else {
			// Ignore items under water
			trace_line(head.origin + head.maxs, head.origin + head.maxs, TRACE_MOVE_NORMAL, head);
			if (trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK) {
				head = head.chain;
				continue;
			}
		}
		if (team_mode) {
			discard = FALSE;
			FOR_EACH_PLAYER(player) {
				if ( self == player || player.deadflag )
					continue;

				d = vlen(player.origin - head.origin); // distance between player and item
				if (player.team == self.team ) {
					if ( clienttype(player) != CLIENTTYPE_REAL || discard )
						continue;

					if ( d > friend_distance)
						continue;

					friend_distance = d;

					discard = TRUE;

					if ( head.health && player.health > self.health )
						continue;

					if ( head.armorvalue && player.armorvalue > self.armorvalue)
						continue;

					if ( head.weapons )
					if ( (player.weapons & head.weapons) != head.weapons)
						continue;

					if (head.ammo_shells && player.ammo_shells > self.ammo_shells)
						continue;

					if (head.ammo_nails && player.ammo_nails > self.ammo_nails)
						continue;

					if (head.ammo_rockets && player.ammo_rockets > self.ammo_rockets)
						continue;

					if (head.ammo_cells && player.ammo_cells > self.ammo_cells )
						continue;

					discard = FALSE;
				} else {
					// If enemy only track distances
					// TODO: track only if visible ?
					if ( d < enemy_distance )
						enemy_distance = d;
				}
			}
			// Rate the item only if no one needs it, or if an enemy is closer to it
			if ((enemy_distance < friend_distance && distance < enemy_distance) ||
				(friend_distance > bot_ai_friends_aware_pickup_radius ) || !discard )
				rating = head.bot_pickupevalfunc(self, head);

		} else
			rating = head.bot_pickupevalfunc(self, head);

		if (rating > 0)
			navigation_routerating(head, rating * ratingscale, 2000);

		head = head.chain;
	}
}

void(float ratingscale, vector org, float sradius) havocbot_role_goalrating_enemyplayers {
	entity head;
	float t, noteam, distance;
	entity e;
	noteam = ((self.team == 0) || !team_mode); // fteqcc sucks
	if (bot_nofire)
		return;

	// don't chase players if we're under water
	if (self.waterlevel>WATER_LEVEL_WETFEET)
		return;

	FOR_EACH_PLAYER(head) {
		// TODO: Merge this logic with the bot_shouldattack function
		if (self != head)
		if (head.health > 0)
		if ((noteam && (!bot_ignore_bots || clienttype(head) == CLIENTTYPE_REAL)) || head.team != self.team) {
			e = player_entity(head);
			distance = vlen(e.origin - org);
			if (distance < 100 || distance > sradius)
				continue;

			if ((e.flags & FL_INWATER) || (e.flags & FL_PARTIALGROUND))
				continue;

			// not falling
			if not(e.flags & FL_ONGROUND) {
				trace_line(e.origin, e.origin + '0 0 -1500', TRUE, world);
				t = pointcontents(trace_endpos + '0 0 1');
				if (t != CONTENT_SOLID)
				if ((t == CONTENT_WATER) || (t == CONTENT_SLIME) || (t == CONTENT_LAVA))
					continue;

				if (trigger_tracebox_hits_hurt(e.origin, e.mins, e.maxs, trace_endpos))
					continue;
			}
			t = (self.health + self.armorvalue ) / (head.health + head.armorvalue );
			navigation_routerating(e, t * ratingscale, 2000);
		}
	}
}

// choose a role according to the situation
void() havocbot_role_dm;

//DM:
//go to best items
void() havocbot_role_dm {
	if (self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_role_goalrating_items(10000, self.origin, 10000);
		havocbot_role_goalrating_enemyplayers(20000, self.origin, 10000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
}

void(void) havocbot_role_choose_dm {
	self.havocbot_role = havocbot_role_dm;
}

void(void) havocbot_role_choose {
	navigation_clearroute();
	self.bot_strategytime = 0;
	plugin_havocbot_role_choose();
}

void(void) havocbot_role_init {
	CVAR_CACHE(bot_ai_friends_aware_pickup_radius);
}
