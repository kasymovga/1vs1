entity spawnNexuizBigCommandButton() {
	entity me; me = spawnNexuizCommandButton();
	me.configureNexuizBigCommandButton = configureNexuizBigCommandButtonNexuizBigCommandButton;
	me.image = SKINGFX_BUTTON_BIG;
	me.grayImage = SKINGFX_BUTTON_BIG_GRAY;
	me.classname = "NexuizCommandButton";
	return me;
}
entity makeNexuizBigCommandButton(string theText, vector theColor, string theCommand, float closesMenu);
entity makeNexuizBigCommandButton(string theText, vector theColor, string theCommand, float theFlags)
{
	entity me;
	me = spawnNexuizBigCommandButton();
	me.configureNexuizBigCommandButton(me, theText, theColor, theCommand, theFlags);
	return me;
}
void configureNexuizBigCommandButtonNexuizBigCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags)
{
	me.configureNexuizCommandButton(me, theText, theColor, theCommand, theFlags);
}
