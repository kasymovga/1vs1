entity spawnNexuizTabController() {
	entity me; me = gui_modalcontroller_spawn();
	me.configureNexuizTabController = configureNexuizTabControllerNexuizTabController;
	me.makeTabButton = makeTabButtonNexuizTabController;
	me.rows = 0;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_BUTTON;
	me.classname = "NexuizTabController";
	return me;
}
entity makeNexuizTabController(float theRows);
entity makeNexuizTabController(float theRows)
{
	entity me;
	me = spawnNexuizTabController();
	me.configureNexuizTabController(me, theRows);
	return me;
}
void configureNexuizTabControllerNexuizTabController(entity me, float theRows)
{
	me.rows = theRows;
}
entity makeTabButtonNexuizTabController(entity me, string theTitle, entity tab)
{
	entity b;
	if(me.rows != tab.rows)
		error(_("Tab dialog height mismatch!"));
	b = gui_rexuiz_button_make(theTitle, '0 0 0');
		me.addTab(me, tab, b);
	// TODO make this real tab buttons (with color parameters, and different gfx)
	return b;
}
