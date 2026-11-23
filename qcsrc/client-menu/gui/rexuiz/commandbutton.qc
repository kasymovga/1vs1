entity(void) gui_rexuiz_commandbutton_spawn {
	entity me; me = gui_rexuiz_button_spawn();
	me.configureNexuizCommandButton = configureNexuizCommandButtonNexuizCommandButton;
	me.onClickCommand = NULL;
	me.flags = 0;
	me.classname = "NexuizCommandButton";
	return me;
}

entity(string theText, vector theColor, string theCommand, float theFlags) gui_rexuiz_commandbutton_make {
	entity me = gui_rexuiz_commandbutton_spawn();
	me.configureNexuizCommandButton(me, theText, theColor, theCommand, theFlags);
	return me;
}

void(entity me, entity theOther) gui_rexuiz_commandbutton_click {
	//if(me.flags & GUI_REXUIZ_COMMANDBUTTON_APPLY)
	//	saveAllCvars(me.parent);
	localcmd("\n", me.onClickCommand, "\n");
	//if(me.flags & GUI_REXUIZ_COMMANDBUTTON_REVERT)
	//	loadAllCvars(me.parent);
	if(me.flags & 1)
#ifdef MENUQC
		menu_goto(NULL);
#endif
#ifdef CSQC
		GUI_Hide();
#endif
}
void configureNexuizCommandButtonNexuizCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags)
{
	me.configureNexuizButton(me, theText, theColor);
	me.onClickCommand = theCommand;
	me.flags = theFlags;
	me.onClick = gui_rexuiz_commandbutton_click;
	me.onClickEntity = me;
}
