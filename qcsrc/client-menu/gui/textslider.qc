// Note:
//   to use this, you FIRST call configureSliderVisuals, then multiple times addValue, then configureTextSlider
entity(void) gui_textslider_spawn {
	entity me; me = gui_slider_spawn();
	me.valueToText = valueToTextTextSlider;
	me.valueToIdentifier = valueToIdentifierTextSlider;
	me.setValueFromIdentifier = setValueFromIdentifierTextSlider;
	me.getIdentifier = getIdentifierTextSlider;
	me.addValue = addValueTextSlider;
	me.configureTextSliderValues = configureTextSliderValuesTextSlider;
	me.nValues = 0;
	me.classname = "TextSlider";
	return me;
}
// Note:
//   to use this, you FIRST call configureSliderVisuals, then multiple times addValue, then configureTextSlider
string valueToIdentifierTextSlider(entity me, float val)
{
	if(val >= me.nValues)
		return _("custom");
	if(val < 0)
		return _("custom");
	return me.(valueIdentifiers[val]);
}
string valueToTextTextSlider(entity me, float val)
{
	if(val >= me.nValues)
		return _("custom");
	if(val < 0)
		return _("custom");
	return me.(valueStrings[val]);
}
void setValueFromIdentifierTextSlider(entity me, string id)
{
	float i;
	for(i = 0; i < me.nValues; ++i)
		if(me.valueToIdentifier(me, i) == id)
		{
			me.value = i;
			return;
		}
	me.value = -1;
}
string getIdentifierTextSlider(entity me)
{
	return me.valueToIdentifier(me, me.value);
}
void addValueTextSlider(entity me, string theString, string theIdentifier)
{
	me.(valueStrings[me.nValues]) = theString;
	me.(valueIdentifiers[me.nValues]) = theIdentifier;
	me.nValues += 1;
}
void configureTextSliderValuesTextSlider(entity me, string theDefault)
{
	me.configureSliderValues(me, 0, 0, me.nValues - 1, 1, 1, 1);
	me.setValueFromIdentifier(me, theDefault);
}
