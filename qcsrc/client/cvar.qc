var void() read_cvars;

var void(string varname, string val) cvar_register_save;
string(vector v) cvar_vtos;

#define CVAR(x) autocvar_##x
#define CVAR_OR(x,y) (autocvar_##x ? autocvar_##x : y)

#define CVAR_CACHE(x) float autocvar_##x;
#define CVAR_CACHE_DEF(x,y) var float autocvar_##x = y;
#define CVAR_CACHE_VEC(x) vector autocvar_##x;
#define CVAR_CACHE_VEC_DEF(x,y) var vector autocvar_##x = y;
#define CVAR_LIST_BEGIN(x,y)
#define CVAR_LIST_SECTION(x,y)
#define CVAR_LIST_END(x)
#include "cvar_list.qc"
#undef CVAR_CACHE
#undef CVAR_CACHE_DEF
#undef CVAR_CACHE_VEC
#undef CVAR_CACHE_VEC_DEF
#undef CVAR_LIST_BEGIN
#undef CVAR_LIST_SECTION
#undef CVAR_LIST_END

#define CVAR_CACHE(x) 
#define CVAR_CACHE_DEF(x,y) if (autocvar_##x == y) { cvar_register_save(#x, ftos(y)); }
#define CVAR_CACHE_VEC(x) 
#define CVAR_CACHE_VEC_DEF(x,y) if (autocvar_##x == y) { cvar_register_save(#x, cvar_vtos(y)); }
#define CVAR_LIST_BEGIN(x,y) void cvar_register_autocvars() {
#define CVAR_LIST_SECTION(x,y)
#define CVAR_LIST_END(x) }
#include "cvar_list.qc"
#undef CVAR_CACHE
#undef CVAR_CACHE_DEF
#undef CVAR_CACHE_VEC
#undef CVAR_CACHE_VEC_DEF
#undef CVAR_LIST_BEGIN
#undef CVAR_LIST_SECTION
#undef CVAR_LIST_END

#define CVAR_CACHE(x) autocvar_##x = cvar(#x);
#define CVAR_CACHE_DEF(x,y) autocvar_##x = cvar(#x);
#define CVAR_CACHE_VEC(x) autocvar_##x = stov(cvar_string(#x));
#define CVAR_CACHE_VEC_DEF(x,y) autocvar_##x = stov(cvar_string(#x));
#define CVAR_LIST_BEGIN(x,y) void read_cvars_##y(); void read_cvars_##x() {
#define CVAR_LIST_SECTION(x,y) read_cvars = read_cvars_##x; } void read_cvars_##y(); void read_cvars_##x() {
#define CVAR_LIST_END(x) read_cvars = read_cvars_##x; }
#include "cvar_list.qc"
#undef CVAR_CACHE
#undef CVAR_CACHE_DEF
#undef CVAR_CACHE_VEC
#undef CVAR_CACHE_VEC_DEF
#undef CVAR_LIST_BEGIN
#undef CVAR_LIST_SECTION
#undef CVAR_LIST_END

void cvar_register_save_old(string varname, string val) {
	registercvar(varname, val, CVAR_SAVE);
}

void cvar_register_save_awful(string varname, string val) {
	localcmd(strcat("\nseta ", varname, " \"", val, "\"\n"));
}

void cvar_register_save_rm(string varname, string val) {
	if not(cvar_type(varname) & 8) //engine cvar
		cvar_altertype(varname, 2, 0);
}

string(vector v) cvar_vtos {
	return strcat(ftos(v_x), " ", ftos(v_y), " ", ftos(v_z));
}

float autocvar_autocvar_check;
void read_cvars_dummy() { };
void read_cvars_init() {
	cvar_set("autocvar_check", "0");
	autocvar_autocvar_check = 0;
	cvar_set("autocvar_check", "1");
	if (autocvar_autocvar_check) {
		if (extension_DP_RM_CVAR_ALTERTYPE)
			cvar_register_save = cvar_register_save_rm;
		else
			cvar_register_save = cvar_register_save_awful;
	} else {
		cvar_register_save = cvar_register_save_old;
	}
	cvar_register_autocvars();
	if (autocvar_autocvar_check) {
		//print("Auto cvars working, good\n");
		read_cvars = read_cvars_dummy;
		return;
	}
	read_cvars = read_cvars_0;
	do { read_cvars(); } while (read_cvars != read_cvars_0);
}

void(string cv, string val) cvar_clientsettemp {
	entity e;
	if (cvar_string(cv) == val)
		return;

	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == cv)
			goto saved;

	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(cv);
	e.message = strzone(cvar_string(cv));
:saved
	cvar_set(cv, val);
}

void(void) cvar_clientsettemp_restore {
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
			cvar_set(e.netname, e.message);
}

void(string s, vector v) cvar_set_vec {
	cvar_set(s, strcat(ftos(v_x), " ", ftos(v_y), " ", ftos(v_z)));
}
