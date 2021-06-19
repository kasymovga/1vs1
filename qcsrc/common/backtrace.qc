void(string msg) backtrace {
	float dev, war;
	dev = builtin_cvar("developer");
	war = builtin_cvar("prvm_backtraceforwarnings");
	builtin_cvar_set("developer", "1");
	builtin_cvar_set("prvm_backtraceforwarnings", "1");
	print("\n");
	print("--- CUT HERE ---\nWARNING: ");
	print(msg);
	print("\n");
	remove(NULL); // isn't there any better way to cause a backtrace?
	print("\n--- CUT UNTIL HERE ---\n");
	builtin_cvar_set("developer", ftos(dev));
	builtin_cvar_set("prvm_backtraceforwarnings", ftos(war));
}
