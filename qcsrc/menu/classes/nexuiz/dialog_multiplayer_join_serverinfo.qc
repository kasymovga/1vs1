entity spawnNexuizServerInfoDialog() {
	entity me; me = spawnNexuizDialog();
	me.fill = fillNexuizServerInfoDialog;
	me.loadServerInfo = loadServerInfoNexuizServerInfoDialog;
	me.title = _("Server Information");
	me.color = SKINCOLOR_DIALOG_SERVERINFO;
	me.intendedWidth = 0.68;
	me.rows = 11;
	me.columns = 12;
	me.currentServerName = NULL;
	me.currentServerCName = NULL;
	me.currentServerType = NULL;
	me.currentServerMap = NULL;
	me.currentServerPlayers = NULL;
	me.currentServerNumPlayers = NULL;
	me.currentServerNumBots = NULL;
	me.currentServerMod = NULL;
	me.currentServerVersion = NULL;
	me.currentServerPing = NULL;
	me.nameLabel = NULL;
	me.cnameLabel = NULL;
	me.typeLabel = NULL;
	me.mapLabel = NULL;
	me.rawPlayerList = NULL;
	me.numPlayersLabel = NULL;
	me.numBotsLabel = NULL;
	me.modLabel = NULL;
	me.versionLabel = NULL;
	me.pingLabel = NULL;
	me.classname = "NexuizServerInfoDialog";
	return me;
}
float SLIST_FIELD_NAME;
float SLIST_FIELD_CNAME;
float SLIST_FIELD_QCSTATUS;
float SLIST_FIELD_MAP;
float SLIST_FIELD_PLAYERS;
float SLIST_FIELD_NUMHUMANS;
float SLIST_FIELD_MAXPLAYERS;
float SLIST_FIELD_NUMBOTS;
float SLIST_FIELD_MOD;
float SLIST_FIELD_PING;
void Join_Click(entity btn, entity me);
void loadServerInfoNexuizServerInfoDialog(entity me, float i)
{
	float m;
	string s, typestr, versionstr, numh, maxp;
	SLIST_FIELD_NAME = gethostcacheindexforkey("name");
	me.currentServerName = str_zone_ifneeded(gethostcachestring(SLIST_FIELD_NAME, i));
	me.nameLabel.setText(me.nameLabel, me.currentServerName);
	SLIST_FIELD_CNAME = gethostcacheindexforkey("cname");
	me.currentServerCName = str_zone_ifneeded(gethostcachestring(SLIST_FIELD_CNAME, i));
	me.cnameLabel.setText(me.cnameLabel, me.currentServerCName);
	SLIST_FIELD_QCSTATUS = gethostcacheindexforkey("qcstatus");
	s = gethostcachestring(SLIST_FIELD_QCSTATUS, i);
	m = tokenizebyseparator(s, ":");
	if(m > 1)
	{
		typestr = argv (0);
		versionstr = argv(1);
	}
	else
	{
		typestr = _("N/A");
		versionstr = _("N/A");
	}
	me.currentServerType = str_zone_ifneeded(typestr);
	me.typeLabel.setText(me.typeLabel, me.currentServerType);
	SLIST_FIELD_MAP = gethostcacheindexforkey("map");
	me.currentServerMap = str_zone_ifneeded(gethostcachestring(SLIST_FIELD_MAP, i));
	me.mapLabel.setText(me.mapLabel, me.currentServerMap);
	SLIST_FIELD_PLAYERS = gethostcacheindexforkey("players");
	me.currentServerPlayers = str_zone_ifneeded(gethostcachestring(SLIST_FIELD_PLAYERS, i));
	me.rawPlayerList.setPlayerList(me.rawPlayerList, me.currentServerPlayers);
	SLIST_FIELD_NUMHUMANS = gethostcacheindexforkey("numhumans");
	numh = ftos(gethostcachenumber(SLIST_FIELD_NUMHUMANS, i));
	SLIST_FIELD_MAXPLAYERS = gethostcacheindexforkey("maxplayers");
	maxp = ftos(gethostcachenumber(SLIST_FIELD_MAXPLAYERS, i));
	me.currentServerNumPlayers = str_zone_ifneeded(strcat(numh,"/",maxp));
	me.numPlayersLabel.setText(me.numPlayersLabel, me.currentServerNumPlayers);
	SLIST_FIELD_NUMBOTS = gethostcacheindexforkey("numbots");
	s = ftos(gethostcachenumber(SLIST_FIELD_NUMBOTS, i));
	me.currentServerNumBots = str_zone_ifneeded(s);
	me.numBotsLabel.setText(me.numBotsLabel, me.currentServerNumBots);
	SLIST_FIELD_MOD = gethostcacheindexforkey("mod");
	me.currentServerMod = str_zone_ifneeded(gethostcachestring(SLIST_FIELD_MOD, i));
	me.modLabel.setText(me.modLabel, me.currentServerMod);
	me.currentServerVersion = str_zone_ifneeded(versionstr);
	me.versionLabel.setText(me.versionLabel, me.currentServerVersion);
	SLIST_FIELD_PING = gethostcacheindexforkey("ping");
	s = ftos(gethostcachenumber(SLIST_FIELD_PING, i));
	me.currentServerPing = str_zone_ifneeded(s);
	me.pingLabel.setText(me.pingLabel, me.currentServerPing);
}
void fillNexuizServerInfoDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizTextLabel(0.5, ""));
				e.colorL = SKINCOLOR_SERVERINFO_NAME;
				e.allowCut = 1;
				me.nameLabel = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizTextLabel(0.5, ""));
				e.colorL = SKINCOLOR_SERVERINFO_IP;
				e.allowCut = 1;
				me.cnameLabel = e;
	me.TR(me);
		me.TD(me, 1, 5.5, e = makeNexuizTextLabel(0, _("Players:")));
	me.TR(me);
		me.TD(me, me.rows - 4, 6, e = makeNexuizPlayerList());
				e.nexuizFont = TRUE;
				me.rawPlayerList = e;
	me.gotoRC(me, 1, 6.25); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Type:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.typeLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Map:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.mapLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Players:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.numPlayersLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Bots:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.numBotsLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Mod:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.modLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Version:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.versionLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeNexuizTextLabel(0, _("Ping:")));
		me.TD(me, 1, 4.0, e = makeNexuizTextLabel(0, ""));
				e.allowCut = 1;
				me.pingLabel = e;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns - 6, e = makeNexuizButton(_("Close"), '0 0 0'));
				e.onClick = gui_dialog_close;
				e.onClickEntity = me;
		me.TD(me, 1, me.columns - 6, e = makeNexuizButton(_("Join!"), '0 0 0'));
				e.onClick = Join_Click;
				e.onClickEntity = me;
}
void Join_Click(entity btn, entity me)
{
	localcmd("connect ", me.currentServerCName, "\n");
}
