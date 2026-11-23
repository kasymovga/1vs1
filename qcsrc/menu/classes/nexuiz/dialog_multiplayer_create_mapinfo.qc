entity spawnNexuizMapInfoDialog() {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = fillNexuizMapInfoDialog;
	me.loadMapInfo = loadMapInfoNexuizMapInfoDialog;
	me.title = _("Map Information");
	me.color = SKINCOLOR_DIALOG_MAPINFO;
	me.intendedWidth = 0.85;
	me.rows = 16;
	me.columns = 10;
	me.previewImage = NULL;
	me.titleLabel = NULL;
	me.authorLabel = NULL;
	me.descriptionLabel = NULL;
	me.featuresLabel = NULL;
	me.typeLabelNext = NULL;
	me.currentMapIndex = 0;
	me.currentMapBSPName = NULL;
	me.currentMapTitle = NULL;
	me.currentMapAuthor = NULL;
	me.currentMapDescription = NULL;
	me.currentMapPreviewImage = NULL;
	me.currentMapFeaturesText = NULL;
	me.instanceOfNexuizMapInfoDialog = 1;
	me.classname = "NexuizMapInfoDialog";
	return me;
}
void loadMapInfoNexuizMapInfoDialog(entity me, float i, entity mlb)
{
	me.currentMapIndex = i;
	me.startButton.onClickEntity = mlb;
	map_info_get_by_id(i);
	str_unzone_ifneeded(me.currentMapBSPName);
	str_unzone_ifneeded(me.currentMapTitle);
	str_unzone_ifneeded(me.currentMapAuthor);
	str_unzone_ifneeded(me.currentMapDescription);
	str_unzone_ifneeded(me.currentMapPreviewImage);
	str_unzone_ifneeded(me.currentMapFeaturesText);
	me.currentMapBSPName = str_zone_ifneeded(map_info_map_bspname);
	me.currentMapTitle = str_zone_ifneeded(map_info_map_title);
	me.currentMapAuthor = str_zone_ifneeded(map_info_map_author);
	me.currentMapDescription = str_zone_ifneeded(map_info_map_description);
	me.currentMapFeaturesText = str_zone_ifneeded((map_info_map_supported_features & MAP_INFO_FEATURE_WEAPONS) ? _("Full item placement") : _("MinstaGib only"));
	me.currentMapPreviewImage = str_zone_ifneeded(strcat("/", map_info_map_image));
	me.frame.setText(me.frame, me.currentMapBSPName);
	me.titleLabel.setText(me.titleLabel, me.currentMapTitle);
	me.authorLabel.setText(me.authorLabel, me.currentMapAuthor);
	me.descriptionLabel.setText(me.descriptionLabel, me.currentMapDescription);
	me.featuresLabel.setText(me.featuresLabel, me.currentMapFeaturesText);
	me.previewImage.src = me.currentMapPreviewImage;
	entity e;
	float t;
	t = GAME_TYPE_DEATHMATCH;
	for (e = me.typeLabelNext; e; e = e.typeLabelNext) {
		e.disabled = !(map_info_map_supported_game_types & map_info_type_from_game_type(t));
		t++;
	}
	map_info_clear_temps();
}
void fillNexuizMapInfoDialog(entity me)
{
	entity e;
	float w;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, me.rows - 2, 3, e = makeNexuizImage(NULL, 4.0/3.0));
		me.previewImage = e;
	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
	w = me.columns - me.currentColumn;
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Title:")));
		me.TD(me, 1, w-1, e = gui_rexuiz_textlabel_make(0, ""));
				e.colorL = SKINCOLOR_MAPLIST_TITLE;
				e.allowCut = 1;
				me.titleLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Author:")));
		me.TD(me, 1, w-1, e = gui_rexuiz_textlabel_make(0, ""));
				e.colorL = SKINCOLOR_MAPLIST_AUTHOR;
				e.allowCut = 1;
				me.authorLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Features:")));
		me.TD(me, 1, w-1, e = gui_rexuiz_textlabel_make(0, ""));
				e.allowCut = 1;
				me.featuresLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Game types:")));
		float i;
		e = me;
		for (i = GAME_TYPE_DEATHMATCH; i < GAME_TYPE_SINGLE; i++) {
				me.TD(me, 1, 2, e.typeLabelNext = gui_rexuiz_textlabel_make(0, game_type_name_long(i)));
				e = e.typeLabelNext;
				if not(mod(i, 2)) {
				me.TR(me);
				me.TDempty(me, 1);
				}
		}
	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_textlabel_make(0.5, ""));
				e.allowCut = 1;
				me.descriptionLabel = e;
	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, me.columns - 5.5, e = gui_rexuiz_button_make(_("Close"), '0 0 0'));
				e.onClick = gui_dialog_close;
				e.onClickEntity = me;
		me.TD(me, 1, me.columns - 5.5, me.startButton = e = gui_rexuiz_button_make(_("Play"), '0 0 0'));
				me.startButton.onClick = MapList_LoadMap;
				me.startButton.onClickEntity = NULL; // filled later
		me.TDempty(me, 0.5);
}
