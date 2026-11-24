void(entity me, entity button) gui_rexuiz_dialog_winner_close;
void(entity me) gui_rexuiz_dialog_winner_fill;

entity(void) gui_rexuiz_dialog_winner_spawn {
	entity me = gui_rexuiz_dialog_spawn();
	me.fill = gui_rexuiz_dialog_winner_fill;
	me.title = _("Congratulations!");
	me.color = SKINCOLOR_DIALOG_SINGLEPLAYER;
	me.intendedWidth = 0.4;
	me.rows = 12;
	me.columns = 3;
	me.classname = "NexuizWinnerDialog";
	return me;
}

void(entity me, entity button) gui_rexuiz_dialog_winner_close {
	gui_dialog_close(me, button);
	menu_goto("credits");
}

void(entity me) gui_rexuiz_dialog_winner_fill {
	entity e;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, me.rows - 3, me.columns - 1, e = gui_rexuiz_image_make("/gfx/winner", -1));
	me.gotoRC(me, me.rows - 3, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_textlabel_make(0, _("You have successfully completed the Single Player Campaign!")));
		e.align = 0.5;
		e.allowWrap = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("OK"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_winner_close;
			e.onClickEntity = me;
}
