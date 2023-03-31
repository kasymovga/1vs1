#ifdef INTERFACE
CLASS(NexuizHUDDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizHUDDialog, toString, string(entity))
	METHOD(NexuizHUDDialog, fill, void(entity))
	METHOD(NexuizHUDDialog, showNotify, void(entity))
	ATTRIB(NexuizHUDDialog, title, string, _("HUD & Waypoints"))
	ATTRIB(NexuizHUDDialog, color, vector, SKINCOLOR_DIALOG_RADAR)
	ATTRIB(NexuizHUDDialog, intendedWidth, float, 0.7)
	ATTRIB(NexuizHUDDialog, rows, float, 14)
	ATTRIB(NexuizHUDDialog, columns, float, 4)
ENDCLASS(NexuizHUDDialog)
#endif

#ifdef IMPLEMENTATION
void(entity me) showNotifyNexuizHUDDialog {
	gui_load_all_cvars(me);
}

string(entity me) toStringNexuizHUDDialog {
	return "XXX";
}

void(entity me) fillNexuizHUDDialog {
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, _("HUD settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizCheckBoxEx(100, 110, "viewsize", _("Background:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_alpha_bg"));
			gui_set_dependent(e, "viewsize", 0, 100);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default red:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_r"));
			gui_set_dependent(e, "viewsize", 0, 100);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default green:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_g"));
			gui_set_dependent(e, "viewsize", 0, 100);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default blue:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_b"));
			gui_set_dependent(e, "viewsize", 0, 100);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Team color:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0.1, 1, 0.01, "sbar_color_bg_team"));
			gui_set_dependent(e, "viewsize", 0, 100);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Show radar:")));
		me.TD(me, 1, 2.6, e = makeNexuizTextSlider("cl_teamradar"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Teamplay"), "1");
			e.addValue(e, _("Always"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Radar position:")));
		me.TD(me, 1, 2.6, e = makeNexuizTextSlider("cl_teamradar_position"));
			e.addValue(e, _("Left-top"), "0 0");
			e.addValue(e, _("Left-middle"), "0 0.5");
			e.addValue(e, _("Left-bottom"), "0 1");
			e.addValue(e, _("Center-top"), "0.5 0");
			e.addValue(e, _("Center-bottom"), "0.5 1");
			e.addValue(e, _("Right-top"), "1 0");
			e.addValue(e, _("Right-middle"), "1 0.5");
			e.addValue(e, _("Right-bottom"), "1 1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, _("Waypoint settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeNexuizCheckBox(1, "cl_hidewaypoints", _("Show base waypoints")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Waypoint scale:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.5, 1.5, 0.01, "g_waypointsprite_scale"));
				gui_set_dependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
 		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Waypoint alpha:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.1, 1, 0.01, "g_waypointsprite_alpha"));
				gui_set_dependent(e, "cl_hidewaypoints", 0, 0);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

#endif
