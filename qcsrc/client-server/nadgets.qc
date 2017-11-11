
string HG_TypeToExpandedName(float t) {
    switch(t) {
        #define HGDEF(id,shortname,longname,color) \
            case id: return longname;
        HGDEFS
        #undef HGDEF

        case HG_RANDOM: return "Random Nadget";
        default       : return "Fuckoff Grenade";
    }
}

string HG_TypeToName(float t) {
    switch(t) {
        #define HGDEF(id,shortname,longname,color) \
            case id: return #shortname;
        HGDEFS
        #undef HGDEF

        case HG_RANDOM: return "random";
        default       : return strcat("fuckoff", ftos(t));
    }
}

float HG_NameToType(string t) {
    switch(t) {
        #define HGDEF(id,shortname,longname,color) \
            case #shortname: return id;
        HGDEFS
        #undef HGDEF

        case "random": return HG_RANDOM;
        default      : return HG_NORMAL;
    }
}

string HG_NameToExpandedName(string t) {
    switch(t) {
        #define HGDEF(id,shortname,longname,color) \
            case #shortname: return longname;
        HGDEFS
        #undef HGDEF

        case "random": return "Random Nadget";
        default      : return "Fuckoff Grenade";
    }
}

vector HG_TypeToColor(float t) {
    switch(t) {
        #define HGDEF(id,shortname,longname,color) \
            case id: return color;
        HGDEFS
        #undef HGDEF

        case HG_RANDOM: return '1.0 1.0 1.0';
        default       : return '0.5 0.5 0.5';
    }
}

string HG_NameToIcon(string n, float large, float alt) {
    string s = strcat("gfx/nades/", n);
    
    if(large)   s = strcat(s, "_large");
    if(alt)     s = strcat(s, "_alt");
    
    return s;
}

string HG_TypeToIcon(float t, float large, float alt) {
    return HG_NameToIcon(HG_TypeToName(t), large, alt);
}

float HG_CompressDualType(float t1, float t2) {
    return (t1 - HG_START) + (t2 - HG_START) * 16;
}

vector HG_DecompressDualType(float t) {
    vector v;
    v_x = (t & 0x0F)      + HG_START;
    v_y = (t & 0xF0) / 16 + HG_START;
    return v;
}
