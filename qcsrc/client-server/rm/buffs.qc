
string Buffs_TypeToName(float buff) {
    switch(buff) {
        #define BUFFDEF(id,shortname,longname,color) \
            case id: return #shortname;
        BUFFDEFS
        #undef BUFFDEF

        default: return "unknown";
    }
}

float Buffs_NameToType(string name) {
    switch(name) {
        #define BUFFDEF(id,shortname,longname,color) \
            case #shortname: return id;
        BUFFDEFS
        #undef BUFFDEF

        // compatibility
        case "bash": return BUFF_IGNITE;
        case "focus": return BUFF_CONDUIT;
        
        default: return 0;
    }
}

string Buffs_TypeToFullName(float buff) {
    switch(buff) {
        #define BUFFDEF(id,shortname,longname,color) \
            case id: return longname;
        BUFFDEFS
        #undef BUFFDEF

        default: return NULL;
    }
}

string rgb_to_hexcolor(vector rgb)
{
	string HEXDIGITS = "0123456789ABCDEF0123456789abcdef";
	#define DEC_TO_HEXDIGIT(d) (substring(HEXDIGITS, (d), 1))
	return
		strcat(
			"^x",
			DEC_TO_HEXDIGIT(floor(rgb_x * 15 + 0.5)),
			DEC_TO_HEXDIGIT(floor(rgb_y * 15 + 0.5)),
			DEC_TO_HEXDIGIT(floor(rgb_z * 15 + 0.5))
		);
	#undef DEC_TO_HEXDIGIT
}

string Buffs_TypeToExpandedName(float buff, string sep, float colorfactor) {
    string n = Buffs_TypeToFullName(buff);

    if(n != "") {
        if(colorfactor) {
            float i = 1 - colorfactor;
            n = strcat(rgb_to_hexcolor(Buffs_TypeToColor(buff) * colorfactor + i * '1 1 1'), n);
        }

        return n;
    }

    string r = "";
    float o, first = TRUE;

    for(o = BUFF_FIRST; o <= BUFF_LAST; o *= 2) {
        if(buff & o) {
            if(first) {
                r = Buffs_TypeToExpandedName(o, sep, colorfactor);
                first = FALSE;
            } else {
                r = strcat(r, sep, Buffs_TypeToExpandedName(o, sep, colorfactor));
            }
        }
    }

    if(r == "")
        return "Unknown";

    return r;
}

string Buffs_NameToFullName(string t) {
    switch(t) {
        #define BUFFDEF(id,shortname,longname,color) \
            case #shortname: return longname;
        BUFFDEFS
        #undef BUFFDEF

        default: return "Unknown Buff";
    }
}

vector Buffs_TypeToColor(float buff) {
    switch(buff) {
        #define BUFFDEF(id,shortname,longname,color) \
            case id: return color;
        BUFFDEFS
        #undef BUFFDEF

        default: {
            vector c = '0 0 0';
            float o, n = 0;

            for(o = BUFF_FIRST; o <= BUFF_LAST; o *= 2) {
                if(buff & o) {
                    c += Buffs_TypeToColor(o);
                    ++n;
                }
            }

            return c * (1/n);
        }
    }
}

float Buffs_TypeToIndex(float buff) {
    #define BUFFDEF(id,shortname,longname,color) \
        if(buff == id) return id##_ID;
    BUFFDEFS
    #undef BUFFDEF

    return -1;
}

float Buffs_ParseList(string bufflist) {
    float tokens = tokenize(bufflist);
    float bffs = 0;

	float i;
    for(i = 0; i < tokens; ++i) {
        if(argv(i) == "all")
            return BUFF_LAST * 2 - 1;

        bffs |= Buffs_NameToType(argv(i));
    }

    return bffs;
}

string Buffs_TypeToList(float bffs) {
    string s = "";

	float b;
    for(b = BUFF_FIRST; b <= BUFF_LAST; b *= 2) {
        if(bffs & b) {
            string n = Buffs_TypeToName(b);

            if(s == "")
                s = n;
            else
                s = strcat(s, " ", n);
        }
    }

    return s;
}
