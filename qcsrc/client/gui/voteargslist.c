#ifdef INTERFACE
CLASS(NexuizVoteArgsList) EXTENDS(NexuizListBox)
	METHOD(NexuizVoteArgsList, configureNexuizVoteArgsList, void(entity))
	METHOD(NexuizVoteArgsList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizVoteArgsList, setSelected, void(entity, float))
	METHOD(NexuizVoteArgsList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizVoteArgsList, setVoteType, void(entity, string))
	ATTRIB(NexuizVoteArgsList, voteType, float, 0)
	ATTRIB(NexuizVoteArgsList, textBox, entity, NULL)
	ATTRIB(NexuizVoteArgsList, realUpperMargin, float, 0)
	ATTRIB(NexuizVoteArgsList, columnNameOrigin, float, 0)
	ATTRIB(NexuizVoteArgsList, voteList, entity, NULL)
ENDCLASS(NexuizVoteArgsList)
entity makeNexuizVoteArgsList();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizVoteArgsList(void)
{
	entity me;
	me = spawnNexuizVoteArgsList();
	me.configureNexuizVoteArgsList(me);
	me.nItems = 0;
	return me;
}

void configureNexuizVoteArgsListNexuizVoteArgsList(entity me)
{
	me.configureNexuizListBox(me);
}

void setVoteTypeNexuizVoteArgsList(entity me, string vote) {
	me.nItems = 0;
	if (vote == "kick" ||
			vote == "kickban") {
		me.voteType = 1;
		me.nItems = 255;
	} else if (vote == "movetoteam_auto" ||
			vote == "movetoteam_blue" ||
			vote == "movetoteam_red" ||
			vote == "movetoteam_yellow" ||
			vote == "movetoteam_ping" ||
			vote == "mute") {
		me.voteType = 2;
		me.nItems = 255;
	} else {
		me.voteType = 0;
	}

}

void setSelectedNexuizVoteArgsList(entity me, float i)
{
	setSelectedListBox(me, i);
	if (i >= me.nItems)
		return;

	if (me.voteType == 1 || me.voteType == 2) {
		entity e = playerslots[i];
		if (e) {
			string vote = vote_commands[me.voteList.selectedItem];
			string s;
			if (me.voteType == 1)
				s = strcat(vote, " # ", ftos(e.sv_entnum + 1));
			else
				s = strcat(vote, " ", ftos(e.sv_entnum + 1));

			s = strcat(s, " reason");
			me.voteList.textBox.setText(me.voteList.textBox, s);
			me.voteList.textBox.cursorPos = strlen(s);
		}
	}
}

void resizeNotifyNexuizVoteArgsList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemNexuizVoteArgsList(entity me, float i, vector absSize, float isSelected)
{
	if (me.voteType == 1 || me.voteType == 2) {
		string s;
		if(isSelected)
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

		entity  e = playerslots[i];
		if (e)
			s = strcat("#", ftos(e.sv_entnum + 1), ": ", strdecolorize(GetPlayerName(e.sv_entnum)));

		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	}
}

#endif
