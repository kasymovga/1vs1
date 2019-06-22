void(string msg) backtrace {
    float dev, war;
    dev = cvar("developer");
    war = cvar("prvm_backtraceforwarnings");
    cvar_set("developer", "1");
    cvar_set("prvm_backtraceforwarnings", "1");
    print("\n");
    print("--- CUT HERE ---\nWARNING: ");
    print(msg);
    print("\n");
    remove(world); // isn't there any better way to cause a backtrace?
    print("\n--- CUT UNTIL HERE ---\n");
    cvar_set("developer", ftos(dev));
    cvar_set("prvm_backtraceforwarnings", ftos(war));
}
