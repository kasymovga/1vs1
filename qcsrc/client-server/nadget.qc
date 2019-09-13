
string nadget_TypeToExpandedName(float t) {
    switch(t) {
        #define NADGETDEF(id,shortname,longname,color) \
            case id: return longname;
        NADGETDEFS
        #undef NADGETDEF

        case NADGET_RANDOM: return "Random Nadget";
        default       : return "Fuckoff Grenade";
    }
}

string nadget_TypeToName(float t) {
    switch(t) {
        #define NADGETDEF(id,shortname,longname,color) \
            case id: return #shortname;
        NADGETDEFS
        #undef NADGETDEF

        case NADGET_RANDOM: return "random";
        default       : return strcat("fuckoff", ftos(t));
    }
}

float nadget_NameToType(string t) {
    switch(t) {
        #define NADGETDEF(id,shortname,longname,color) \
            case #shortname: return id;
        NADGETDEFS
        #undef NADGETDEF

        case "random": return NADGET_RANDOM;
        default      : return NADGET_NORMAL;
    }
}

string nadget_NameToExpandedName(string t) {
    switch(t) {
        #define NADGETDEF(id,shortname,longname,color) \
            case #shortname: return longname;
        NADGETDEFS
        #undef NADGETDEF

        case "random": return "Random Nadget";
        default      : return "Fuckoff Grenade";
    }
}

vector nadget_TypeToColor(float t) {
    switch(t) {
        #define NADGETDEF(id,shortname,longname,color) \
            case id: return color;
        NADGETDEFS
        #undef NADGETDEF

        case NADGET_RANDOM: return '1.0 1.0 1.0';
        default       : return '0.5 0.5 0.5';
    }
}

string nadget_NameToIcon(string n, float large, float alt) {
    string s = strcat("gfx/nades/", n);
    if(large)   s = strcat(s, "_large");
    if(alt)     s = strcat(s, "_alt");
    return s;
}

string nadget_TypeToIcon(float t, float large, float alt) {
    return nadget_NameToIcon(nadget_TypeToName(t), large, alt);
}

float nadget_CompressDualType(float t1, float t2) {
    return (t1 - NADGET_START) + (t2 - NADGET_START) * 16;
}

vector nadget_DecompressDualType(float t) {
    vector v;
    v_x = (t & 0x0F)      + NADGET_START;
    v_y = (t & 0xF0) / 16 + NADGET_START;
    return v;
}
