#ifdef INTERFACE
CLASS(NexuizNetworkSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizNetworkSettingsTab, fill, void(entity))
	ATTRIB(NexuizNetworkSettingsTab, title, string, _("Network"))
	ATTRIB(NexuizNetworkSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizNetworkSettingsTab, rows, float, 22)
	ATTRIB(NexuizNetworkSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizNetworkSettingsTab)
entity makeNexuizNetworkSettingsTab();
#endif

#ifdef IMPLEMENTATION
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
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "shownetgraph", _("Show netgraph")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Network speed:")));
		me.TD(me, 1, 1.75, e = makeNexuizTextSlider("_cl_rate"));
			e.addValue(e, "56k", "4000");
			e.addValue(e, "ISDN", "7000");
			e.addValue(e, _("Slow ADSL"), "15000");
			e.addValue(e, _("Fast ADSL"), "20000");
			e.addValue(e, _("Broadband"), "25000");
			e.addValue(e, _("Unlimited"), "128000");
			e.configureNexuizTextSliderValues(e);
    me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Input packets/s:")));
		me.TD(me, 1, 1.75, e = makeNexuizSlider(20, 125, 1, "cl_netfps"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("HTTP downloads:")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.15, e = makeNexuizTextLabel(0, _("Downloads:")));
		me.TD(me, 1, 1.75, e = makeNexuizSlider(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.15, e = makeNexuizTextLabel(0, _("Speed (kB/s):")));
		me.TD(me, 1, 1.75, e = makeNexuizSlider(10, 5000, 10, "cl_curl_maxspeed"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Client UDP port:")));
		me.TD(me, 1, 0.64, e = makeNexuizInputBox(0, "cl_port"));
}
#endif
