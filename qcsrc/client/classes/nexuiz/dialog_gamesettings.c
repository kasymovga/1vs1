#ifdef INTERFACE
CLASS(NexuizGameSettingsDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizGameSettingsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizGameSettingsDialog, configureDialog, void(entity))
	ATTRIB(NexuizGameSettingsDialog, title, string, "Game Settings")
	ATTRIB(NexuizGameSettingsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizGameSettingsDialog, intendedWidth, float, 0.5)
	ATTRIB(NexuizGameSettingsDialog, rows, float, 26)
	ATTRIB(NexuizGameSettingsDialog, columns, float, 6)
	ATTRIB(NexuizGameSettingsDialog, name, string, "GameSettings")
ENDCLASS(NexuizGameSettingsDialog)
#endif

#ifdef IMPLEMENTATION
void configureDialogNexuizGameSettingsDialog(entity me) {
	if not(extension_DP_CSQC_QUERYRENDERENTITY)
		me.rows = me.rows + 2;

	if (game_type == GAME_TYPE_SINGLE)
		me.rows = me.rows - 2;

	configureDialogNexuizDialog(me); //Parent method
}

void(entity me, entity bnt) showHudDialogGameSettingsDialog {
	GUI_Show(GUI_HUD);
}

void(entity me) loadCvarsNexuizGameSettingsDialogGunAlpha {
	float f = (cvar("r_drawviewmodel") ? cvar("cl_gunalpha") : -1);
	me.value = ((f == 0) ? 1 : (f < 0 ? 0 : f));
}

void(entity me) saveCvarsNexuizGameSettingsDialogGunAlpha {
	if (me.value == 0)
		cvar_set("cl_gunalpha", "-1");
	else {
		cvar_set("r_drawviewmodel", "1");
		cvar_set("cl_gunalpha", ftos(me.value));
	}
}

void fillNexuizGameSettingsDialog(entity me)
{
	entity e;
	if (game_type == GAME_TYPE_SINGLE) {
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_weapon_wheel", _("Weapon wheel")));
	} else {
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Show names:")));
			if not(extension_DP_CSQC_QUERYRENDERENTITY)
				e.disabled = 1;
			me.TD(me, 1, 2.5, e = makeNexuizTextSlider("cl_shownames"));
				e.addValue(e, _("Never"), "0");
				e.addValue(e, _("Only for teammates"), "1");
				e.addValue(e, _("Always"), "2");
				e.configureNexuizTextSliderValues(e);
			if not(extension_DP_CSQC_QUERYRENDERENTITY) {
				e.disabled = 1;
				me.TDempty(me, 0.5);
				me.TD(me, 1, 0.25, e = makeNexuizTextLabel(0, "*"));
				e.colorL = SKINCOLOR_TEXT_WARNING;
			}
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Show names view sector:")));
			if not(extension_DP_CSQC_QUERYRENDERENTITY)
				e.disabled = 1;
			me.TD(me, 1, 2.5, e = makeNexuizTextSlider("cl_shownames_cos"));
				e.addValue(e, _("Wide"), "0");
				e.addValue(e, _("Narrow"), "0.9");
				e.addValue(e, _("Very narrow"), "0.99");
				e.configureNexuizTextSliderValues(e);
			if not(extension_DP_CSQC_QUERYRENDERENTITY) {
				e.disabled = 1;
				me.TDempty(me, 0.5);
				me.TD(me, 1, 0.25, e = makeNexuizTextLabel(0, "*"));
				e.colorL = SKINCOLOR_TEXT_WARNING;
			}
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_voice", _("Player voices")));
	}
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Weapon opacity:")));
		me.TD(me, 1, 2.5, e = makeNexuizSlider(0, 1, 0.05, "cl_gunalpha"));
		e.saveCvars = saveCvarsNexuizGameSettingsDialogGunAlpha;
		e.loadCvars = loadCvarsNexuizGameSettingsDialogGunAlpha;
		e.loadCvars(e); //cvar must be reloaded with custom loadCvars function
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Weapon position:")));
		me.TD(me, 1, 2.5, e = makeNexuizTextSlider("cl_gunalign"));
			e.addValue(e, _("Right"), "1");
			e.addValue(e, _("Left"), "2");
			e.addValue(e, _("Center or Right"), "3");
			e.addValue(e, _("Center or Left"), "4");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_gunalign_force_center", _("Force center position")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_nex_secondary_zoom_disable", _("Disable nex zoom with secondary attack")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_showweaponspawns", _("Weapon location hint")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_recoil", _("Recoil from shots")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_damage_screen_effects", _("Force screen effect on damage")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Damage indicator:")));
		me.TD(me, 1, 2.5, e = makeNexuizTextSlider("cl_damageindicator"));
			e.addValue(e, _("Hidden"), "0");
			e.addValue(e, _("Fast"), "0.5");
			e.addValue(e, _("Normal"), "1.5");
			e.addValue(e, _("Slow"), "2.5");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Announcer print:")));
		me.TD(me, 1, 2.5, e = makeNexuizTextSlider("cl_announcer_print"));
			e.addValue(e, _("Hidden"), "0");
			e.addValue(e, _("Fast"), "1");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Slow"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Weapon bar fade time:")));
		me.TD(me, 1, 2.5, e = makeNexuizTextSlider("sbar_weapons_fadetime"));
			e.addValue(e, _("Always hidden"), "0");
			e.addValue(e, _("Short"), "1");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Long"), "3");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "sbar_weapons_show_ammo", _("Show ammo in weapon bar")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "sbar_weapons_order", _("Reverse weapon order")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizTextLabel(0, _("Weapon bar fade speed:")));
		me.TD(me, 1, 2.5, e = makeNexuizTextSlider("sbar_weapons_fadespeed"));
			e.addValue(e, _("Fast"), "4");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Slow"), "1");
			e.addValue(e, _("Stopped"), "0");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_autoswitch", _("Auto switch weapons on pickup")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, (g_velocity_rounding ? 2.5 : 5), e = makeNexuizCheckBox(0, "cl_cts_strafe_helper", _("Show strafe helper in CTS")));
		if (g_velocity_rounding)
			me.TD(me, 1, 2.5, e = makeNexuizCheckBox(0, "cl_cts_snap_helper", _("and snap zones")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "cl_cts_position_helper", _("Show position helper in CTS")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizCheckBox(0, "cl_showacceleration", _("Show acceleration")));
		me.TD(me, 1, 2.5, e = makeNexuizCheckBox(0, "cl_cts_showacceleration", _("Auto enable in CTS")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeNexuizCheckBox(0, "cl_showspeed", _("Show speed")));
		me.TD(me, 1, 2.5, e = makeNexuizCheckBox(0, "cl_cts_showspeed", _("Auto enable in CTS")));
	if not(extension_DP_CSQC_QUERYRENDERENTITY) {
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 4, e = makeNexuizTextLabel(0, _("(*) Some features are unavailable. Your client is outdated.")));
			e.colorL = SKINCOLOR_TEXT_WARNING;
		me.TR(me);
			me.TDempty(me, 0.25);
			me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Download Rexuiz client here:")));
			e.colorL = SKINCOLOR_TEXT_WARNING;
			me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "http://rexuiz.com"));
			e.colorL = SKINCOLOR_TEXT_LINK;
	}
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "sbar_increment_maptime", "Incremental timer"));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "sbar_showcurrentammo", "Show only current ammo"));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 5, e = makeNexuizButton(_("HUD Selection..."), '0 0 0'));
			e.onClick = showHudDialogGameSettingsDialog;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, makeNexuizCommandButton("Apply immediately", '0 0 0', ";sendcvar cl_voice;sendcvar cl_gunalpha;sendcvar cl_autoswitch;sendcvar cl_gunalign_force_center;sendcvar cl_gunalign;sendcvar cl_showweaponspawns;sendcvar cl_damage_screen_effects;menu_cmd sync", COMMANDBUTTON_CLOSE));
}
#endif
