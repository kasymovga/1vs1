entity(void) gui_rexuiz_textslider_spawn {
	entity me = gui_textslider_spawn();
	me.configureNexuizTextSlider = configureNexuizTextSliderNexuizTextSlider;
	me.setValue = setValueNexuizTextSlider;
	me.configureNexuizTextSliderValues = configureNexuizTextSliderValuesNexuizTextSlider;
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
	me.loadCvars = loadCvarsNexuizTextSlider;
	me.saveCvars = saveCvarsNexuizTextSlider;
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
void configureNexuizTextSliderNexuizTextSlider(entity me, string theCvar)
{
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	if(theCvar)
	{
		me.cvarName = theCvar;
		// don't load it yet
	}
}
void setValueNexuizTextSlider(entity me, float val)
{
	if(val != me.value)
	{
		me.value = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizTextSlider(entity me)
{
	if not(me.cvarName)
		return;
	me.setValueFromIdentifier(me, cvar_string(me.cvarName));
}
void saveCvarsNexuizTextSlider(entity me)
{
	if not(me.cvarName)
		return;
	if(me.value >= 0 && me.value < me.nValues)
		cvar_set(me.cvarName, me.getIdentifier(me));
}
void configureNexuizTextSliderValuesNexuizTextSlider(entity me)
{
	me.configureTextSliderValues(me, NULL);
	me.loadCvars(me);
}
