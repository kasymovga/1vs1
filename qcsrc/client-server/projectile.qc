void(float csqcid, float entrytype, vector sizes) projectile_register {
	sizes_x = bound(0, sizes_x, 63);
	sizes_z = bound(-31, sizes_z, 32);
	sizes_y = bound(-31, sizes_y, sizes_z);
	if (sizes_y < 0) {
		sizes_y += 64;
		if (sizes_z < 0)
			sizes_z += 64;
	}
    if(PROJINFO_PROPERTY(csqcid, type) != PROJINFO_TYPE_UNREGISTERED) {
		return;
	}
    PROJINFO_PROPERTY(csqcid, type) = entrytype;
	float f = (sizes_x & 0x3F) + ((sizes_y * 64) & (0xFC0)) + (sizes_z * 4096);
    PROJINFO_PROPERTY(csqcid, sizes) = f;

    if(projinfo_highest_registered < csqcid) {
        projinfo_highest_registered = csqcid;
    }
}

void(float csqcid, vector sizes) projectile_register_auto {
    float type;

    if(sizes_x == 0 && sizes_y == sizes_z) {
        if(sizes == '0 0 0') {
            type = PROJINFO_TYPE_POINT_000;
        } else if(sizes == '0 -3 -3') {
            type = PROJINFO_TYPE_POINT_00n3;
        } else {
            type = PROJINFO_TYPE_POINT;
        }
    } else if(sizes_y == sizes_z * -1) {
        type = PROJINFO_TYPE_CENTERED;
    } else {
        type = PROJINFO_TYPE_UNCENTERED;
    }

    projectile_register(csqcid, type, sizes);
}

void(entity e, float csqcid) projectile_set_size {
	vector pmins, pmaxs;
	float f = PROJINFO_PROPERTY(csqcid, sizes);
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
