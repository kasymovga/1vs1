void() kh_role_carrier;
void() kh_role_defense;
void() kh_role_offense;
void() kh_role_freelancer;

entity kh_worldkeylist;
.entity kh_worldkeynext;

void(float ratingscale_team, float ratingscale_dropped, float ratingscale_enemy) havocbot_goalrating_kh {
	entity head;
	for (head = kh_worldkeylist; head; head = head.kh_worldkeynext)
	{
		if(head.owner == self)
			continue;
		if(!kh_tracking_enabled)
		{
			// if it's carried by our team we know about it
			// otherwise we have to see it to know about it
			if(!head.owner || head.team != self.team)
			{
				trace_line(self.origin + self.view_ofs, head.origin, MOVE_NOMONSTERS, self);
				if (trace_fraction < 1 && trace_ent != head)
					continue; // skip what I can't see
			}
		}
		if(!head.owner)
			navigation_routerating(head, ratingscale_dropped * BOT_PICKUP_RATING_HIGH, 100000);
		else if(head.team == self.team)
			navigation_routerating(head.owner, ratingscale_team * BOT_PICKUP_RATING_HIGH, 100000);
		else
			navigation_routerating(head.owner, ratingscale_enemy * BOT_PICKUP_RATING_HIGH, 100000);
	}

	havocbot_goalrating_items(1, self.origin, 10000);
}

void() kh_role_carrier {
	if(self.deadflag != DEAD_NO)
		return;

	if (!(self.kh_next))
	{
		self.havocbot_role = kh_role_freelancer;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();

		if(kh_Key_AllOwnedByWhichTeam() == self.team)
			havocbot_goalrating_kh(10, 0.1, 0.1); // bring home
		else
			havocbot_goalrating_kh(4, 4, 1); // play defensively

		navigation_goalrating_end();
	}
}

void() kh_role_defense {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.kh_next)
	{
		self.havocbot_role = kh_role_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 20;
	if (time > self.havocbot_role_timeout)
	{
		self.havocbot_role = kh_role_freelancer;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (self.bot_strategytime < time)
	{
		float key_owner_team;
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();

		key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if(key_owner_team == self.team)
			havocbot_goalrating_kh(10, 0.1, 0.1); // defend key carriers
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(4, 1, 0.1); // play defensively
		else
			havocbot_goalrating_kh(0.1, 0.1, 10); // ATTACK ANYWAY

		navigation_goalrating_end();
	}
}

void() kh_role_offense {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.kh_next)
	{
		self.havocbot_role = kh_role_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 20;
	if (time > self.havocbot_role_timeout)
	{
		self.havocbot_role = kh_role_freelancer;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (self.bot_strategytime < time)
	{
		float key_owner_team;

		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();

		key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if(key_owner_team == self.team)
			havocbot_goalrating_kh(10, 0.1, 0.1); // defend anyway
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(0.1, 1, 4); // play offensively
		else
			havocbot_goalrating_kh(0.1, 0.1, 10); // ATTACK! EMERGENCY!

		navigation_goalrating_end();
	}
}

void() kh_role_freelancer {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.kh_next)
	{
		self.havocbot_role = kh_role_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 10;
	if (time > self.havocbot_role_timeout)
	{
		if (random() < 0.5)
			self.havocbot_role = kh_role_offense;
		else
			self.havocbot_role = kh_role_defense;

		self.havocbot_role_timeout = 0;
		return;
	}

	if (self.bot_strategytime < time)
	{
		float key_owner_team;

		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();

		key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if(key_owner_team == self.team)
			havocbot_goalrating_kh(10, 0.1, 0.1); // defend anyway
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(1, 10, 4); // prefer dropped keys
		else
			havocbot_goalrating_kh(0.1, 0.1, 10); // ATTACK ANYWAY

		navigation_goalrating_end();
	}
}

void() kh_role_choose {
	float r;

	if(self.deadflag != DEAD_NO)
		return;

	r = random() * 3;
	if (r < 1)
		self.havocbot_role = kh_role_offense;
	else if (r < 2)
		self.havocbot_role = kh_role_defense;
	else
		self.havocbot_role = kh_role_freelancer;
}
