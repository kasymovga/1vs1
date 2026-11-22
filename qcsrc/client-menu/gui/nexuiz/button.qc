entity spawnNexuizButton() {
	entity me; me = gui_button_spawn();
	me.configureNexuizButton = configureNexuizButtonNexuizButton;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_BUTTON;
	me.grayImage = SKINGFX_BUTTON_GRAY;
	me.color = SKINCOLOR_BUTTON_N;
	me.colorC = SKINCOLOR_BUTTON_C;
	me.colorF = SKINCOLOR_BUTTON_F;
	me.colorD = SKINCOLOR_BUTTON_D;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizButton";
	return me;
}
entity makeNexuizButton(string theText, vector theColor);
entity makeNexuizButton(string theText, vector theColor)
{
	entity me;
	me = spawnNexuizButton();
	me.configureNexuizButton(me, theText, theColor);
	return me;
}
void configureNexuizButtonNexuizButton(entity me, string theText, vector theColor)
{
	if(theColor == '0 0 0')
	{
		me.configureButton(me, theText, me.fontSize, me.image);
	}
	else
	{
		me.configureButton(me, theText, me.fontSize, me.grayImage);
		me.color = theColor;
		me.colorC = theColor;
		me.colorF = theColor;
	}
}
