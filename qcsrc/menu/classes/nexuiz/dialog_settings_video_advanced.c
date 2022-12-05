#ifdef INTERFACE
CLASS(NexuizVideoSettingsAdvancedTab) EXTENDS(NexuizTab)
	METHOD(NexuizVideoSettingsAdvancedTab, fill, void(entity))
	ATTRIB(NexuizVideoSettingsAdvancedTab, title, string, _("Advanced"))
	ATTRIB(NexuizVideoSettingsAdvancedTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizVideoSettingsAdvancedTab, rows, float, 20)
	ATTRIB(NexuizVideoSettingsAdvancedTab, columns, float, 6.5)
ENDCLASS(NexuizVideoSettingsAdvancedTab)
entity makeNexuizVideoSettingsAdvancedTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizVideoSettingsAdvancedTab()
{
	entity me;
	me = spawnNexuizVideoSettingsAdvancedTab();
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

void fillNexuizVideoSettingsAdvancedTab(entity me)
{
	entity e;
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
		gui_make_callback(gibs, gibsMaxCount, gibsUpdate);
		gui_make_callback(gibsMaxCount, gibs, gibsCountUpdate);
		gibsUpdate(gibsMaxCount, gibs);
		gibsCountUpdate(gibs, gibsMaxCount);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Casing count:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 100, 10, "cl_casings_maxcount"));
		gui_make_callback(e, NULL, casingsCountUpdate);
		casingsCountUpdate(NULL, e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizCheckBox(0, "cl_decals", _("Decals")));
		me.TD(me, 1, 2, e = makeNexuizSlider(64, 1024, 64, "cl_decals_max"));
			gui_set_dependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.3, e = makeNexuizTextLabel(0, _("Distance:")));
			gui_set_dependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(200, 500, 20, "r_drawdecals_drawdistance"));
			gui_set_dependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.3, e = makeNexuizTextLabel(0, _("Time:")));
			gui_set_dependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(1, 20, 1, "cl_decals_time"));
			gui_set_dependent(e, "cl_decals", 1, 1);

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TD(me, 1, 1, e = makeNexuizCheckBox(1, "mod_q3bsp_nolightmaps", _("Use lightmaps")));
	me.TD(me, 1, 1.8, e = makeNexuizCheckBox(0, "r_glsl_deluxemapping", _("Deluxe mapping")));
		gui_set_dependent(e, "mod_q3bsp_nolightmaps", 0, 0);
	me.TD(me, 1, 0.7, e = makeNexuizCheckBox(0, "r_shadow_gloss", _("Gloss")));
		gui_set_dependent_and(e, "r_glsl_deluxemapping", 1, 2, "mod_q3bsp_nolightmaps", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizCheckBox(0, "r_glsl_offsetmapping", _("Offset mapping")));
		me.TD(me, 1, 1.5, e = makeNexuizCheckBox(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping")));
			gui_set_dependent(e, "r_glsl_offsetmapping", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_bloom", _("Bloom")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_coronas", _("Coronas")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_deformvertexes", _("Deform vertexes")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_sky", _("Sky")));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Texture compression")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "0", _("None")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "1", _("Fast")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "2", _("Good")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "v_glslgamma", _("Use GLSL to handle color control")));
	me.TR(me);
		if(cvar_type("apple_multithreadedgl") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(1, "apple_multithreadedgl", _("Disable multithreaded OpenGL")));
}
#endif
