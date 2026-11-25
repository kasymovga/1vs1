void(entity me) gui_rexuiz_tab_multiplayer_demolist_fill;

entity(void) gui_rexuiz_tab_multiplayer_demolist_spawn {
	entity me = gui_rexuiz_tab_spawn();
	me.fill = gui_rexuiz_tab_multiplayer_demolist_fill;
	me.title = _("Demo");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.name = "DemoBrowser";
	me.classname = "NexuizDemoBrowserTab";
	return me;
}

entity(void) gui_rexuiz_tab_multiplayer_demolist_make {
	entity me = gui_rexuiz_tab_multiplayer_demolist_spawn();
	me.configureDialog(me);
	return me;
}

void(entity me) gui_rexuiz_tab_multiplayer_demolist_fill {
	entity e;
	entity btn;
	entity dlist;
	me.TR(me);
		me.TD(me, 1, me.columns / 2, e = gui_rexuiz_checkbox_make(0, "cl_autodemo", _("Record demos while playing")));
		me.TD(me, 1, me.columns / 2, e = gui_rexuiz_checkbox_make(0, "menu_demo_hud", _("Enable demo player")));
	me.TR(me);
	dlist = gui_rexuiz_demolist_make();
	me.TR(me);
		me.TD(me, 1, 0.5, e = gui_rexuiz_textlabel_make(0, _("Filter:")));
		me.TD(me, 1, 0.5, btn = gui_rexuiz_button_make(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, me.columns - 1, e = gui_rexuiz_inputbox_make(0, NULL));
			e.onChange = gui_rexuiz_demolist_filter_change;
			e.onChangeEntity = dlist;
			btn.onClickEntity = e;
			dlist.controlledTextbox = e;
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, dlist);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, e = gui_rexuiz_button_make(_("Timedemo"), '0 0 0'));
			e.onClick = gui_rexuiz_demolist_timedemo_click;
			e.onClickEntity = dlist;
		me.TD(me, 1, me.columns / 2, e = gui_rexuiz_button_make(_("Play"), '0 0 0'));
			e.onClick = gui_rexuiz_demolist_start_click;
			e.onClickEntity = dlist;
}
