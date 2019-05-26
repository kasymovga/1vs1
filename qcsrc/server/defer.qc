void(void) defer_think {
	entity oldself = self;
	self = self.enemy;
	oldself.use();
	self = oldself;
	remove(self);
}

void(entity e_for, float t, void() callback) defer_for {
	entity e = spawn();
	e.use = callback;
	e.enemy = e_for;
	e.nextthink = t + time;
	e.think = defer_think;
}

void(float t, void() callback) defer {
	defer_for(self, t, callback);
}
