void(entity me) gui_rexuiz_nexposee_configure;
void(entity me) gui_rexuiz_nexposee_close;

entity(void) gui_rexuiz_nexposee_spawn {
	entity me = gui_nexposee_spawn();
	me.configureNexuizNexposee = gui_rexuiz_nexposee_configure;
	me.close = gui_rexuiz_nexposee_close;
	me.classname = "NexuizNexposee";
	return me;
}

entity(void) gui_rexuiz_nexposee_make {
	entity me = gui_rexuiz_nexposee_spawn();
	me.configureNexuizNexposee(me);
	return me;
}

void(entity me) gui_rexuiz_nexposee_configure {
}

void(entity me) gui_rexuiz_nexposee_close {
	menu_goto(NULL); // hide
}
