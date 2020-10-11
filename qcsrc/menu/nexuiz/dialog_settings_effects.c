#ifdef INTERFACE
CLASS(NexuizEffectsSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizEffectsSettingsTab, fill, void(entity))
	ATTRIB(NexuizEffectsSettingsTab, title, string, _("Effects"))
	ATTRIB(NexuizEffectsSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizEffectsSettingsTab, rows, float, 17)
	ATTRIB(NexuizEffectsSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizEffectsSettingsTab)
entity makeNexuizEffectsSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizEffectsSettingsTab()
{
	entity me;
	me = spawnNexuizEffectsSettingsTab();
	me.configureDialog(me);
	return me;
}

void casingsCountUpdate(entity e, entity me) {
	cvar_set("cl_casings", ftos(!!cvar("cl_casings_maxcount")));
}

void gibsUpdate(entity gibsMaxCount, entity me) {
	if (cvar("cl_nogibs") == 1) {
		if (cvar("cl_gibs_maxcount"))
			cvar_set("cl_gibs_maxcount", "0");
	} else if not(cvar("cl_gibs_maxcount"))
		cvar_set("cl_gibs_maxcount", "30");

	gibsMaxCount.loadCvars(gibsMaxCount);
}

void gibsCountUpdate(entity gibs, entity me) {
	if not(cvar("cl_gibs_maxcount")) {
		if (cvar("cl_nogibs") < 1)
			cvar_set("cl_nogibs", "1");
	} else if (cvar("cl_nogibs") >= 1) {
		cvar_set("cl_nogibs", "0.5");
	}
	gibs.loadCvars(gibs);
}

void fillNexuizEffectsSettingsTab(entity me)
{
	entity e;
	float n;
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Quality preset:")));
		n = 5;
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Low"), '0 0 0', "exec effects-low.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Medium"), '0 0 0', "exec effects-med.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Normal"), '0 0 0', "exec effects-normal.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("High"), '0 0 0', "exec effects-high.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Ultra"), '0 0 0', "exec effects-ultra.cfg", 0));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("r_subdivisions_tolerance"));
			e.addValue(e, _("Lowest"), "16");
			e.addValue(e, _("Low"), "8");
			e.addValue(e, _("Normal"), "4");
			e.addValue(e, _("Good"), "3");
			e.addValue(e, _("Best"), "2");
			e.addValue(e, _("Insane"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Antialiasing:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("vid_samples"));
			e.addValue(e, _("Disabled"), "1");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
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
	me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("gl_texture_anisotropy"));
			e.addValue(e, _("Disabled"), "1");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
			e.addValue(e, "8x", "8");
			e.addValue(e, "16x", "16");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Particle quality:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.1, 1.0, 0.05, "cl_particles_quality"));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Particle dist.:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(500, 2000, 100, "r_drawparticles_drawdistance"));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Gibs:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("cl_nogibs"));
			e.addValue(e, _("None"), "1");
			e.addValue(e, _("Few"), "0.75");
			e.addValue(e, _("Many"), "0.5");
			e.addValue(e, _("Lots"), "0");
			e.configureNexuizTextSliderValues(e);
		entity gibs = e;
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Gibs count:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 100, 10, "cl_gibs_maxcount"));
		entity gibsMaxCount = e;
		makeCallback(gibs, gibsMaxCount, gibsUpdate);
		makeCallback(gibsMaxCount, gibs, gibsCountUpdate);
		gibsUpdate(gibsMaxCount, gibs);
		gibsCountUpdate(gibs, gibsMaxCount);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Casing count:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 100, 10, "cl_casings_maxcount"));
		makeCallback(e, NULL, casingsCountUpdate);
		casingsCountUpdate(NULL, e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_decals", _("Decals")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.3, e = makeNexuizTextLabel(0, _("Distance:")));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(200, 500, 20, "r_drawdecals_drawdistance"));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
	    me.TD(me, 1, 1.3, e = makeNexuizTextLabel(0, _("Time:")));
	        setDependent(e, "cl_decals", 1, 1);
	    me.TD(me, 1, 2, e = makeNexuizSlider(1, 20, 1, "cl_decals_time"));
	        setDependent(e, "cl_decals", 1, 1);

	me.gotoRC(me, 2, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TD(me, 1, 2, e = makeNexuizCheckBox(1, "mod_q3bsp_nolightmaps", _("Use lightmaps")));
	me.TD(me, 1, 1.9, e = makeNexuizCheckBox(0, "r_glsl_deluxemapping", _("Deluxe mapping")));
		setDependentAND(e, "r_glsl", 1, 1, "mod_q3bsp_nolightmaps", 0, 0);
	me.TD(me, 1, 0.7, e = makeNexuizCheckBox(0, "r_shadow_gloss", _("Gloss")));
		setDependentAND3(e, "r_glsl", 1, 1, "r_glsl_deluxemapping", 1, 2, "mod_q3bsp_nolightmaps", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizCheckBox(0, "r_glsl_offsetmapping", _("Offset mapping")));
			setDependent(e, "r_glsl", 1, 1);
		me.TD(me, 1, 1.9, e = makeNexuizCheckBox(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping")));
			setDependentAND(e, "r_glsl", 1, 1, "r_glsl_offsetmapping", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_water", _("Reflections:")));
			setDependent(e, "r_glsl", 1, 1);
		me.TD(me, 1, 2, e = makeNexuizTextSlider("r_water_resolutionmultiplier"));
			e.addValue(e, _("Blurred"), "0.25");
			e.addValue(e, _("Good"), "0.5");
			e.addValue(e, _("Sharp"), "1");
			e.configureNexuizTextSliderValues(e);
			setDependentAND(e, "r_glsl", 1, 1, "r_water", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "r_shadow_realtime_dlight", _("Realtime dynamic lighting")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_shadow_realtime_dlight_shadows", _("Shadows")));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "r_shadow_realtime_world", _("Realtime world lighting")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_shadow_realtime_world_shadows", _("Shadows")));
			setDependent(e, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeNexuizCheckBox(0, "r_shadow_usenormalmap", _("Use normal maps")));
			setDependentOR(e, "r_shadow_realtime_dlight", 1, 1, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_bloom", _("Bloom")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "r_coronas", _("Coronas")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_deformvertexes", _("Deform vertexes")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Motion blur:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.1, "r_motionblur"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Damage blur:")));
			setDependent(e, "r_motionblur", 0, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.1, "r_damageblur"));
			setDependent(e, "r_motionblur", 0, 1);
	
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "vid_conwidth $menu_vid_conwidth; vid_conheight $menu_vid_conheight; vid_restart", COMMANDBUTTON_APPLY));
}
#endif
