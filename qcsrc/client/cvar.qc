var void() read_cvars;

#define CVAR(x) autocvar_##x
#define CVAR_OR(x,y) (autocvar_##x ? autocvar_##x : y)

#define CACHE_CVAR(x) registercvar(#x, "0", 0);
#define CACHE_CVAR_DEF(x,y) registercvar(#x, ftos(y), CVAR_SAVE);
#define CACHE_CVAR_VEC(x) registercvar(#x, "", 0);
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

float autocvar_autocvar_check;
void read_cvars_dummy() { };
void read_cvars_init() {
	register_autocvars(); //needed for old engines
	cvar_set("autocvar_check", "0");
	autocvar_autocvar_check = 0;
	cvar_set("autocvar_check", "1");
	if (autocvar_autocvar_check) {
		//print("Auto cvars working, good\n");
		read_cvars = read_cvars_dummy;
		return;
	}
	read_cvars = read_cvars_0;
	do { read_cvars(); } while (read_cvars != read_cvars_0);
}
