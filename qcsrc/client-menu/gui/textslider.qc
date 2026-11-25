void(entity me, string theDefault) gui_textslider_configure;
void(entity me, string theString, string theIdentifier) gui_textslider_value_add;
string(entity me) gui_textslider_identifier;
void(entity me, string id) gui_textslider_set;
string(entity me, float val) gui_textslider_value_text;
string(entity me, float val) gui_textslider_value_to_identifier;

entity(void) gui_textslider_spawn {
	entity me; me = gui_slider_spawn();
	me.valueToText = gui_textslider_value_text;
	me.valueToIdentifier = gui_textslider_value_to_identifier;
	me.setValueFromIdentifier = gui_textslider_set;
	me.getIdentifier = gui_textslider_identifier;
	me.addValue = gui_textslider_value_add;
	me.configureTextSliderValues = gui_textslider_configure;
	me.nValues = 0;
	me.classname = "TextSlider";
	return me;
}

string(entity me, float val) gui_textslider_value_to_identifier {
	if (val >= me.nValues)
		return _("custom");

	if (val < 0)
		return _("custom");

	return me.(valueIdentifiers[val]);
}

string(entity me, float val) gui_textslider_value_text {
	if (val >= me.nValues)
		return _("custom");

	if (val < 0)
		return _("custom");

	return me.(valueStrings[val]);
}

void(entity me, string id) gui_textslider_set {
	float i;
	for (i = 0; i < me.nValues; ++i)
		if (me.valueToIdentifier(me, i) == id) {
			me.value = i;
			return;
		}
	me.value = -1;
}

string(entity me) gui_textslider_identifier {
	return me.valueToIdentifier(me, me.value);
}

void(entity me, string theString, string theIdentifier) gui_textslider_value_add {
	me.(valueStrings[me.nValues]) = theString;
	me.(valueIdentifiers[me.nValues]) = theIdentifier;
	me.nValues += 1;
}

void(entity me, string theDefault) gui_textslider_configure {
	me.configureSliderValues(me, 0, 0, me.nValues - 1, 1, 1, 1);
	me.setValueFromIdentifier(me, theDefault);
}
