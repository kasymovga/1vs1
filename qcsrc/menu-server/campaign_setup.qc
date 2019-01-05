void CampaignSetupCvarsOnly(float n) {
	localcmd("set g_campaign 1\n");
	localcmd("set _campaign_name \""); localcmd(campaign_name); localcmd("\"\n");
	localcmd("set _campaign_index "); localcmd(ftos(campaign_offset + n)); localcmd("\n");
	localcmd(strcat("maxplayers ", ftos(campaign_bots[n] + 1), "\n"));
}
void CampaignSetup(float n)
{
	CampaignSetupCvarsOnly(n);
	localcmd("disconnect\n");
	MapInfo_LoadMap(campaign_mapname[n]);
}
