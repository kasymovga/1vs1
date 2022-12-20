#ifdef INTERFACE
CLASS(NexuizVideoSettingsBasicTab) EXTENDS(NexuizTab)
	METHOD(NexuizVideoSettingsBasicTab, fill, void(entity))
	ATTRIB(NexuizVideoSettingsBasicTab, title, string, _("Basic"))
	ATTRIB(NexuizVideoSettingsBasicTab, intendedWidth, float, 1)
	ATTRIB(NexuizVideoSettingsBasicTab, rows, float, 20)
	ATTRIB(NexuizVideoSettingsBasicTab, columns, float, 6.5)
ENDCLASS(NexuizVideoSettingsBasicTab)
entity makeNexuizVideoSettingsBasicTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizVideoSettingsBasicTab()
{
	entity me;
	me = spawnNexuizVideoSettingsBasicTab();
	me.configureDialog(me);
	return me;
}
void(entity e1, entity e2) fxxaChangedNexuizVideoSettingsBasicTab {
	print("fxxa changed\n");
	if (cvar("r_fxaa")) {
		cvar_set("vid_samples", "1");
	}
}
void(entity me) loadCvarsAASliderNexuizVideoSettingsBasicTab {
	if (cvar("r_fxaa"))
		me.setValueFromIdentifier(me, "fxaa");
	else if (cvar_string(me.cvarName) == "fxaa") //wtf?
		me.setValueFromIdentifier(me, "0");
	else
		me.setValueFromIdentifier(me, cvar_string(me.cvarName));
}
void(entity me) saveCvarsAASliderNexuizVideoSettingsBasicTab {
	if (me.value >= 0 && me.value < me.nValues) {
		string s = me.getIdentifier(me);
		if (s == "fxaa") {
			cvar_set(me.cvarName, "1");
			cvar_set("r_fxaa", "1");
		} else
			cvar_set(me.cvarName, me.getIdentifier(me));
	}
}
void fillNexuizVideoSettingsBasicTab(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "vid_fullscreen", _("Full screen")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "vid_desktopfullscreen", _("Desktop resolution")));
		gui_set_dependent(e, "vid_fullscreen", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Resolution:")));
		me.TD(me, 1, 2, e = makeNexuizResolutionSlider());
		gui_set_dependent_or(e, "vid_fullscreen", 0, 0, "vid_desktopfullscreen", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Resolution scale:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.1, 1, 0.02, "r_viewscale"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Max FPS:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("cl_maxfps"));
			e.addValue(e, "125", "125");
			e.addValue(e, "250", "250");
			e.addValue(e, "500", "500");
			e.addValue(e, _("Unlimited"), "0");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Brightness:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.0, 0.5, 0.02, "v_brightness"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Contrast:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(1.0, 3.0, 0.05, "v_contrast"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Gamma:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.5, 2.0, 0.05, "v_gamma"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Contrast boost:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(1.0, 5.0, 0.1, "v_contrastboost"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Saturation:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.5, 2.0, 0.05, "r_glsl_saturation"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Ambient light:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 20.0, 1.0, "r_ambient"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Intensity:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.5, 2.0, 0.05, "r_hdr_scenebrightness"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Tint effect:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.05, "gl_polyblend"));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 0.5, 2, e = makeNexuizTextLabel(0, _("* From water, hurt and powerups")));
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("r_subdivisions_tolerance"));
			e.addValue(e, _("Lowest"), "16");
			e.addValue(e, _("Low"), "8");
			e.addValue(e, _("Normal"), "4");
			e.addValue(e, _("Good"), "3");
			e.addValue(e, _("Best"), "2");
			e.addValue(e, _("Insane"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Texture quality:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("gl_picmip"));
			e.addValue(e, _("Lowest"), "16");
			e.addValue(e, _("Low"), "4");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Good"), "1");
			e.addValue(e, _("Best"), "0");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("World texture quality:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("gl_picmip_world"));
			e.addValue(e, _("Lowest"), "16");
			e.addValue(e, _("Low"), "4");
			e.addValue(e, _("Normal"), "2");
			e.addValue(e, _("Good"), "1");
			e.addValue(e, _("Best"), "0");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Antialiasing:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("vid_samples"));
			e.addValue(e, _("Disabled"), "1");
			e.addValue(e, _("FXAA"), "fxaa");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
			e.configureNexuizTextSliderValues(e);
			e.loadCvars = loadCvarsAASliderNexuizVideoSettingsBasicTab;
			e.saveCvars = saveCvarsAASliderNexuizVideoSettingsBasicTab;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("gl_texture_anisotropy"));
			e.addValue(e, _("Disabled"), "1");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
			e.addValue(e, "8x", "8");
			e.addValue(e, "16x", "16");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Motion blur:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.1, "r_motionblur"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Damage blur:")));
			gui_set_dependent(e, "r_motionblur", 0, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.1, "r_damageblur"));
			gui_set_dependent(e, "r_motionblur", 0, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_water", _("Reflections:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("r_water_resolutionmultiplier"));
			e.addValue(e, _("Blurred"), "0.25");
			e.addValue(e, _("Good"), "0.5");
			e.addValue(e, _("Sharp"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "r_shadow_realtime_dlight", _("Realtime dynamic lighting")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_shadow_realtime_dlight_shadows", _("Shadows")));
			gui_set_dependent(e, "r_shadow_realtime_dlight", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "r_shadow_realtime_world", _("Realtime world lighting")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_shadow_realtime_world_shadows", _("Shadows")));
			gui_set_dependent(e, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeNexuizCheckBox(0, "r_shadow_usenormalmap", _("Use normal maps")));
			gui_set_dependent_or(e, "r_shadow_realtime_dlight", 1, 1, "r_shadow_realtime_world", 1, 1);
}
#endif
