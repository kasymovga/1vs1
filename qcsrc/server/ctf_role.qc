#define HAVOCBOT_CTF_ROLE_NONE 		0
#define HAVOCBOT_CTF_ROLE_DEFENSE	2
#define HAVOCBOT_CTF_ROLE_MIDDLE	4
#define HAVOCBOT_CTF_ROLE_OFFENSE	8
#define HAVOCBOT_CTF_ROLE_CARRIER	16
#define HAVOCBOT_CTF_ROLE_RETRIEVER	32
#define HAVOCBOT_CTF_ROLE_ESCORT	64

void() ctf_role_middle;
void() ctf_role_defense;
void() ctf_role_offense;
void() ctf_role_carrier;
void() ctf_role_retriever;
void() ctf_role_escort;

void(entity bot) ctf_role_reset;

.float havocbot_cantfindflag;
.entity ctf_worldflagnext;
.entity basewaypoint;

entity ctf_worldflaglist;
vector ctf_role_middlepoint;
float havocbot_ctf_middlepoint_radius;

entity(entity bot) ctf_role_find_flag {
	entity f;
	f = ctf_worldflaglist;
	while (f)
	{
		if (bot.team == f.team)
			return f;
		f = f.ctf_worldflagnext;
	}
	return world;
}

entity(entity bot) ctf_role_find_enemy_flag {
	entity f;
	f = ctf_worldflaglist;
	while (f)
	{
		if (bot.team != f.team)
			return f;
		f = f.ctf_worldflagnext;
	}
	return world;
}

float(entity bot, vector org, float _radius) ctf_role_teamcount {
	float c;
	entity head;

	FOR_EACH_PLAYER(head)
	{
		if(head.team!=bot.team || head.deadflag != DEAD_NO || head == bot)
			continue;

		if(vlen(head.origin - org) < _radius)
			++c;
	}

	return c;
}

void(float ratingscale) ctf_role_goalrating_ourbase {
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (self.team == head.team)
			break;
		head = head.ctf_worldflagnext;
	}
	if not(head)
		return;

	navigation_routerating(head.basewaypoint, ratingscale, 10000);
}

void(float ratingscale) ctf_role_goalrating_enemyflag {
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (self.team != head.team)
			break;
		head = head.ctf_worldflagnext;
	}
	if (head)
		navigation_routerating(head, ratingscale, 10000);
}

void(float ratingscale) ctf_role_goalrating_enemybase {
	if not(bot_waypoints_for_items)
	{
		ctf_role_goalrating_enemyflag(ratingscale);
		return;
	}

	entity head;

	head = ctf_role_find_enemy_flag(self);

	if not(head)
		return;

	navigation_routerating(head.basewaypoint, ratingscale, 10000);
}

void(float ratingscale) ctf_role_goalrating_ourstolenflag {
	entity mf;

	mf = ctf_role_find_flag(self);

	if(mf.cnt == FLAG_BASE)
		return;

	navigation_routerating(mf, ratingscale, 10000);
}

void(float ratingscale, vector org, float _radius) ctf_role_goalrating_droppedflags {
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		// flag is out in the field
		if(head.cnt != FLAG_BASE)
		if(head.tag_entity==world)	// dropped
		{
			if(_radius)
			{
				if(vlen(org-head.origin)<_radius)
					navigation_routerating(head, ratingscale, 10000);
			}
			else
				navigation_routerating(head, ratingscale, 10000);
		}

		head = head.ctf_worldflagnext;
	}
}

void(float ratingscale, vector org, float sradius) ctf_role_goalrating_carrieritems {
	entity head;
	float t;
	head = findchainfloat(bot_pickup, TRUE);
	while (head)
	{
		// gather health and armor only
		if (head.solid)
		if (head.health || head.armorvalue)
		if (vlen(head.origin - org) < sradius)
		{
			// get the value of the item
			t = head.bot_pickupevalfunc(self, head) * 0.0001;
			if (t > 0)
				navigation_routerating(head, t * ratingscale, 500);
		}
		head = head.chain;
	}
}

void(entity bot, float role) ctf_role_set {
	dprint(strcat(bot.netname," switched to "));
	switch(role)
	{
		case HAVOCBOT_CTF_ROLE_CARRIER:
			dprint("carrier");
			bot.havocbot_role = ctf_role_carrier;
			bot.havocbot_role_timeout = 0;
			bot.havocbot_cantfindflag = time + 10;
			break;
		case HAVOCBOT_CTF_ROLE_DEFENSE:
			dprint("defense");
			bot.havocbot_role = ctf_role_defense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_MIDDLE:
			dprint("middle");
			bot.havocbot_role = ctf_role_middle;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_OFFENSE:
			dprint("offense");
			bot.havocbot_role = ctf_role_offense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_RETRIEVER:
			dprint("retriever");
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = ctf_role_retriever;
			bot.havocbot_role_timeout = time + 10;
			break;
		case HAVOCBOT_CTF_ROLE_ESCORT:
			dprint("escort");
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = ctf_role_escort;
			bot.havocbot_role_timeout = time + 30;
			break;
	}
	dprint("\n");
}

void() ctf_role_carrier {
	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried == world)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;

		navigation_goalrating_start();
		ctf_role_goalrating_ourbase(50000);

		if(self.health<100)
			ctf_role_goalrating_carrieritems(1000, self.origin, 1000);

		navigation_goalrating_end();

		if (self.navigation_hasgoals)
			self.havocbot_cantfindflag = time + 10;
		else if (time > self.havocbot_cantfindflag)
		{
			// Can't navigate to my own base, suicide!
			// TODO: drop it and wander around
			damage(self, self, self, 100000, DEATH_KILL, self.origin, '0 0 0');
			return;
		}
	}
}

void() ctf_role_escort {
	entity mf, ef;

	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If enemy flag is back on the base switch to previous role
	ef = ctf_role_find_enemy_flag(self);
	if(ef.cnt==FLAG_BASE)
	{
		self.havocbot_role = self.havocbot_previous_role;
		self.havocbot_role_timeout = 0;
		return;
	}

	// If the flag carrier reached the base switch to defense
	mf = ctf_role_find_flag(self);
	if(mf.cnt!=FLAG_BASE)
	if(vlen(ef.origin - mf.dropped_origin) < 300)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_DEFENSE);
		return;
	}

	// Set the role timeout if necessary
	if (!self.havocbot_role_timeout)
	{
		self.havocbot_role_timeout = time + random() * 30 + 60;
	}

	// If nothing happened just switch to previous role
	if (time > self.havocbot_role_timeout)
	{
		self.havocbot_role = self.havocbot_previous_role;
		self.havocbot_role_timeout = 0;
		return;
	}

	// Chase the flag carrier
	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		ctf_role_goalrating_enemyflag(30000);
		ctf_role_goalrating_ourstolenflag(40000);
		havocbot_goalrating_items(10000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

void() ctf_role_offense {
	entity mf, ef;
	vector pos;

	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// Check flags
	mf = ctf_role_find_flag(self);
	ef = ctf_role_find_enemy_flag(self);

	// Own flag stolen
	if(mf.cnt!=FLAG_BASE)
	{
		if(mf.tag_entity)
			pos = mf.tag_entity.origin;
		else
			pos = mf.origin;

		// Try to get it if closer than the enemy base
		if(vlen(self.origin-ef.dropped_origin)>vlen(self.origin-pos))
		{
			ctf_role_set(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
			return;
		}
	}

	// Escort flag carrier
	if(ef.cnt!=FLAG_BASE)
	{
		if(ef.tag_entity)
			pos = ef.tag_entity.origin;
		else
			pos = ef.origin;

		if(vlen(pos-mf.dropped_origin)>700)
		{
			ctf_role_set(self, HAVOCBOT_CTF_ROLE_ESCORT);
			return;
		}
	}

	// About to fail, switch to middlefield
	if(self.health<50)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_MIDDLE);
		return;
	}

	// Set the role timeout if necessary
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 120;

	if (time > self.havocbot_role_timeout)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		ctf_role_goalrating_ourstolenflag(50000);
		ctf_role_goalrating_enemybase(20000);
		havocbot_goalrating_items(5000, self.origin, 1000);
		havocbot_goalrating_items(1000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

// Retriever (temporary role):
void() ctf_role_retriever {
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If flag is back on the base switch to previous role
	mf = ctf_role_find_flag(self);
	if(mf.cnt==FLAG_BASE)
	{
		ctf_role_reset(self);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 20;

	if (time > self.havocbot_role_timeout)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		float _radius;
		_radius = 10000;

		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		ctf_role_goalrating_ourstolenflag(50000);
		ctf_role_goalrating_droppedflags(40000, self.origin, _radius);
		ctf_role_goalrating_enemybase(30000);
		havocbot_goalrating_items(500, self.origin, _radius);
		navigation_goalrating_end();
	}
}

void() ctf_role_middle {
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = ctf_role_find_flag(self);
	if(mf.cnt!=FLAG_BASE)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 10;

	if (time > self.havocbot_role_timeout)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		vector org;

		org = ctf_role_middlepoint;
		org_z = self.origin_z;

		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		ctf_role_goalrating_ourstolenflag(50000);
		ctf_role_goalrating_droppedflags(30000, self.origin, 10000);
		havocbot_goalrating_enemyplayers(10000, org, havocbot_ctf_middlepoint_radius * 0.5);
		havocbot_goalrating_items(5000, org, havocbot_ctf_middlepoint_radius * 0.5);
		havocbot_goalrating_items(2500, self.origin, 10000);
		ctf_role_goalrating_enemybase(2500);
		navigation_goalrating_end();
	}
}

void() ctf_role_defense {
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		ctf_role_reset(self);
		return;
	}

	if (self.flagcarried)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If own flag was captured
	mf = ctf_role_find_flag(self);
	if(mf.cnt!=FLAG_BASE)
	{
		ctf_role_set(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 30;

	if (time > self.havocbot_role_timeout)
	{
		ctf_role_reset(self);
		return;
	}
	if (self.bot_strategytime < time)
	{
		float _radius;
		vector org;

		org = mf.dropped_origin;
		_radius = havocbot_ctf_middlepoint_radius;

		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();

		// if enemies are closer to our base, go there
		entity head, closestplayer;
		float distance, bestdistance;
		distance = 10000;
		FOR_EACH_PLAYER(head)
		{
			if(head.deadflag!=DEAD_NO)
				continue;

			distance = vlen(org - head.origin);
			if(distance<bestdistance)
			{
				closestplayer = head;
				bestdistance = distance;
			}
		}

		if(closestplayer)
		if(closestplayer.team!=self.team)
		if(vlen(org - self.origin)>1000)
		if(checkpvs(self.origin,closestplayer)||random()<0.5)
			ctf_role_goalrating_ourbase(30000);

		ctf_role_goalrating_ourstolenflag(20000);
		ctf_role_goalrating_droppedflags(20000, org, _radius);
		havocbot_goalrating_enemyplayers(15000, org, _radius);
		havocbot_goalrating_items(10000, org, _radius);
		havocbot_goalrating_items(5000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

void() ctf_role_calculate_middlepoint {
	entity f;
	vector p1, p2;

	f = ctf_worldflaglist;
	while (f)
	{
		if(p1)
			p2 = f.origin;
		else
			p1 = f.origin;

		f = f.ctf_worldflagnext;
	}
	ctf_role_middlepoint = p1 + ((p2-p1) * 0.5);
	havocbot_ctf_middlepoint_radius	 = vlen(p2-p1) * 0.5;
}

void(entity bot) ctf_role_reset {
	float cdefense, cmiddle, coffense;
	entity mf, ef, head;
	float c;
	if(bot.deadflag != DEAD_NO)
		return;

	if(vlen(ctf_role_middlepoint)==0)
		ctf_role_calculate_middlepoint();

	// Check ctf flags
	if (bot.flagcarried)
	{
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = ctf_role_find_flag(bot);
	ef = ctf_role_find_enemy_flag(bot);

	// Retrieve stolen flag
	if(mf.cnt!=FLAG_BASE)
	{
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	// If enemy flag is taken go to the middle to intercept pursuers
	if(ef.cnt!=FLAG_BASE)
	{
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_MIDDLE);
		return;
	}

	// if there is only me on the team switch to offense
	c = 0;
	FOR_EACH_PLAYER(head)
	if(head.team==bot.team)
		++c;

	if(c==1)
	{
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_OFFENSE);
		return;
	}

	// Evaluate best position to take
	// Count mates on middle position
	cmiddle = ctf_role_teamcount(bot, ctf_role_middlepoint, havocbot_ctf_middlepoint_radius * 0.5);

	// Count mates on defense position
	cdefense = ctf_role_teamcount(bot, mf.dropped_origin, havocbot_ctf_middlepoint_radius * 0.5);

	// Count mates on offense position
	coffense = ctf_role_teamcount(bot, ef.dropped_origin, havocbot_ctf_middlepoint_radius);

	if(cdefense<=coffense)
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_DEFENSE);
	else if(coffense<=cmiddle)
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_OFFENSE);
	else
		ctf_role_set(bot, HAVOCBOT_CTF_ROLE_MIDDLE);
}

void() ctf_role_choose {
	ctf_role_reset(self);
}
