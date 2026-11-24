void(entity me) gui_rexuiz_dialog_singleplayer_fill;

entity(void) gui_rexuiz_dialog_singleplayer_spawn {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = gui_rexuiz_dialog_singleplayer_fill;
	me.title = _("Singleplayer");
	me.color = SKINCOLOR_DIALOG_SINGLEPLAYER;
	me.intendedWidth = 0.80;
	me.rows = 24;
	me.columns = 5;
	me.classname = "NexuizSingleplayerDialog";
	return me;
}

void(entity me) gui_rexuiz_dialog_singleplayer_fill {
	entity mc, e;
	mc = gui_rexuiz_tabcontroller_make(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Campaign"), makeNexuizCampaignTab()));
				//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Custom"), makeNexuizServerCreateTab(TRUE)));
				//setDependentStringNotEqual(e, "_cl_name", "Player");
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
