void(entity me, string theCvar) gui_rexuiz_textslider_configure;
void(entity me, float val) gui_rexuiz_textslider_set;
void(entity me) gui_rexuiz_textslider_load;
void(entity me) gui_rexuiz_textslider_values_configure;

entity(void) gui_rexuiz_textslider_spawn {
	entity me = gui_textslider_spawn();
	me.configureNexuizTextSlider = gui_rexuiz_textslider_configure;
	me.setValue = gui_rexuiz_textslider_set;
	me.configureNexuizTextSliderValues = gui_rexuiz_textslider_values_configure;
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
	me.loadCvars = gui_rexuiz_textslider_load;
	me.saveCvars = gui_rexuiz_textslider_save;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizTextSlider";
	return me;
}

entity(string theCvar) gui_rexuiz_textslider_make {
	entity me;
	me = gui_rexuiz_textslider_spawn();
	me.configureNexuizTextSlider(me, theCvar);
	return me;
}

void(entity me, string theCvar) gui_rexuiz_textslider_configure {
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	if (theCvar) {
		me.cvarName = theCvar;
		// don't load it yet
	}
}

void(entity me, float val) gui_rexuiz_textslider_set {
	if (val != me.value) {
		me.value = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_textslider_load {
	if not(me.cvarName)
		return;

	me.setValueFromIdentifier(me, cvar_string(me.cvarName));
}

void(entity me) gui_rexuiz_textslider_save {
	if not(me.cvarName)
		return;

	if (me.value >= 0 && me.value < me.nValues)
		cvar_set(me.cvarName, me.getIdentifier(me));
}

void(entity me) gui_rexuiz_textslider_values_configure {
	me.configureTextSliderValues(me, NULL);
	me.loadCvars(me);
}
