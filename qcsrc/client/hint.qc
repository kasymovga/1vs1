void(void) hint_net_read {
	float u;
	u = net_read_byte();
	if (GUI_currentWindow != GUI_HINT)
		hint_user = u;

	hint_num = net_read_byte();
	str_unzone_ifneeded(hint);
	hint = str_zone_ifneeded(net_read_string());
	if (hint_text_label)
		hint_text_label.setText(hint_text_label, hint);
	if (!hint_user && CVAR(cl_hints_skip))
		return;

	str_unzone_ifneeded(hint_cmd_next);
	str_unzone_ifneeded(hint_cmd_prev);
	hint_cmd_next = strzone(strcat("cmd hint ", ftos(hint_num + 1), "\n"));
	hint_cmd_prev = strzone(strcat("cmd hint ", ftos(hint_num - 1), "\n"));
	GUI_Show(GUI_HINT);
}
