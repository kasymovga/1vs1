void(float ratingscale, vector org, float sradius) dom_role_goalrating_controlpoints {
	local entity head;
	head = findchain(classname, "dom_controlpoint");
	while (head)
	{
		if (vlen(head.origin - org) < sradius)
		{
			if(head.cnt > -1) // this is just being fought for
				navigation_routerating(head, ratingscale, 5000);
			else if(head.goalentity.cnt == 0) // unclaimed point
				navigation_routerating(head, ratingscale * 0.5, 5000);
			else if(head.goalentity.team != self.team) // other team's point
				navigation_routerating(head, ratingscale * 0.2, 5000);
		}
		head = head.chain;
	}
};

void() dom_role {
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		dom_role_goalrating_controlpoints(10000, self.origin, 15000);
		havocbot_goalrating_items(8000, self.origin, 8000);
		//havocbot_goalrating_enemyplayers(3000, self.origin, 2000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
}

void() dom_role_choose {
	self.havocbot_role = dom_role;
}
