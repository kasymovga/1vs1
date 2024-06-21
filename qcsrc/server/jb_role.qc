void(float ratingscale, vector org, float sradius) jb_role_goalrating_controlpoints {
	entity head;
	for (head = NULL; (head = find(head, classname, "jb_controlpoint")); ) {
		if (head.team != self.team) {
			navigation_routerating(head, ratingscale, 100000);
		}
	}
}

void(float ratingscale, vector org, float sradius) jb_role_goalrating_enemyplayers {
	entity head;
	float t, distance;
	entity e, e2;
	vector o;
	if (bot_nofire)
		return;

	// don't chase players if we're under water
	if (self.waterlevel>WATER_LEVEL_WETFEET)
		return;

	PLAYER_FOR_EACH (head) {
		if (self != head)
		if (head.health > 0 && !JB_PLAYER_JAILED(head))
		if ((!bot_ignore_bots || clienttype(head) == CLIENTTYPE_REAL) && head.team != self.team) {
			e = player_entity(head);
			distance = vlen(e.origin - org);
			if (distance < 100 || distance > sradius)
				continue;

			if ((e.flags & FL_INWATER) || (e.flags & FL_PARTIALGROUND))
				continue;

			o = ENTITY_CENTER(e);
			// not falling
			if not(e.flags & FL_ONGROUND) {
				trace_line(o, o + '0 0 -1500', TRUE, world);
				t = pointcontents(trace_endpos + '0 0 1');
				if (t != CONTENT_SOLID)
				if ((t == CONTENT_WATER) || (t == CONTENT_SLIME) || (t == CONTENT_LAVA))
					continue;

				if (trigger_tracebox_hits_hurt(e.origin, e.mins, e.maxs, trace_endpos))
					continue;
			}
			for (e2 = findradius(o, 1); e2; e2 = e2.chain) {
				if (e2.classname == "jb_room") break;
			};
			if (e2) continue;
			t = (self.health + self.armorvalue ) / (head.health + head.armorvalue );
			navigation_routerating(e, t * ratingscale, 2000);
		}
	}
}

void() jb_role {
	if (self.deadflag != DEAD_NO)
		return;

	if (JB_PLAYER_JAILED(self)) {
		bot_stay(self, 0.1);
		return;
	}
	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		entity head;
		float somebodyjailed = FALSE;
		if ((self.team == COLOR_TEAM1 && !jb_open_red) || (self.team == COLOR_TEAM2 && !jb_open_blue))
			PLAYER_FOR_EACH (head) {
				if (head.team == self.team && JB_PLAYER_JAILED(head)) {
					somebodyjailed = TRUE;
					break;
				}
			}
		if (somebodyjailed) {
			jb_role_goalrating_controlpoints(10000, self.origin, 15000);
		} else {
			havocbot_role_goalrating_items(8000, self.origin, 8000);
			jb_role_goalrating_enemyplayers(8000, self.origin, 2000);
		}
		navigation_goalrating_end();
	}
}

void() jb_role_choose {
	self.havocbot_role = jb_role;
}
