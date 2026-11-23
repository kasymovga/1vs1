entity spawnNexuizNexposee() {
	entity me; me = gui_nexposee_spawn();
	me.configureNexuizNexposee = configureNexuizNexposeeNexuizNexposee;
	me.close = closeNexuizNexposee;
	me.classname = "NexuizNexposee";
	return me;
}
entity makeNexuizNexposee();
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
