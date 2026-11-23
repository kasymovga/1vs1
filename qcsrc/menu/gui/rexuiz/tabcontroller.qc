void(entity me, float theRows) gui_rexuiz_tabcontroller_configure;
entity(entity me, string theTitle, entity tab) gui_rexuiz_tabcontroller_button_make;

entity(void) gui_rexuiz_tabcontroller_spawn {
	entity me = gui_modalcontroller_spawn();
	me.configureNexuizTabController = gui_rexuiz_tabcontroller_configure;
	me.makeTabButton = gui_rexuiz_tabcontroller_button_make;
	me.rows = 0;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_BUTTON;
	me.classname = "NexuizTabController";
	return me;
}

entity(float theRows) gui_rexuiz_tabcontroller_make {
	entity me = gui_rexuiz_tabcontroller_spawn();
	me.configureNexuizTabController(me, theRows);
	return me;
}

void(entity me, float theRows) gui_rexuiz_tabcontroller_configure {
	me.rows = theRows;
}

entity(entity me, string theTitle, entity tab) gui_rexuiz_tabcontroller_button_make {
	entity b;
	if (me.rows != tab.rows)
		error(_("Tab dialog height mismatch!"));

	b = gui_rexuiz_button_make(theTitle, '0 0 0');
	me.addTab(me, tab, b);
	// TODO make this real tab buttons (with color parameters, and different gfx)
	return b;
}
