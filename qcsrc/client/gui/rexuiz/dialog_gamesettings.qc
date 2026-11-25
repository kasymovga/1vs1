void(entity me) gui_rexuiz_dialog_gamesettings_configure;
void(entity me) gui_rexuiz_dialog_gamesettings_fill;

entity(void) gui_rexuiz_dialog_gamesettings_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_gamesettings_fill;
	me.configureDialog = gui_rexuiz_dialog_gamesettings_configure;
	me.title = "Game Settings";
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.5;
	me.rows = 24;
	me.columns = 6;
	me.name = "GameSettings";
	me.classname = "NexuizGameSettingsDialog";
	return me;
}

void(entity me) gui_rexuiz_dialog_gamesettings_configure {
	if not(extension_DP_CSQC_QUERYRENDERENTITY)
		me.rows = me.rows + 2;

	if (game_type == GAME_TYPE_SINGLE)
		me.rows = me.rows - 2;

	if (game_type == GAME_TYPE_CTS)
		me.rows = me.rows + 4;

	RM({
		me.columns += 5;
		me.intendedWidth += 0.4;
	})
	gui_rexuiz_dialog_configure(me); //Parent method
}

void(entity me, entity bnt) gui_rexuiz_dialog_gamesettings_hud {
	GUI_Show(GUI_HUD);
}

void(entity me) gui_rexuiz_dialog_gamesettings_gun_alpha_load {
	float f = (cvar("r_drawviewmodel") ? cvar("cl_gunalpha") : -1);
	me.value = ((f == 0) ? 1 : (f < 0 ? 0 : f));
}

void(entity me) gui_rexuiz_dialog_gamesettings_gun_alpha_save {
	if (me.value == 0)
		cvar_set("cl_gunalpha", "-1");
	else {
		cvar_set("r_drawviewmodel", "1");
		cvar_set("cl_gunalpha", ftos(me.value));
	}
}

void(entity me) gui_rexuiz_dialog_gamesettings_fill {
	entity e;
	me.gotoRC(me, -1, 0.25); me.setFirstColumn(me, me.currentColumn);
	if (game_type == GAME_TYPE_SINGLE) {
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_weapon_wheel", _("Weapon wheel")));
	} else {
		me.TR(me);
			me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Show names:")));
				if not(extension_DP_CSQC_QUERYRENDERENTITY)
					e.disabled = 1;

			me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_shownames"));
				e.addValue(e, _("Never"), "0");
				e.addValue(e, _("Only for teammates"), "1");
				e.addValue(e, _("Always"), "2");
				e.configureNexuizTextSliderValues(e);
				if not(extension_DP_CSQC_QUERYRENDERENTITY) {
					e.disabled = 1;
					me.TDempty(me, 0.5);
					me.TD(me, 1, 0.25, e = gui_rexuiz_textlabel_make(0, "*"));
						e.colorL = SKINCOLOR_TEXT_WARNING;
				}
		me.TR(me);
			me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Show names view sector:")));
			if not(extension_DP_CSQC_QUERYRENDERENTITY)
				e.disabled = 1;

			me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_shownames_cos"));
				e.addValue(e, _("Wide"), "0");
				e.addValue(e, _("Narrow"), "0.9");
				e.addValue(e, _("Very narrow"), "0.99");
				e.configureNexuizTextSliderValues(e);
				if not(extension_DP_CSQC_QUERYRENDERENTITY) {
					e.disabled = 1;
					me.TDempty(me, 0.25);
					me.TD(me, 1, 0.25, e = gui_rexuiz_textlabel_make(0, "*"));
						e.colorL = SKINCOLOR_TEXT_WARNING;
				}
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_voice", _("Player voices")));
	}
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Weapon alpha:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_slider_make(0, 1, 0.05, "cl_gunalpha"));
			e.saveCvars = gui_rexuiz_dialog_gamesettings_gun_alpha_save;
			e.loadCvars = gui_rexuiz_dialog_gamesettings_gun_alpha_load;
			e.loadCvars(e); //cvar must be reloaded with custom loadCvars function
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Weapon position:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_gunalign"));
			e.addValue(e, _("Right"), "1");
			e.addValue(e, _("Left"), "2");
			e.addValue(e, _("Right or center"), "3");
			e.addValue(e, _("Left or center"), "4");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_gunalign_force_center", _("Force center position")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_nex_secondary_zoom_disable", _("Disable nex zoom with secondary attack")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_showweaponspawns", _("Weapon location hint")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_recoil", _("Recoil from shots")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_damage_screen_effects", _("Force screen effect on damage")));
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Damage indicator:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_damageindicator"));
			e.addValue(e, _("Hidden"), "0");
			e.addValue(e, _("Fast"), "0.5");
			e.addValue(e, _("Normal"), "1.5");
			e.addValue(e, _("Slow"), "2.5");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Announcer print:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_announcer_print"));
			e.addValue(e, _("Hidden"), "0");
			e.addValue(e, _("Fast"), "1");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Slow"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Weapon bar fade time:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("sbar_weapons_fadetime"));
			e.addValue(e, _("Always hidden"), "0");
			e.addValue(e, _("Short"), "1");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Long"), "3");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "sbar_weapons_show_ammo", _("Show ammo in weapon bar")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "sbar_weapons_order", _("Reverse weapon order")));
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("Weapon bar fade speed:")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("sbar_weapons_fadespeed"));
			e.addValue(e, _("Fast"), "4");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Slow"), "1");
			e.addValue(e, _("Stopped"), "0");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_autoswitch", _("Auto switch weapons on pickup")));
	if (game_type == GAME_TYPE_CTS) {
		me.TR(me);
			me.TD(me, 1, (g_velocity_rounding ? 2.5 : 5), e = gui_rexuiz_checkbox_make(0, "cl_cts_strafe_helper", _("Show strafe helper in CTS")));
			if (g_velocity_rounding)
				me.TD(me, 1, 2.5, e = gui_rexuiz_checkbox_make(0, "cl_cts_snap_helper", _("and snap zones")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_cts_position_helper", _("Show position helper in CTS")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "cl_cts_split_timer", _("Show split timer in CTS")));
		me.TR(me);
			me.TD(me, 1, 2.5, e = gui_rexuiz_textlabel_make(0, _("CTS Ghost:")));
			me.TD(me, 1, 2.5, e = gui_rexuiz_textslider_make("cl_cts_ghost"));
				e.addValue(e, _("None"), "-1");
				e.addValue(e, _("Session"), "0");
				e.addValue(e, _("Global"), "1");
				e.addValue(e, _("Personal"), "2");
				e.configureNexuizTextSliderValues(e);
	}
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_checkbox_make(0, "cl_showacceleration", _("Show acceleration")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_checkbox_make(0, "cl_cts_showacceleration", _("Auto enable in CTS")));
	me.TR(me);
		me.TD(me, 1, 2.5, e = gui_rexuiz_checkbox_make(0, "cl_showspeed", _("Show speed")));
		me.TD(me, 1, 2.5, e = gui_rexuiz_checkbox_make(0, "cl_cts_showspeed", _("Auto enable in CTS")));
	if not(extension_DP_CSQC_QUERYRENDERENTITY) {
		me.TR(me);
			me.TD(me, 1, 4, e = gui_rexuiz_textlabel_make(0, _("(*) Some features are unavailable. Your client is outdated.")));
				e.colorL = SKINCOLOR_TEXT_WARNING;
		me.TR(me);
			me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Download Rexuiz client here:")));
				e.colorL = SKINCOLOR_TEXT_WARNING;
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, "http://rexuiz.com"));
				e.colorL = SKINCOLOR_TEXT_LINK;
	}
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "sbar_increment_maptime", _("Incremental timer")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "sbar_showcurrentammo", _("Show only current ammo")));
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_button_make(_("HUD Selection..."), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_gamesettings_hud;
	RM({
		me.gotoRC(me, -1, 6); me.setFirstColumn(me, me.currentColumn);
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_textlabel_make(0, _("RM Settings:")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_nobigtext", _("No big text")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(1, "rm_simpleeffects", _("Effects for textual notifications")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_hidebigcomments", _("Hide big commentaries")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_showrankings", _("Show top players in the HUD")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_crosshealth", _("Crosshair health color")));
		me.TR(me);
			me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, _("Crosshair ring size:")));
			me.TD(me, 1, 3, e = gui_rexuiz_slider_make(0, 10, 0.05, "rm_hud_crosshair_ring_size"));
		me.TR(me);
			me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, _("Crosshair ring opacity:")));
			me.TD(me, 1, 3, e = gui_rexuiz_slider_make(0, 1, 0.05, "rm_hud_crosshair_ring_alpha"));
		me.TR(me);
			me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, _("Crosshair ring opacity:")));
			me.TD(me, 1, 3, e = gui_rexuiz_slider_make(0, 1, 0.05, "rm_hud_crosshair_ring_alpha"));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(1, "rm_notimer", _("\"time\" column in scoreboard")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_visualscore", _("Scoring notifications in the HUD")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_shownadgetregen", _("Show Nadget regeneration in seconds")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_hud_healthcolor", _("Health-colored HUD")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_showspec", _("Show spectators")));
		me.TR(me);
			me.TD(me, 1, 5, e = gui_rexuiz_checkbox_make(0, "rm_anonspec", _("Spectate anonymously")));
	})
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, gui_rexuiz_commandbutton_make("Apply immediately", '0 0 0', ";sendcvar cl_voice;sendcvar cl_gunalpha;sendcvar cl_autoswitch;sendcvar cl_gunalign_force_center;sendcvar cl_gunalign;sendcvar cl_showweaponspawns;sendcvar cl_damage_screen_effects;menu_cmd sync;sendcvar rm_showspec;sendcvar rm_anonspec;sendcvar cl_cts_ghost", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
}
