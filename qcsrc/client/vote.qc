void(void) vote_commands_read {
	string s = ReadString();
	string head, tail;
	float i;
	for (i = 0; i < vote_commands_count; i++) {
		strunzone(vote_commands[i]);
	}
	vote_commands_count = 0;
	for (head = str_car(s), tail = str_cdr(s); ; head = str_car(tail), tail = str_cdr(tail)) {
		if (head == "") {
			if (tail == "")
				break;

			continue;
		}
		vote_commands[vote_commands_count] = strzone(head);
		vote_commands_count++;
		if (vote_commands_count >= VOTE_COMMANDS_COUNT)
			return;
	}
}


