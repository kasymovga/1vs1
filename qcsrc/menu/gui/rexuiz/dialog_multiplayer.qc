void(entity me) gui_rexuiz_dialog_multiplayer_fill;

entity(void) gui_rexuiz_dialog_multiplayer_spawn {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = gui_rexuiz_dialog_multiplayer_fill;
	me.title = _("Multiplayer");
	me.color = SKINCOLOR_DIALOG_MULTIPLAYER;
	me.intendedWidth = 0.96;
	me.rows = 24;
	me.columns = 6;
	me.classname = "NexuizMultiplayerDialog";
	return me;
}

void(entity me) gui_rexuiz_dialog_multiplayer_fill {
	entity mc, e;
	mc = gui_rexuiz_tabcontroller_make(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Servers"), gui_rexuiz_tab_multiplayer_serverlist_make()));
			//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Create"), rexuiz_gui_tab_multiplayer_create_make(FALSE)));
			//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Demos"), gui_rexuiz_tab_multiplayer_demolist_make()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
