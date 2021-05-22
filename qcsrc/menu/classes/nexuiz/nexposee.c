#ifdef INTERFACE
CLASS(NexuizNexposee) EXTENDS(Nexposee)
	METHOD(NexuizNexposee, configureNexuizNexposee, void(entity))
	METHOD(NexuizNexposee, close, void(entity))
ENDCLASS(NexuizNexposee)
entity makeNexuizNexposee();
#endif

#ifdef IMPLEMENTATION
entity() makeNexuizNexposee {
	entity me;
	me = spawnNexuizNexposee();
	me.configureNexuizNexposee(me);
	return me;
}

void(entity me) configureNexuizNexposeeNexuizNexposee { }

void(entity me) closeNexuizNexposee {
	menu_goto(NULL); // hide
}
#endif
