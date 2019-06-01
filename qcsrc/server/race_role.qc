.float race_checkpoint;
void() race_role {
	if(self.deadflag != DEAD_NO)
		return;

	entity e;
	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		/*
		havocbot_goalrating_items(100, self.origin, 10000);
		havocbot_goalrating_enemyplayers(500, self.origin, 20000);
		*/

		for(e = world; (e = find(e, classname, "trigger_race_checkpoint")) != world; )
		{
			if(e.cnt == self.race_checkpoint)
			{
				navigation_routerating(e, 1000000, 5000);
			}
			else if(self.race_checkpoint == -1)
			{
				navigation_routerating(e, 1000000, 5000);
			}
		}

		navigation_goalrating_end();
	}
}

void() race_role_choose {
	self.havocbot_role = race_role;
}
