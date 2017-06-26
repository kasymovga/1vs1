
void ProjInfo_Register(float csqcid, float entrytype, vector pmins, vector pmaxs) {
    // FIXME: client init gets sent twice with sendflags == 0xff
    // ProjInfo_AssertUnregistered(csqcid);

#if 0
    print("ProjInfo_Register");
    print(" ", ftos(csqcid));
    print(" ", ftos(entrytype));
    print(" ", vtos(pmins));
    print(" ", vtos(pmaxs));
    print("\n");
#endif

    PROJINFO_PROPERTY(csqcid, type) = entrytype;
    PROJINFO_PROPERTY(csqcid, mins) = pmins;
    PROJINFO_PROPERTY(csqcid, maxs) = pmaxs;

    if(projinfo_highest_registered < csqcid) {
        projinfo_highest_registered = csqcid;
    }
}

void ProjInfo_RegisterAuto(float csqcid, vector pmins, vector pmaxs) {
    float type;

    if(pmins == pmaxs) {
        if(pmins == '0 0 0') {
            type = PROJINFO_TYPE_POINT_000;
        } else if(pmins == '0 0 -3') {
            type = PROJINFO_TYPE_POINT_00n3;
        } else {
            type = PROJINFO_TYPE_POINT;
        }
    } else if(pmins == pmaxs * -1) {
        type = PROJINFO_TYPE_CENTERED;
    } else {
        type = PROJINFO_TYPE_UNCENTERED;
    }

    ProjInfo_Register(csqcid, type, pmins, pmaxs);
}

#ifdef PROJINFO_ENABLE_ASSERTIONS

void ProjInfo_AssertRegistered(float csqcid) {
    if(PROJINFO_PROPERTY(csqcid, type) == PROJINFO_TYPE_UNREGISTERED) {
        error(strcat("CSQC projectile ", ftos(csqcid), " has not been registered"));
    }
}

void ProjInfo_AssertUnregistered(float csqcid) {
    if(PROJINFO_PROPERTY(csqcid, type) != PROJINFO_TYPE_UNREGISTERED) {
        error(strcat("CSQC projectile ", ftos(csqcid), " has already been registered"));
    }
}

#endif
