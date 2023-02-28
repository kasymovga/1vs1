#ifdef INTERFACE
CLASS(NexuizVideoSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizVideoSettingsTab, fill, void(entity))
	ATTRIB(NexuizVideoSettingsTab, title, string, _("Video"))
	ATTRIB(NexuizVideoSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizVideoSettingsTab, rows, float, 22)
	ATTRIB(NexuizVideoSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizVideoSettingsTab)
entity makeNexuizVideoSettingsTab();
#endif

#ifdef IMPLEMENTATION
void(entity btn, entity me) lowNexuizVideoSettingsTab {
	cvar_set("cl_decals", "1");
	cvar_set("cl_decals_time", "2");
	cvar_set("cl_particles_quality", "0.1");
	cvar_set("cl_nogibs", "1");
	cvar_set("cl_gibs_maxcount", "0");
	cvar_set("cl_casings", "0");
	cvar_set("cl_casings_maxcount", "0");
	cvar_set("gl_flashblend", "0");
	cvar_set("gl_picmip", "2");
	cvar_set("gl_texture_anisotropy", "1");
	cvar_set("mod_q3bsp_nolightmaps", "1");
	cvar_set("r_bloom", "0");
	cvar_set("r_coronas", "0");
	cvar_set("r_damageblur", "0");
	cvar_set("r_drawdecals_drawdistance", "200");
	cvar_set("r_drawparticles_drawdistance", "500");
	cvar_set("r_glsl_deluxemapping", "0");
	cvar_set("r_glsl_offsetmapping", "0");
	cvar_set("r_glsl_offsetmapping_reliefmapping", "0");
	cvar_set("r_hdr_irisadaptation", "0");
	cvar_set("r_motionblur", "0");
	cvar_set("r_picmipworld", "1");
	cvar_set("r_shadow_gloss", "0");
	cvar_set("r_shadow_realtime_dlight", "0");
	cvar_set("r_shadow_realtime_dlight_shadows", "0");
	cvar_set("r_shadow_realtime_world", "0");
	cvar_set("r_shadow_realtime_world_shadows", "0");
	cvar_set("r_shadow_realtime_world_lightmaps", "0.75");
	cvar_set("r_shadow_usenormalmap", "0");
	cvar_set("r_showsurfaces", "0");
	cvar_set("r_subdivisions_tolerance", "8");
	cvar_set("r_water", "0");
	cvar_set("r_water_resolutionmultiplier", "0.5");
	cvar_set("vid_samples", "1");
	cvar_set("r_fxaa", "0");
	//r_viewscale 1
	cvar_set("r_glsl_postprocess", "0");
	cvar_set("r_glsl_saturation", "1");
	cvar_set("v_glslgamma", "0");
	cvar_set("r_deformvertexes", "0");
	cvar_set("cl_decals_max", "64");
	gui_load_all_cvars(main);
}

void(entity btn, entity me) mediumNexuizVideoSettingsTab {
	cvar_set("cl_decals", "1");
	cvar_set("cl_decals_time", "2");
	cvar_set("cl_particles_quality", "0.25");
	cvar_set("cl_nogibs", "0.5");
	cvar_set("cl_gibs_maxcount", "10");
	cvar_set("cl_casings", "1");
	cvar_set("cl_casings_maxcount", "10");
	cvar_set("gl_flashblend", "0");
	cvar_set("gl_picmip", "0");
	cvar_set("gl_texture_anisotropy", "1");
	cvar_set("mod_q3bsp_nolightmaps", "0");
	cvar_set("r_bloom", "0");
	cvar_set("r_coronas", "0");
	cvar_set("r_damageblur", "0");
	cvar_set("r_drawdecals_drawdistance", "300");
	cvar_set("r_drawparticles_drawdistance", "1000");
	cvar_set("r_glsl_deluxemapping", "0");
	cvar_set("r_glsl_offsetmapping", "0");
	cvar_set("r_glsl_offsetmapping_reliefmapping", "0");
	cvar_set("r_hdr_irisadaptation", "0");
	cvar_set("r_motionblur", "0");
	cvar_set("r_picmipworld", "1");
	cvar_set("r_shadow_gloss", "0");
	cvar_set("r_shadow_realtime_dlight", "1");
	cvar_set("r_shadow_realtime_dlight_shadows", "0");
	cvar_set("r_shadow_realtime_world", "0");
	cvar_set("r_shadow_realtime_world_shadows", "0");
	cvar_set("r_shadow_realtime_world_lightmaps", "0.75");
	cvar_set("r_shadow_usenormalmap", "0");
	cvar_set("r_showsurfaces", "0");
	cvar_set("r_subdivisions_tolerance", "4");
	cvar_set("r_water", "0");
	cvar_set("r_water_resolutionmultiplier", "0.5");
	cvar_set("vid_samples", "1");
	cvar_set("r_fxaa", "0");
	//r_viewscale 1
	cvar_set("r_glsl_postprocess", "0");
	cvar_set("r_glsl_saturation", "1");
	cvar_set("v_glslgamma", "0");
	cvar_set("r_deformvertexes", "1");
	cvar_set("cl_decals_max", "128");
	gui_load_all_cvars(main);
}

void(entity btn, entity me) normalNexuizVideoSettingsTab {
	cvar_set("cl_decals", "1");
	cvar_set("cl_decals_time", "2");
	cvar_set("cl_particles_quality", "0.5");
	cvar_set("cl_nogibs", "0.75");
	cvar_set("cl_gibs_maxcount", "30");
	cvar_set("cl_casings", "1");
	cvar_set("cl_casings_maxcount", "30");
	cvar_set("gl_flashblend", "0");
	cvar_set("gl_picmip", "0");
	cvar_set("gl_texture_anisotropy", "1");
	cvar_set("mod_q3bsp_nolightmaps", "0");
	cvar_set("r_bloom", "0");
	cvar_set("r_coronas", "0");
	cvar_set("r_damageblur", "0");
	cvar_set("r_drawdecals_drawdistance", "300");
	cvar_set("r_drawparticles_drawdistance", "1000");
	cvar_set("r_glsl_deluxemapping", "1");
	cvar_set("r_glsl_offsetmapping", "0");
	cvar_set("r_glsl_offsetmapping_reliefmapping", "0");
	cvar_set("r_hdr_irisadaptation", "0");
	cvar_set("r_motionblur", "0");
	cvar_set("r_picmipworld", "1");
	cvar_set("r_shadow_gloss", "1");
	cvar_set("r_shadow_realtime_dlight", "1");
	cvar_set("r_shadow_realtime_dlight_shadows", "0");
	cvar_set("r_shadow_realtime_world", "0");
	cvar_set("r_shadow_realtime_world_shadows", "0");
	cvar_set("r_shadow_realtime_world_lightmaps", "0.75");
	cvar_set("r_shadow_usenormalmap", "1");
	cvar_set("r_showsurfaces", "0");
	cvar_set("r_subdivisions_tolerance", "3");
	cvar_set("r_water", "0");
	cvar_set("r_water_resolutionmultiplier", "0.5");
	cvar_set("vid_samples", "1");
	cvar_set("r_fxaa", "0");
	//r_viewscale 1
	cvar_set("r_glsl_postprocess", "0");
	cvar_set("r_glsl_saturation", "1");
	cvar_set("v_glslgamma", "0");
	cvar_set("r_deformvertexes", "1");
	cvar_set("cl_decals_max", "192");
	gui_load_all_cvars(main);
}

void(entity btn, entity me) highNexuizVideoSettingsTab {
	cvar_set("cl_decals", "1");
	cvar_set("cl_decals_time", "4");
	cvar_set("cl_particles_quality", "0.75");
	cvar_set("cl_nogibs", "0.5");
	cvar_set("cl_gibs_maxcount", "50");
	cvar_set("cl_casings", "1");
	cvar_set("cl_casings_maxcount", "50");
	cvar_set("gl_flashblend", "0");
	cvar_set("gl_picmip", "0");
	cvar_set("gl_texture_anisotropy", "16");
	cvar_set("mod_q3bsp_nolightmaps", "0");
	cvar_set("r_bloom", "1");
	cvar_set("r_coronas", "0");
	cvar_set("r_damageblur", "0.3");
	cvar_set("r_drawdecals_drawdistance", "500");
	cvar_set("r_drawparticles_drawdistance", "2000");
	cvar_set("r_glsl_deluxemapping", "1");
	cvar_set("r_glsl_offsetmapping", "1");
	cvar_set("r_glsl_offsetmapping_reliefmapping", "0");
	cvar_set("r_hdr_irisadaptation", "0");
	cvar_set("r_motionblur", "0.4");
	cvar_set("r_picmipworld", "1");
	cvar_set("r_shadow_gloss", "1");
	cvar_set("r_shadow_realtime_dlight", "1");
	cvar_set("r_shadow_realtime_dlight_shadows", "0");
	cvar_set("r_shadow_realtime_world", "0");
	cvar_set("r_shadow_realtime_world_shadows", "0");
	cvar_set("r_shadow_realtime_world_lightmaps", "0.75");
	cvar_set("r_shadow_usenormalmap", "1");
	cvar_set("r_showsurfaces", "0");
	cvar_set("r_subdivisions_tolerance", "3");
	cvar_set("r_water", "1");
	cvar_set("r_water_resolutionmultiplier", "0.5");
	cvar_set("vid_samples", "1");
	cvar_set("r_fxaa", "1");
	//r_viewscale 1
	cvar_set("r_glsl_postprocess", "0");
	//r_glsl_saturation 1
	cvar_set("v_glslgamma", "1");
	cvar_set("r_deformvertexes", "1");
	cvar_set("cl_decals_max", "256");
	gui_load_all_cvars(main);
}

void(entity btn, entity me) ultraNexuizVideoSettingsTab {
	cvar_set("cl_decals", "1");
	cvar_set("cl_decals_time", "10");
	cvar_set("cl_particles_quality", "1");
	cvar_set("cl_nogibs", "0");
	cvar_set("cl_gibs_maxcount", "100");
	cvar_set("cl_casings", "1");
	cvar_set("cl_casings_maxcount", "100");
	cvar_set("gl_flashblend", "0");
	cvar_set("gl_picmip", "0");
	cvar_set("gl_texture_anisotropy", "16");
	cvar_set("mod_q3bsp_nolightmaps", "0");
	cvar_set("r_bloom", "1");
	cvar_set("r_coronas", "0");
	cvar_set("r_damageblur", "0.3");
	cvar_set("r_drawdecals_drawdistance", "500");
	cvar_set("r_drawparticles_drawdistance", "2000");
	cvar_set("r_glsl_deluxemapping", "1");
	cvar_set("r_glsl_offsetmapping", "1");
	cvar_set("r_glsl_offsetmapping_reliefmapping", "0");
	cvar_set("r_hdr_irisadaptation", "0");
	cvar_set("r_motionblur", "0.4");
	cvar_set("r_picmipworld", "1");
	cvar_set("r_shadow_gloss", "1");
	cvar_set("r_shadow_realtime_dlight", "1");
	cvar_set("r_shadow_realtime_dlight_shadows", "1");
	cvar_set("r_shadow_realtime_world", "1");
	cvar_set("r_shadow_realtime_world_shadows", "1");
	cvar_set("r_shadow_realtime_world_lightmaps", "0.75");
	cvar_set("r_shadow_usenormalmap", "1");
	cvar_set("r_showsurfaces", "0");
	cvar_set("r_subdivisions_tolerance", "2");
	cvar_set("r_water", "1");
	cvar_set("r_water_resolutionmultiplier", "0.5");
	cvar_set("vid_samples", "4");
	cvar_set("r_fxaa", "0");
	cvar_set("r_viewscale", "1");
	cvar_set("r_glsl_postprocess", "0");
	//r_glsl_saturation 1
	cvar_set("v_glslgamma", "1");
	cvar_set("r_deformvertexes", "1");
	cvar_set("cl_decals_max", "512");
	gui_load_all_cvars(main);
}

entity makeNexuizVideoSettingsTab()
{
	entity me;
	me = spawnNexuizVideoSettingsTab();
	me.configureDialog(me);
	return me;
}
void fillNexuizVideoSettingsTab(entity me)
{
	entity e;
	entity mc;
	float n;
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Quality preset:")));
		n = 5;
		me.TD(me, 1, 5.3 / n, e = makeNexuizButton(_("Low"), '0 0 0'));
			e.onClick = lowNexuizVideoSettingsTab;
		me.TD(me, 1, 5.3 / n, e = makeNexuizButton(_("Medium"), '0 0 0'));
			e.onClick = mediumNexuizVideoSettingsTab;
		me.TD(me, 1, 5.3 / n, e = makeNexuizButton(_("Normal"), '0 0 0'));
			e.onClick = normalNexuizVideoSettingsTab;
		me.TD(me, 1, 5.3 / n, e = makeNexuizButton(_("High"), '0 0 0'));
			e.onClick = highNexuizVideoSettingsTab;
		me.TD(me, 1, 5.3 / n, e = makeNexuizButton(_("Ultra"), '0 0 0'));
			e.onClick = ultraNexuizVideoSettingsTab;
	me.TR(me);
		mc = makeNexuizTabController(me.rows - 2);
		me.TD(me, 1, 3.25, e = mc.makeTabButton(mc, _("Basic"),  makeNexuizVideoSettingsBasicTab()));
		me.TD(me, 1, 3.25, mc.makeTabButton(mc, _("Advanced"),   makeNexuizVideoSettingsAdvancedTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 3, me.columns, mc);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "vid_restart; menu_cmd ui_con_width_height_set;saveconfig\n", COMMANDBUTTON_APPLY));
}
#endif
