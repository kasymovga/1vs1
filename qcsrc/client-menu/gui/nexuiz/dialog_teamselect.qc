entity spawnNexuizTeamSelectDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizTeamSelectDialog; // to be overridden by user to fill the dialog with controls
	me.showNotify = showNotifyNexuizTeamSelectDialog;
	me.title = _("Team Selection"); // ;)
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.4;
	me.rows = 6;
	me.columns = 4;
	me.name = "TeamSelect";
	me.team1 = NULL;
	me.team2 = NULL;
	me.team3 = NULL;
	me.team4 = NULL;
	me.classname = "NexuizTeamSelectDialog";
	return me;
}
/* Click. The c-word is here so you can grep for it :-) */
entity makeTeamButton(string theName, vector theColor, string commandtheName)
{
	entity b;
	b = makeNexuizBigCommandButton(theName, theColor, commandtheName, 1);
	return b;
}
void showNotifyNexuizTeamSelectDialog(entity me)
{
	float theTeams, nTeams;
	theTeams = cvar("_teams_available");
	nTeams = 0;
	me.team1.disabled = !(theTeams & 1); nTeams += !!(theTeams & 1);
	me.team2.disabled = !(theTeams & 2); nTeams += !!(theTeams & 2);
	me.team3.disabled = !(theTeams & 4); nTeams += !!(theTeams & 4);
	me.team4.disabled = !(theTeams & 8); nTeams += !!(theTeams & 8);
}
void fillNexuizTeamSelectDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1.5, 4, e = makeTeamButton(_("join 'best' team (auto-select)"), '0 0 0', "cmd selectteam auto; cmd join"));
			e.preferredFocusPriority = 1;
	me.gotoRC(me, 1.5, 0);
		me.TD(me, 1.5, 2, me.team1 = makeTeamButton(_("Red Team"), '1 0.5 0.5', "cmd selectteam red; cmd join"));
		me.TD(me, 1.5, 2, me.team2 = makeTeamButton(_("Blue Team"), '0.5 0.5 1', "cmd selectteam blue; cmd join"));
	me.gotoRC(me, 3, 0);
		me.TD(me, 1.5, 2, me.team3 = makeTeamButton(_("Yellow Team"), '1 1 0.5', "cmd selectteam yellow; cmd join"));
		me.TD(me, 1.5, 2, me.team4 = makeTeamButton(_("Pink Team"), '1 0.5 1', "cmd selectteam pink; cmd join"));
	me.gotoRC(me, 4.5, 0);
		me.TD(me, 1.5, 4, makeNexuizCommandButton(_("spectate"), '0 0 0', "cmd spectate", 1));
}
/* Click. The c-word is here so you can grep for it :-) */
