void(void) spawnfunc_path_corner {
	if (self.spawnflags & 1) //quake2 compatibility, teleportation
		self.speed = -1;
}
