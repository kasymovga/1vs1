void(float csqcid, float entrytype, vector sizes) projectile_register {
	sizes_x = bound(0, sizes_x, 63);
	sizes_z = bound(-31, sizes_z, 32);
	sizes_y = bound(-31, sizes_y, sizes_z);
	if (sizes_y < 0) {
		sizes_y += 64;
		if (sizes_z < 0)
			sizes_z += 64;
	}
	if (PROJECTILE_INFO_PROPERTY(csqcid, type) != PROJECTILE_INFO_TYPE_UNREGISTERED) {
		return;
	}
	PROJECTILE_INFO_PROPERTY(csqcid, type) = entrytype;
	float f = (sizes_x & 0x3F) + ((sizes_y * 64) & (0xFC0)) + (sizes_z * 4096);
	PROJECTILE_INFO_PROPERTY(csqcid, sizes) = f;
	if (projectile_info_highest_registered < csqcid) {
		projectile_info_highest_registered = csqcid;
	}
}

void(entity e, float csqcid) projectile_set_size {
	vector pmins, pmaxs;
	float f = PROJECTILE_INFO_PROPERTY(csqcid, sizes);
	pmaxs_x = pmaxs_y = (f & 0x3F);
	pmins_x = pmins_y = -pmaxs_x;
	pmins_z = (f & 0xFC0) / 0x40;
	pmaxs_z = (f & 0x3F000) / (0x1000);
	if (pmins_z > 32) {
		pmins_z -= 64;
		if (pmaxs_z > 32)
			pmaxs_z -= 64;
	}
	setsize(e, pmins, pmaxs);
}
