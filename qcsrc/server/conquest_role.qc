void(float ratingscale, vector org, float sradius) conquest_role_goalrating_controlpoints {
	local entity head;
	head = findchain(classname, "conquest_cp");
	while (head)
	{
		if (vlen(head.origin - org) < sradius)
		{
			if(!head.team)
				navigation_routerating(head, ratingscale * 0.5, 5000);
			else if(head.team != self.team) // other team's point
				navigation_routerating(head, ratingscale, 5000);
		}
		head = head.chain;
	}
}

void() conquest_role {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		conquest_role_goalrating_controlpoints(25000, self.origin, 15000);
		havocbot_role_goalrating_items(8000, self.origin, 8000);
		havocbot_role_goalrating_enemyplayers(8000, self.origin, 2000);
		navigation_goalrating_end();
	}
}

void() conquest_role_choose {
	self.havocbot_role = conquest_role;
}

