entity(void) gui_rexuiz_bigcommandbutton_spawn {
	entity me; me = gui_rexuiz_commandbutton_spawn();
	me.image = SKINGFX_BUTTON_BIG;
	me.grayImage = SKINGFX_BUTTON_BIG_GRAY;
	me.classname = "NexuizCommandButton";
	return me;
}

entity(string theText, vector theColor, string theCommand, float theFlags) gui_rexuiz_bigcommandbutton_make {
	entity me;
	me = gui_rexuiz_bigcommandbutton_spawn();
	me.configureNexuizCommandButton(me, theText, theColor, theCommand, theFlags);
	return me;
}
