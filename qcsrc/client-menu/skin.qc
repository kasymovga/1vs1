#define SKINBEGIN void skin_setting_apply(string key, string _value) { switch(key) {
#define SKINVECTOR(name,def) case #name: SKIN##name = stov(_value); break
#define SKINFLOAT(name,def) case #name: SKIN##name = stof(_value); break
#define SKINSTRING(name,def) case #name: break
#define SKINEND case "": break; case "//": break; default: print("Invalid key in skin file: ", key, "\n"); } }
#include "skin-customizables.inc"
#undef SKINEND
#undef SKINSTRING
#undef SKINFLOAT
#undef SKINVECTOR
#undef SKINBEGIN
void(void) skin_init {
	float fh, n;
	string s;
	fh = -1;
	str_unzone_ifneeded(skin_current);
	if (cvar_string("menu_skin") != "") {
		skin_current = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(skin_current, "/skinvalues.txt"), FILE_READ);
	}
#ifndef CSQC
	if (fh < 0)
	if (cvar_defstring("menu_skin") != "") {
		skin_current = strcat("gfx/menu/", cvar_defstring("menu_skin"));
		fh = fopen(strcat(skin_current, "/skinvalues.txt"), FILE_READ);
	}
#endif
	if (fh < 0) {
		skin_current = "gfx/menu/default";
		fh = fopen(strcat(skin_current, "/skinvalues.txt"), FILE_READ);
	}
	skin_current = strzone(skin_current);
	while ((s = fgets(fh))) {
		// these two are handled by skinlist.qc
		if(substring(s, 0, 6) == "title ")
			continue;

		if(substring(s, 0, 7) == "author ")
			continue;

		n = tokenize_console(s);
		if(n >= 2)
			skin_setting_apply(argv(0), substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
	}
	fclose(fh);
}
