string(float buff) rm_buffs_TypeToName {
	switch (buff) {
	#define RM_BUFFS_DEF(id,shortname,longname,color) case id: return #shortname;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	default: return "unknown";
	}
}

float(string name) rm_buffs_NameToType {
	switch (name) {
	#define RM_BUFFS_DEF(id,shortname,longname,color) case #shortname: return id;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	// compatibility
	case "bash": return RM_BUFFS_IGNITE;
	case "focus": return RM_BUFFS_CONDUIT;
	}
	return 0;
}

string(float buff) rm_buffs_TypeToFullName {
	switch (buff) {
	#define RM_BUFFS_DEF(id,shortname,longname,color) case id: return longname;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	}
	return NULL;
}

string(float buff, string sep, float colorfactor) rm_buffs_TypeToExpandedName {
    string n = rm_buffs_TypeToFullName(buff);
    if(n != "") {
        if(colorfactor) {
            float i = 1 - colorfactor;
            n = strcat(rgb_to_hexcolor(rm_buffs_TypeToColor(buff) * colorfactor + i * '1 1 1'), n);
        }
        return n;
    }
    string r = "";
    float o, first = TRUE;
    for(o = RM_BUFFS_FIRST; o <= RM_BUFFS_LAST; o *= 2) {
        if(buff & o) {
            if(first) {
                r = rm_buffs_TypeToExpandedName(o, sep, colorfactor);
                first = FALSE;
            } else {
                r = strcat(r, sep, rm_buffs_TypeToExpandedName(o, sep, colorfactor));
            }
        }
    }
    if(r == "")
        return "Unknown";

    return r;
}

string(string t) rm_buffs_NameToFullName {
	switch (t) {
	#define RM_BUFFS_DEF(id,shortname,longname,color) case #shortname: return longname;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	}
	return "Unknown Buff";
}

vector rm_buffs_TypeToColor(float buff) {
	switch (buff) {
	#define RM_BUFFS_DEF(id,shortname,longname,color) case id: return color;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	}
	vector c = '0 0 0';
	float o, n = 0;
	for (o = RM_BUFFS_FIRST; o <= RM_BUFFS_LAST; o *= 2) {
		if (buff & o) {
			c += rm_buffs_TypeToColor(o);
			++n;
		}
	}
	return c * (1/n);
}

float(float buff) rm_buffs_TypeToIndex {
	#define RM_BUFFS_DEF(id,shortname,longname,color) if(buff == id) return id##_ID;
	RM_BUFFS_DEFS
	#undef RM_BUFFS_DEF
	return -1;
}

float(string bufflist) rm_buffs_ParseList {
    float tokens = tokenize(bufflist);
    float bffs = 0;
	float i;
    for(i = 0; i < tokens; ++i) {
        if(argv(i) == "all")
            return RM_BUFFS_LAST * 2 - 1;

        bffs |= rm_buffs_NameToType(argv(i));
    }
    return bffs;
}

string(float bffs) rm_buffs_TypeToList {
    string s = "";
	float b;
    for(b = RM_BUFFS_FIRST; b <= RM_BUFFS_LAST; b *= 2) {
        if(bffs & b) {
            string n = rm_buffs_TypeToName(b);
            if(s == "")
                s = n;
            else
                s = strcat(s, " ", n);
        }
    }
    return s;
}
