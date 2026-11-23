void(entity me, float theOffValue, float isInverted, entity theControlledSlider, string theText) gui_rexuiz_checkbox_slider_configure;
void(entity me) gui_rexuiz_checkbox_slider_draw;
void(entity me, float val) gui_rexuiz_checkbox_slider_set;

entity(void) gui_rexuiz_checkbox_slider_spawn {
	entity me = gui_checkbox_spawn();
	me.configureNexuizSliderCheckBox = gui_rexuiz_checkbox_slider_configure;
	me.setChecked = gui_rexuiz_checkbox_slider_set;
	me.draw = gui_rexuiz_checkbox_slider_draw;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_CHECKBOX;
	me.color = SKINCOLOR_CHECKBOX_N;
	me.colorC = SKINCOLOR_CHECKBOX_C;
	me.colorF = SKINCOLOR_CHECKBOX_F;
	me.colorD = SKINCOLOR_CHECKBOX_D;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.controlledSlider = NULL;
	me.offValue = -1;
	me.inverted = 0;
	me.savedValue = -1;
	me.classname = "NexuizSliderCheckBox";
	return me;
}

entity(float theOffValue, float isInverted, entity theControlledSlider, string theText) gui_rexuiz_checkbox_slider_make {
	entity me;
	me = gui_rexuiz_checkbox_slider_spawn();
	me.configureNexuizSliderCheckBox(me, theOffValue, isInverted, theControlledSlider, theText);
	return me;
}

void(entity me, float theOffValue, float isInverted, entity theControlledSlider, string theText) gui_rexuiz_checkbox_slider_configure {
	me.offValue = theOffValue;
	me.inverted = isInverted;
	me.checked = (theControlledSlider.value == theOffValue);
	if (theControlledSlider.value == gui_slider_median(theControlledSlider.valueMin, theControlledSlider.value, theControlledSlider.valueMax))
		me.savedValue = theControlledSlider.value;
	else
		me.savedValue = theControlledSlider.valueMin;

	me.controlledSlider = theControlledSlider;
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}

void(entity me) gui_rexuiz_checkbox_slider_draw {
	me.checked = ((me.controlledSlider.value == me.offValue) != me.inverted);
	if (me.controlledSlider.value == gui_slider_median(me.controlledSlider.valueMin, me.controlledSlider.value, me.controlledSlider.valueMax))
		me.savedValue = me.controlledSlider.value;

	drawCheckBox(me);
}

void(entity me, float val) gui_rexuiz_checkbox_slider_set {
	if (me.checked == val)
		return;

	me.checked = val;
	if (val == me.inverted)
		me.controlledSlider.setValue(me.controlledSlider, gui_slider_median(me.controlledSlider.valueMin, me.savedValue, me.controlledSlider.valueMax));
	else
		me.controlledSlider.setValue(me.controlledSlider, me.offValue);
}
