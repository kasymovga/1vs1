#ifdef INTERFACE
CLASS(NexuizMapInfoDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMapInfoDialog, fill, void(entity))
	METHOD(NexuizMapInfoDialog, loadMapInfo, void(entity, float, entity))
	ATTRIB(NexuizMapInfoDialog, title, string, _("Map Information"))
	ATTRIB(NexuizMapInfoDialog, color, vector, SKINCOLOR_DIALOG_MAPINFO)
	ATTRIB(NexuizMapInfoDialog, intendedWidth, float, 0.85)
	ATTRIB(NexuizMapInfoDialog, rows, float, 16)
	ATTRIB(NexuizMapInfoDialog, columns, float, 10)

	ATTRIB(NexuizMapInfoDialog, previewImage, entity, NULL)
	ATTRIB(NexuizMapInfoDialog, titleLabel, entity, NULL)
	ATTRIB(NexuizMapInfoDialog, authorLabel, entity, NULL)
	ATTRIB(NexuizMapInfoDialog, descriptionLabel, entity, NULL)
	ATTRIB(NexuizMapInfoDialog, featuresLabel, entity, NULL)

	ATTRIB(NexuizMapInfoDialog, typeLabelNext, entity, NULL)

	ATTRIB(NexuizMapInfoDialog, currentMapIndex, float, 0)
	ATTRIB(NexuizMapInfoDialog, currentMapBSPName, string, NULL)
	ATTRIB(NexuizMapInfoDialog, currentMapTitle, string, NULL)
	ATTRIB(NexuizMapInfoDialog, currentMapAuthor, string, NULL)
	ATTRIB(NexuizMapInfoDialog, currentMapDescription, string, NULL)
	ATTRIB(NexuizMapInfoDialog, currentMapPreviewImage, string, NULL)
	ATTRIB(NexuizMapInfoDialog, currentMapFeaturesText, string, NULL)
	ATTRIB(NexuizMapInfoDialog, instanceOfNexuizMapInfoDialog, float, 1)
ENDCLASS(NexuizMapInfoDialog)
#endif

#ifdef IMPLEMENTATION
void loadMapInfoNexuizMapInfoDialog(entity me, float i, entity mlb)
{
	me.currentMapIndex = i;
	me.startButton.onClickEntity = mlb;
	map_info_get_by_id(i);
	if (me.currentMapBSPName) {
		strunzone(me.currentMapBSPName);
		strunzone(me.currentMapTitle);
		strunzone(me.currentMapAuthor);
		strunzone(me.currentMapDescription);
		strunzone(me.currentMapPreviewImage);
		strunzone(me.currentMapFeaturesText);
	}
	me.currentMapBSPName = strzone(map_info_map_bspname);
	me.currentMapTitle = strzone(map_info_map_title);
	me.currentMapAuthor = strzone(map_info_map_author);
	me.currentMapDescription = strzone(map_info_map_description);
	me.currentMapFeaturesText = strzone((map_info_map_supported_features & MAP_INFO_FEATURE_WEAPONS) ? _("Full item placement") : _("MinstaGib only"));
	me.currentMapPreviewImage = strzone(strcat("/", map_info_map_image));

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
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Title:")));
		me.TD(me, 1, w-1, e = makeNexuizTextLabel(0, ""));
			e.colorL = SKINCOLOR_MAPLIST_TITLE;
			e.allowCut = 1;
			me.titleLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Author:")));
		me.TD(me, 1, w-1, e = makeNexuizTextLabel(0, ""));
			e.colorL = SKINCOLOR_MAPLIST_AUTHOR;
			e.allowCut = 1;
			me.authorLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Features:")));
		me.TD(me, 1, w-1, e = makeNexuizTextLabel(0, ""));
			e.allowCut = 1;
			me.featuresLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Game types:")));
		float i;
		e = me;
		for (i = GAME_TYPE_DEATHMATCH; i < GAME_TYPE_SINGLE; i++) {
			me.TD(me, 1, 2, e.typeLabelNext = makeNexuizTextLabel(0, game_type_name_long(i)));
			e = e.typeLabelNext;
			if not(mod(i, 2)) {
				me.TR(me);
				me.TDempty(me, 1);
			}
		}

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, me.columns, e = makeNexuizTextLabel(0.5, ""));
			e.allowCut = 1;
			me.descriptionLabel = e;

	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 0.5);

		me.TD(me, 1, me.columns - 5.5, e = makeNexuizButton(_("Close"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns - 5.5, me.startButton = e = makeNexuizButton(_("Play"), '0 0 0'));
			me.startButton.onClick = MapList_LoadMap;
			me.startButton.onClickEntity = NULL; // filled later
		me.TDempty(me, 0.5);
}
#endif
