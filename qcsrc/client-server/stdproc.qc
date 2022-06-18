void(void) stdproc_remove {
	if (self.entremove)
		self.entremove();

	remove (self);
}

void(entity e) stdproc_remove_entity {
	entity oldself = self;
	self = e;
	if (self.entremove)
		self.entremove();

	remove (self);
	self = oldself;
}
