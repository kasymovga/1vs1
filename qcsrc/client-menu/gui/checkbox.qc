void CheckBox_Click(entity me, entity thOther);
entity spawnCheckBox() {
	entity me; me = spawnButton();
	me.configureCheckBox = configureCheckBoxCheckBox;
	me.draw = drawCheckBox;
	me.toString = toStringCheckBox;
	me.setChecked = setCheckedCheckBox;
	me.useDownAsChecked = 0;
	me.checked = 0;
	me.onClick = CheckBox_Click;
	me.srcMulti = 0;
	me.disabled = 0;
	me.classname = "CheckBox";
	return me;
}
void setCheckedCheckBox(entity me, float val)
{
	me.checked = val;
}
void CheckBox_Click(entity me, entity thOther)
{
	me.setChecked(me, !me.checked);
}
string toStringCheckBox(entity me)
{
	return strcat(toStringLabel(me), ", ", me.checked ? "checked" : "unchecked");
}
void configureCheckBoxCheckBox(entity me, string txt, float sz, string gfx)
{
	me.configureButton(me, txt, sz, gfx);
	me.align = 0;
}
void drawCheckBox(entity me)
{
	float s;
	s = me.pressed;
	if(me.useDownAsChecked)
	{
		me.srcSuffix = NULL;
		me.forcePressed = me.checked;
	}
	else
		me.srcSuffix = (me.checked ? "1" : "0");
	drawButton(me);
	me.pressed = s;
}
