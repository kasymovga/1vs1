float(string s) cvar_value_issafe {
	if (strstrofs(s, "\"", 0) >= 0)
		return 0;

	if (strstrofs(s, "\\", 0) >= 0)
		return 0;

	if (strstrofs(s, ";", 0) >= 0)
		return 0;

	if (strstrofs(s, "$", 0) >= 0)
		return 0;

	if (strstrofs(s, "\r", 0) >= 0)
		return 0;

	if (strstrofs(s, "\n", 0) >= 0)
		return 0;
	return 1;
}

void(string pKey, string pValue) cvar_settemp {
	if(cvar_string(pKey) == pValue)
		return;

	builtin_cvar_set("settemp_list", strcat("1 ", pKey, " ", builtin_cvar_string("settemp_var"), " ", builtin_cvar_string("settemp_list")));
#ifdef MENUQC
	registercvar(builtin_cvar_string("settemp_var"), "", 0);
	registercvar(pKey, "", 0);
#else
	registercvar(builtin_cvar_string("settemp_var"), "");
	registercvar(pKey, "");
#endif
	builtin_cvar_set(builtin_cvar_string("settemp_var"), builtin_cvar_string(pKey));
	builtin_cvar_set("settemp_var", strcat(builtin_cvar_string("settemp_var"), "x"));
	builtin_cvar_set(pKey, pValue);
}

void(void) cvar_settemp_restore {
	// undo what cvar_settemp did
	float n, i;
	n = tokenize_console(builtin_cvar_string("settemp_list"));
	for (i = 0; i < n - 3; i += 3)
		builtin_cvar_set(argv(i + 1), builtin_cvar_string(argv(i + 2)));

	builtin_cvar_set("settemp_list", "0");
}
