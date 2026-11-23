entity spawnNexuizNetworkSettingsTab() {
	entity me; me = gui_rexuiz_tab_spawn();
	me.fill = fillNexuizNetworkSettingsTab;
	me.title = _("Network");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.classname = "NexuizNetworkSettingsTab";
	return me;
}
entity makeNexuizNetworkSettingsTab();
entity makeNexuizNetworkSettingsTab()
{
	entity me;
	me = spawnNexuizNetworkSettingsTab();
	me.configureDialog(me);
	return me;
}
void fillNexuizNetworkSettingsTab(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "shownetgraph", _("Show netgraph")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = gui_rexuiz_textlabel_make(0, _("Network speed:")));
		me.TD(me, 1, 1.75, e = gui_rexuiz_textslider_make("_cl_rate"));
				e.addValue(e, _("Low"), "8000");
				e.addValue(e, _("Medium"), "24000");
				e.addValue(e, _("High"), "64000");
				e.addValue(e, _("Unlimited"), "128000");
				e.configureNexuizTextSliderValues(e);
				me.TR(me);
		me.TD(me, 1, 1.25, e = gui_rexuiz_textlabel_make(0, _("Input packets/s:")));
		me.TD(me, 1, 1.75, e = gui_rexuiz_slider_make(20, 125, 1, "cl_netfps"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("HTTP downloads:")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.15, e = gui_rexuiz_textlabel_make(0, _("Downloads:")));
		me.TD(me, 1, 1.75, e = gui_rexuiz_slider_make(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.15, e = gui_rexuiz_textlabel_make(0, _("Speed (kB/s):")));
		me.TD(me, 1, 1.75, e = gui_rexuiz_slider_make(100, 10000, 100, "cl_curl_maxspeed"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = gui_rexuiz_textlabel_make(0, _("Client UDP port:")));
		me.TD(me, 1, 0.64, e = gui_rexuiz_inputbox_make(0, "cl_port"));
	me.TR(me);
		me.TDempty(me, 0.05);
		me.TD(me, 0.5, 3, e = gui_rexuiz_textlabel_make(0, _("* Keep this set to 0 until you know what this setting does")));
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
}
