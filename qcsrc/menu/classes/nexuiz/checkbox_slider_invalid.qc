entity spawnNexuizSliderCheckBox() {
	entity me; me = spawnCheckBox();
	me.configureNexuizSliderCheckBox = configureNexuizSliderCheckBoxNexuizSliderCheckBox;
	me.setChecked = setCheckedNexuizSliderCheckBox;
	me.draw = drawNexuizSliderCheckBox;
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
entity makeNexuizSliderCheckBox(float, float, entity, string);
entity makeNexuizSliderCheckBox(float theOffValue, float isInverted, entity theControlledSlider, string theText)
{
	entity me;
	me = spawnNexuizSliderCheckBox();
	me.configureNexuizSliderCheckBox(me, theOffValue, isInverted, theControlledSlider, theText);
	return me;
}
void configureNexuizSliderCheckBoxNexuizSliderCheckBox(entity me, float theOffValue, float isInverted, entity theControlledSlider, string theText)
{
	me.offValue = theOffValue;
	me.inverted = isInverted;
	me.checked = (theControlledSlider.value == theOffValue);
	if(theControlledSlider.value == medianSlider(theControlledSlider.valueMin, theControlledSlider.value, theControlledSlider.valueMax))
		me.savedValue = theControlledSlider.value;
	else
		me.savedValue = theControlledSlider.valueMin;
	me.controlledSlider = theControlledSlider;
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void drawNexuizSliderCheckBox(entity me)
{
	me.checked = ((me.controlledSlider.value == me.offValue) != me.inverted);
	if(me.controlledSlider.value == medianSlider(me.controlledSlider.valueMin, me.controlledSlider.value, me.controlledSlider.valueMax))
		me.savedValue = me.controlledSlider.value;
	drawCheckBox(me);
}
void setCheckedNexuizSliderCheckBox(entity me, float val)
{
	if(me.checked == val)
		return;
	me.checked = val;
	if(val == me.inverted)
		me.controlledSlider.setValue(me.controlledSlider, medianSlider(me.controlledSlider.valueMin, me.savedValue, me.controlledSlider.valueMax));
	else
		me.controlledSlider.setValue(me.controlledSlider, me.offValue);
}
