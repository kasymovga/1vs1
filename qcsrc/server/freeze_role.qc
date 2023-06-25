void(float ratingscale, vector org, float sradius) freeze_role_goalrating_frozen_teammates {
	entity head;
	float distance;

	// don't chase players if we're under water
	if(self.waterlevel>WATER_LEVEL_WETFEET)
		return;

	FOR_EACH_PLAYER(head)
	{
		if (self != head)
		if (head.deadflag == DEAD_FREEZE)
		if (head.team == self.team)
		{
			distance = vlen(head.origin - org);
			if (distance < 50 || distance > sradius)
				continue;

			if(head.flags & FL_INWATER || head.flags & FL_PARTIALGROUND)
				continue;

			// not falling
			if(head.flags & FL_ONGROUND == 0)
				continue;

			navigation_routerating(head, ratingscale, 5000);
			break;
		}
	}
}

void() freeze_role {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		freeze_role_goalrating_frozen_teammates(15000, self.origin, 8000);
		havocbot_role_goalrating_items(8000, self.origin, 8000);
		havocbot_role_goalrating_enemyplayers(8000, self.origin, 2000);
		navigation_goalrating_end();
	}
}

void() freeze_role_choose {
	self.havocbot_role = freeze_role;
}
