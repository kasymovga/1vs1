#define ONS_ROLE_NONE 0
#define ONS_ROLE_DEFENSE 2
#define ONS_ROLE_ASSISTANT 4
#define ONS_ROLE_OFFENSE 8

.float havocbot_role_flags;
.float havocbot_attack_time;
void() onslaught_role_defense;
void() onslaught_role_offense;
void() onslaught_role_assistant;

void(entity bot) onslaught_role_reset;

.float isshielded;
.float iscaptured;
.float islinked;
.float isgenneighbor_blue, iscpneighbor_blue;
.float isgenneighbor_red, iscpneighbor_red;

.entity havocbot_ons_target;

void(float ratingscale, vector org, float sradius) onslaught_role_goalrating_offenseitems {
	entity head, e;
	float t, c = 0, needarmor = FALSE, needweapons = FALSE;

	// Needs armor/health?
	if(self.health<100)
		needarmor = TRUE;

	// Needs weapons?
	WEAPON_INFO_FOR_EACH(e) {
		// Find weapon
		if ((e.weapons & self.weapons) || (e.weapons_extra & self.weapons_extra))
		if (++c>=4)
			break;
	}

	if(c<4)
		needweapons = TRUE;

	if(!needweapons && !needarmor)
		return;

	// See what is around
	head = findchainfloat(bot_pickup, TRUE);
	while (head)
	{
		// gather health and armor only
		if (head.solid)
		if ( ((head.health || head.armorvalue) && needarmor) || (head.weapons && needweapons ) )
		if (vlen(head.origin - org) < sradius)
		{
			t = head.bot_pickupevalfunc(self, head);
			if (t > 0)
				navigation_routerating(head, t * ratingscale, 500);
		}
		head = head.chain;
	}
}

void(entity bot, float role) onslaught_role_setrole {
	switch(role)
	{
		case ONS_ROLE_DEFENSE:
			bot.havocbot_role = onslaught_role_defense;
			bot.havocbot_role_flags = ONS_ROLE_DEFENSE;
			bot.havocbot_role_timeout = 0;
			break;
		case ONS_ROLE_ASSISTANT:
			bot.havocbot_role = onslaught_role_assistant;
			bot.havocbot_role_flags = ONS_ROLE_ASSISTANT;
			bot.havocbot_role_timeout = 0;
			break;
		case ONS_ROLE_OFFENSE:
			bot.havocbot_role = onslaught_role_offense;
			bot.havocbot_role_flags = ONS_ROLE_OFFENSE;
			bot.havocbot_role_timeout = 0;
			break;
	}
}

void(float ratingscale) onslaught_role_goalrating_controlpoints_attack {
	entity cp = NULL, cp1, cp2, best, pl, wp;
	float _radius, found = FALSE, bestvalue, c;
	cp1 = cp2 = findchain(classname, "onslaught_controlpoint");
	// Filter control points
	for (; cp2; cp2 = cp2.chain)
	{
		cp2.wpcost = c = 0;
		cp2.wpconsidered = FALSE;

		if(cp2.isshielded)
			continue;

		// Ignore owned controlpoints
		if(self.team == COLOR_TEAM1)
		{
			if( (cp2.isgenneighbor_blue || cp2.iscpneighbor_blue) && !(cp2.isgenneighbor_red || cp2.iscpneighbor_red) )
				continue;
		}
		else if(self.team == COLOR_TEAM2)
		{
			if( (cp2.isgenneighbor_red || cp2.iscpneighbor_red) && !(cp2.isgenneighbor_blue || cp2.iscpneighbor_blue) )
				continue;
		}

		// Count team mates interested in this control point
		// (easier and cleaner than keeping counters per cp and teams)
		PLAYER_FOR_EACH(pl)
		if(pl.team==self.team)
		if(pl.havocbot_role_flags & ONS_ROLE_OFFENSE)
		if(pl.havocbot_ons_target==cp2)
			++c;

		// NOTE: probably decrease the cost of attackable control points
		cp2.wpcost = c;
		cp2.wpconsidered = TRUE;
	}

	// We'll consider only the best case
	bestvalue = 99999999999;
	for (; cp1; cp1 = cp1.chain)
	{
		if not(cp1.wpconsidered)
			continue;

		if(cp1.wpcost<bestvalue)
		{
			bestvalue = cp1.wpcost;
			cp = cp1;
			self.havocbot_ons_target = cp1;
		}
	}

	if not(cp)
		return;

	if(cp.goalentity)
	{
		// Should be attacked
		// Rate waypoints near it
		found = FALSE;
		best = world;
		bestvalue = 99999999999;
		for(_radius=0; _radius<1000 && !found; _radius+=500)
		{
			for(wp=findradius(cp.origin,_radius); wp; wp=wp.chain)
			{
				if(!(wp.wpflags & WAYPOINTFLAG_GENERATED))
				if(wp.classname=="waypoint")
				if(checkpvs(wp.origin,cp))
				{
					found = TRUE;
					if(wp.cnt<bestvalue)
					{
						best = wp;
						bestvalue = wp.cnt;
					}
				}
			}
		}

		if(best)
		{
			navigation_routerating(best, ratingscale, 10000);
			best.cnt += 1;

			self.havocbot_attack_time = 0;
			if(checkpvs(self.view_ofs,cp))
			if(checkpvs(self.view_ofs,best))
				self.havocbot_attack_time = time + 2;
		}
		else
		{
			navigation_routerating(cp, ratingscale, 10000);
		}
	}
	else
	{
		// Should be touched
		// Look for auto generated waypoint
		if not(bot_waypoints_for_items)
		for (wp = findradius(cp.origin,100); wp; wp = wp.chain)
		{
			if(wp.classname=="waypoint")
			{
				navigation_routerating(wp, ratingscale, 10000);
				found = TRUE;
			}
		}

		// Nothing found, rate the controlpoint itself
		if not(found)
			navigation_routerating(cp, ratingscale, 10000);
	}
}

float(float ratingscale) onslaught_role_goalrating_generator_attack {
	entity g, wp, bestwp;
	float found, best;

	for (g = findchain(classname, "onslaught_generator"); g; g = g.chain)
	{
		if(g.team == self.team || g.isshielded)
			continue;

		// Should be attacked
		// Rate waypoints near it
		found = FALSE;
		bestwp = world;
		best = 99999999999;

		for(wp=findradius(g.origin,400); wp; wp=wp.chain)
		{
			if(wp.classname=="waypoint")
			if(checkpvs(wp.origin,g))
			{
				found = TRUE;
				if(wp.cnt<best)
				{
					bestwp = wp;
					best = wp.cnt;
				}
			}
		}

		if(bestwp)
		{
			navigation_routerating(bestwp, ratingscale, 10000);
			bestwp.cnt += 1;

			self.havocbot_attack_time = 0;
			if(checkpvs(self.view_ofs,g))
			if(checkpvs(self.view_ofs,bestwp))
				self.havocbot_attack_time = time + 5;

			return TRUE;
		}
		else
		{
			navigation_routerating(g, ratingscale, 10000);
			self.havocbot_attack_time = 0;
			return TRUE;
		}
	}
	return FALSE;
}

void() onslaught_role_offense {
	if(self.deadflag != DEAD_NO)
	{
		self.havocbot_attack_time = 0;
		onslaught_role_reset(self);
		return;
	}

	// Set the role timeout if necessary
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 120;

	if (time > self.havocbot_role_timeout)
	{
		onslaught_role_reset(self);
		return;
	}

	if(self.havocbot_attack_time>time)
		return;

	if (self.bot_strategytime < time)
	{
		navigation_goalrating_start();
		havocbot_role_goalrating_enemyplayers(20000, self.origin, 650);
		if(!onslaught_role_goalrating_generator_attack(20000))
			onslaught_role_goalrating_controlpoints_attack(20000);
		onslaught_role_goalrating_offenseitems(10000, self.origin, 10000);
		navigation_goalrating_end();

		self.bot_strategytime = time + bot_ai_strategyinterval;
	}
}

void() onslaught_role_assistant {
	onslaught_role_reset(self);
}

void() onslaught_role_defense {
	onslaught_role_reset(self);
}

void(entity bot) onslaught_role_reset {
	entity head;
	float c;

	if(self.deadflag != DEAD_NO)
		return;

	bot.havocbot_ons_target = world;

	// TODO: Defend control points or generator if necessary

	// if there is only me on the team switch to offense
	c = 0;
	PLAYER_FOR_EACH(head)
	if(head.team==self.team)
		++c;

	if(c==1)
	{
		onslaught_role_setrole(bot, ONS_ROLE_OFFENSE);
		return;
	}

	onslaught_role_setrole(bot, ONS_ROLE_OFFENSE);
}

void() onslaught_role_choose {
	onslaught_role_reset(self);
}
