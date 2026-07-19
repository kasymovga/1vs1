void() lms_role {
	if (self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time) {
		float f = (1 - lms_progress());
		f *= f;
		vector o = ENTITY_CENTER(self);
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_role_goalrating_items(10000, o, 10000);
		havocbot_role_goalrating_enemyplayers(1000 * f, o, 10000);
		navigation_goalrating_end();
	}
}

void() lms_role_choose {
	self.havocbot_role = lms_role;
}
