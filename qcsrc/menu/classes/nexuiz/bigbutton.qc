entity spawnNexuizBigButton() {
	entity me; me = spawnNexuizButton();
	me.configureNexuizBigButton = configureNexuizBigButtonNexuizBigButton;
	me.image = SKINGFX_BUTTON_BIG;
	me.grayImage = SKINGFX_BUTTON_BIG_GRAY;
	me.classname = "NexuizButton";
	return me;
}
entity makeNexuizButton(string theText, vector theColor);
entity makeNexuizBigButton(string theText, vector theColor)
{
	entity me;
	me = spawnNexuizBigButton();
	me.configureNexuizBigButton(me, theText, theColor);
	return me;
}
void configureNexuizBigButtonNexuizBigButton(entity me, string theText, vector theColor)
{
	me.configureNexuizButton(me, theText, theColor);
}
