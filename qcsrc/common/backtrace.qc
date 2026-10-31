void(string msg) backtrace {
	float dev, war;
	dev = vm_cvar("developer");
	war = vm_cvar("prvm_backtraceforwarnings");
	vm_cvar_set("developer", "1");
	vm_cvar_set("prvm_backtraceforwarnings", "1");
	print("\n");
	print("--- CUT HERE ---\nWARNING: ");
	print(msg);
	print("\n");
	remove(NULL); // isn't there any better way to cause a backtrace?
	print("\n--- CUT UNTIL HERE ---\n");
	vm_cvar_set("developer", ftos(dev));
	vm_cvar_set("prvm_backtraceforwarnings", ftos(war));
}
