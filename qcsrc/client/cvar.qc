var void() read_cvars;

float(string varname, float setflags, float unsetflags) cvar_altertype = #505;

var void(string varname, string val) registercvar_save;

#define CVAR(x) autocvar_##x
#define CVAR_OR(x,y) (autocvar_##x ? autocvar_##x : y)

#define CACHE_CVAR(x) float autocvar_##x;
#define CACHE_CVAR_DEF(x,y) var float autocvar_##x = y;
#define CACHE_CVAR_VEC(x) vector autocvar_##x;
#define READ_CVARS_BEGIN(x,y)
#define READ_CVARS_SECTION(x,y)
#define READ_CVARS_END(x)
#include "cvar_list.qc"
#undef CACHE_CVAR
#undef CACHE_CVAR_DEF
#undef CACHE_CVAR_VEC
#undef READ_CVARS_BEGIN
#undef READ_CVARS_SECTION
#undef READ_CVARS_END

#define CACHE_CVAR(x) 
#define CACHE_CVAR_DEF(x,y) if (autocvar_##x == y) { registercvar_save(#x, ftos(y)); }
#define CACHE_CVAR_VEC(x) 
#define READ_CVARS_BEGIN(x,y) void register_autocvars() {
#define READ_CVARS_SECTION(x,y)
#define READ_CVARS_END(x) }
#include "cvar_list.qc"
#undef CACHE_CVAR
#undef CACHE_CVAR_DEF
#undef CACHE_CVAR_VEC
#undef READ_CVARS_BEGIN
#undef READ_CVARS_SECTION
#undef READ_CVARS_END

#define CACHE_CVAR(x) autocvar_##x = cvar(#x);
#define CACHE_CVAR_DEF(x,y) autocvar_##x = cvar(#x);
#define CACHE_CVAR_VEC(x) autocvar_##x = stov(cvar_string(#x));
#define READ_CVARS_BEGIN(x,y) void read_cvars_##y(); void read_cvars_##x() {
#define READ_CVARS_SECTION(x,y) read_cvars = read_cvars_##x; } void read_cvars_##y(); void read_cvars_##x() {
#define READ_CVARS_END(x) read_cvars = read_cvars_##x; }
#include "cvar_list.qc"
#undef CACHE_CVAR
#undef CACHE_CVAR_DEF
#undef CACHE_CVAR_VEC
#undef READ_CVARS_BEGIN
#undef READ_CVARS_SECTION
#undef READ_CVARS_END

void registercvar_save_old(string varname, string val) {
	registercvar(varname, val, CVAR_SAVE);
}

void registercvar_save_awful(string varname, string val) {
	localcmd(strcat("\nseta ", varname, " ", val, "\n"));
}

void registercvar_save_rm(string varname, string val) {
	cvar_altertype(varname, 2, 0);
}

float autocvar_autocvar_check;
void read_cvars_dummy() { };
void read_cvars_init() {
	cvar_set("autocvar_check", "0");
	autocvar_autocvar_check = 0;
	cvar_set("autocvar_check", "1");
	if (autocvar_autocvar_check) {
		if (checkextension("DP_RM_CVAR_ALTERTYPE"))
			registercvar_save = registercvar_save_rm;
		else
			registercvar_save = registercvar_save_awful;
	} else {
		registercvar_save = registercvar_save_old;
	}
	register_autocvars();
	if (autocvar_autocvar_check) {
		//print("Auto cvars working, good\n");
		read_cvars = read_cvars_dummy;
		return;
	}
	read_cvars = read_cvars_0;
	do { read_cvars(); } while (read_cvars != read_cvars_0);
}
