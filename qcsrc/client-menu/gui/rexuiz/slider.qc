void(entity me, float theValueMin, float theValueMax, float theValueStep, string theCvar) gui_rexuiz_slider_configure;
void(entity me, float val) gui_rexuiz_slider_set;
void(entity me) gui_rexuiz_slider_load;
void(entity me) gui_rexuiz_slider_save;

entity(void) gui_rexuiz_slider_spawn {
	entity me = gui_slider_spawn();
	me.configureNexuizSlider = gui_rexuiz_slider_configure;
	me.setValue = gui_rexuiz_slider_set;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.valueSpace = SKINWIDTH_SLIDERTEXT;
	me.image = SKINGFX_SLIDER;
	me.tolerance = SKINTOLERANCE_SLIDER;
	me.align = 0.5;
	me.color = SKINCOLOR_SLIDER_N;
	me.colorC = SKINCOLOR_SLIDER_C;
	me.colorF = SKINCOLOR_SLIDER_F;
	me.colorD = SKINCOLOR_SLIDER_D;
	me.color2 = SKINCOLOR_SLIDER_S;
	me.cvarName = NULL;
	me.loadCvars = gui_rexuiz_slider_load;
	me.saveCvars = gui_rexuiz_slider_save;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizSlider";
	return me;
}

entity(float theValueMin, float theValueMax, float theValueStep, string theCvar) gui_rexuiz_slider_make {
	entity me = gui_rexuiz_slider_spawn();
	me.configureNexuizSlider(me, theValueMin, theValueMax, theValueStep, theCvar);
	return me;
}

void(entity me, float theValueMin, float theValueMax, float theValueStep, string theCvar) gui_rexuiz_slider_configure {
	float v, vk, vp;
	v = theValueMin;
	vk = theValueStep;
	vp = theValueStep * 10;
	while (fabs(vp) < fabs(theValueMax - theValueMin) / 40)
		vp *= 10;

	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	me.configureSliderValues(me, theValueMin, v, theValueMax, theValueStep, vk, vp);
	if (theCvar) {
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
}

void(entity me, float val) gui_rexuiz_slider_set {
	if (val != me.value) {
		me.value = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_slider_load {
	if not(me.cvarName)
		return;

	me.value = cvar(me.cvarName);
}

void(entity me) gui_rexuiz_slider_save {
	if not(me.cvarName)
		return;

	cvar_set(me.cvarName, ftos(me.value));
}
