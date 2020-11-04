#ifdef INTERFACE
CLASS(NexuizRadarDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizRadarDialog, toString, string(entity))
	METHOD(NexuizRadarDialog, fill, void(entity))
	METHOD(NexuizRadarDialog, showNotify, void(entity))
	ATTRIB(NexuizRadarDialog, title, string, _("HUD & Waypoints"))
	ATTRIB(NexuizRadarDialog, color, vector, SKINCOLOR_DIALOG_RADAR)
	ATTRIB(NexuizRadarDialog, intendedWidth, float, 0.7)
	ATTRIB(NexuizRadarDialog, rows, float, 24)
	ATTRIB(NexuizRadarDialog, columns, float, 4)
ENDCLASS(NexuizRadarDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizRadarDialog(entity me)
{
        loadAllCvars(me);
}
string toStringNexuizRadarDialog(entity me)
{
	return "XXX";
}
void fillNexuizRadarDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, _("HUD settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizCheckBoxEx(100, 110, "viewsize", _("Background:")));
		me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_alpha_bg"));
			setDependent(e, "viewsize", 0, 100);
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default red:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_r"));
				setDependent(e, "viewsize", 0, 100);
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default green:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_g"));
				setDependent(e, "viewsize", 0, 100);
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Default blue:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "sbar_color_bg_b"));
				setDependent(e, "viewsize", 0, 100);
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Team color:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.1, 1, 0.01, "sbar_color_bg_team"));
				setDependent(e, "viewsize", 0, 100);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, _("Waypoint settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeNexuizCheckBox(1, "cl_hidewaypoints", _("Show base waypoints")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Waypoint scale:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.5, 1.5, 0.01, "g_waypointsprite_scale"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
 		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Waypoint alpha:")));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.1, 1, 0.01, "g_waypointsprite_alpha"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

#endif
