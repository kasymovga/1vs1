void(void) stdproc_remove {
	if (self.entremove)
		self.entremove();

	remove (self);
}
