#ifdef INTERFACE
CLASS(NexuizVideoSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizVideoSettingsTab, fill, void(entity))
	ATTRIB(NexuizVideoSettingsTab, title, string, _("Video"))
	ATTRIB(NexuizVideoSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizVideoSettingsTab, rows, float, 17)
	ATTRIB(NexuizVideoSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizVideoSettingsTab)
entity makeNexuizVideoSettingsTab();
#endif

#ifdef IMPLEMENTATION
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

	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "vid_fullscreen", _("Full screen")));
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "vid_desktopfullscreen", _("Desktop resolution")));
		setDependent(e, "vid_fullscreen", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Resolution:")));
		me.TD(me, 1, 2, e = makeNexuizResolutionSlider());
		setDependentOR(e, "vid_fullscreen", 0, 0, "vid_desktopfullscreen", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Color depth:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(16, 32, 16, "vid_bitsperpixel"));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Texture compression")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "0", _("None")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "1", _("Fast")));
		me.TD(me, 1, 0.5, e = makeNexuizRadioButton(2, "gl_texturecompression", "2", _("Good")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "vid_vsync", _("Vertical Synchronization")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_glsl", _("Use OpenGL 2.0 shaders (GLSL)")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "r_coronas_occlusionquery", _("Use Occlusion Queries")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Vertex Buffer Objects (VBOs)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeNexuizRadioButton(1, "gl_vbo", "0", _("Off")));
		me.TD(me, 1, 2.1, e = makeNexuizRadioButton(1, "gl_vbo", "3", _("Vertices, some Tris (compatible)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeNexuizRadioButton(1, "gl_vbo", "2", _("Vertices")));
		me.TD(me, 1, 2.1, e = makeNexuizRadioButton(1, "gl_vbo", "1", _("Vertices and Triangles")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Depth first:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("r_depthfirst"));
			e.addValue(e, _("Disabled"), "0");
			e.addValue(e, _("World"), "1");
			e.addValue(e, _("All"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		if(cvar_type("apple_multithreadedgl") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(1, "apple_multithreadedgl", _("Disable multithreaded OpenGL")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "gl_finish", _("Wait for GPU to finish each frame")));

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
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
			setDependent(e, "r_glsl", 1, 1);
		me.TD(me, 1, 2, e = makeNexuizSlider(0.5, 2.0, 0.05, "r_glsl_saturation"));
			setDependent(e, "r_glsl", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "v_glslgamma", _("Use GLSL to handle color control")));
			setDependent(e, "r_glsl", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Ambient light:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 20.0, 1.0, "r_ambient"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Intensity:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.5, 2.0, 0.05, "r_hdr_scenebrightness"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Max FPS:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("cl_maxfps"));
			e.addValue(e, "125", "125");
			e.addValue(e, "250", "250");
			e.addValue(e, "500", "500");
			e.addValue(e, _("Unlimited"), "0");
			e.configureNexuizTextSliderValues(e);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "vid_conwidth $menu_vid_conwidth; vid_conheight $menu_vid_conheight; vid_restart", COMMANDBUTTON_APPLY));
}
#endif
