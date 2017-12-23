void GameMenu_Add_Item(string item, string cmd) {
	WriteString(MSG_ENTITY, item);
	WriteString(MSG_ENTITY, cmd);
}

void GameMenu_Send() {
	GameHookChain_GameMenuAddItems(GameMenu_Add_Item);
	WriteString(MSG_ENTITY, "");
}
