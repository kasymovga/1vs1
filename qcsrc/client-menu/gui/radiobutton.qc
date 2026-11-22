void RadioButton_Click(entity me, entity theOther);
entity spawnRadioButton() {
	entity me; me = spawnCheckBox();
	me.configureRadioButton = configureRadioButtonRadioButton;
	me.checked = 0;
	me.group = 0;
	me.allowDeselect = 0;
	me.onClick = RadioButton_Click;
	me.classname = "RadioButton";
	return me;
}
void configureRadioButtonRadioButton(entity me, string txt, float sz, string gfx, float theGroup, float doAllowDeselect)
{
	me.configureCheckBox(me, txt, sz, gfx);
	me.align = 0;
	me.group = theGroup;
	me.allowDeselect = doAllowDeselect;
}
void RadioButton_Click(entity me, entity theOther)
{
	if(me.checked)
	{
		if(me.allowDeselect)
			me.setChecked(me, 0);
	}
	else
	{
		entity e;
		for(e = me.parent.firstChild; e; e = e.nextSibling)
			if(e != me)
				if(e.group == me.group)
					e.setChecked(e, 0);
		me.setChecked(me, 1);
	}
}
