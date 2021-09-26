float dlc_repo_finded;

string(string dlc_name) dlc_pk3_name {
	return strcat("zzz-rexdlc_", dlc_name, ".pk3");
}

string(string dlc_name) dlc_serverpackage_name {
	return strcat("rexdlc_", dlc_name, ".serverpackage");
}
string(string dlc_name) dlc_url {
	return strcat(dlc_repo, dlc_pk3_name(dlc_name));
}

float(string dlc_name) dlc_ready {
	return file_exists(dlc_serverpackage_name(dlc_name));
}

string dlc_load_queue;
float(void) dlc_load_queue_submit {
	string head, tail;
	for (head = str_car(dlc_load_queue), tail = str_cdr(dlc_load_queue); ; head = str_car(tail), tail = str_cdr(tail)) {
		if (head == "")
			continue;

		dlc_load(head, FALSE);
		if (tail == "")
			break;
	}
	str_unzone_ifneeded(dlc_load_queue);
	dlc_load_queue = "";
	return TRUE;
}

float URI_FIND_WORKING_REPO;
string dlc_repo_check;
string dlc_repo_check_list;
void dlc_find_working_repo();
entity dlc_repo_checker;

void(float id, float status, string data) dlc_find_working_repo_callback {
	if (dlc_repo_finded)
		return;

	if not(status) {
		str_unzone_ifneeded(dlc_repo);
		dlc_repo = dlc_repo_check;
		dlc_repo_check = "";
		print("DLC repository succeeded: ", dlc_repo, "\n");
		dlc_repo_finded = 1;
		dlc_load_queue_submit();
		return;
	} else {
		print("DLC repository failed: ", dlc_repo_check, " ", ftos(status), "\n");
		str_unzone_ifneeded(dlc_repo_check);
		dlc_repo_check = "";
	}
	if (dlc_repo_check_list != "")
		dlc_find_working_repo();
}

void(void) dlc_find_working_repo {
	if not(URI_FIND_WORKING_REPO)
		URI_FIND_WORKING_REPO = uri_register_handler(dlc_find_working_repo_callback);

	if (dlc_ready_all())
		return;

	if (dlc_repo_check != "") {//have active check
		return;
	}
	for (;;) {
		dlc_repo_check = str_car(dlc_repo_check_list);
		dlc_repo_check_list = str_cdr(dlc_repo_check_list);
		if (dlc_repo_check != "" || dlc_repo_check_list == "")
			break;
	}
	dlc_repo_check_list = str_zone_ifneeded(dlc_repo_check_list);
	dlc_repo_check = str_zone_ifneeded(dlc_repo_check);
	if (dlc_repo_check != "") {
		print("Checking repo ", dlc_repo_check, "\n");
		uri_get(strcat(dlc_repo_check, "dlc_list.txt"), URI_FIND_WORKING_REPO);
	}
}

float(string dlc_name, float force_local) dlc_load {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s == dlc_name)
			goto skip_add_to_list;
	}
	s = strzone(strcat(dlc_list, " ", dlc_name));
	str_unzone_ifneeded(dlc_list);
	dlc_list = s;
:skip_add_to_list
	if (dlc_ready(dlc_name))
		return TRUE;

	if (dlc_repo_finded && !force_local)
		localcmd("\ncurl --pak ", dlc_url(dlc_name), "\n");
	else {
		if not(force_local)
		if not(dlc_repo_checker) {
			dlc_repo_checker = spawn();
			dlc_repo_checker.think = dlc_find_working_repo;
			dlc_repo_checker.nextthink = time + 2;
		}
		localcmd("\ncurl --pak ", dlc_pk3_name(dlc_name), "\n");
		s = strcat(dlc_load_queue, " ", dlc_name);
		str_unzone_ifneeded(dlc_load_queue);
		dlc_load_queue = strzone(s);
	}
	return FALSE;
}

void(string l) dlc_load_local_list {
	string s;
	while (l != "") {
		s = str_car(l);
		l = str_cdr(l);
		if (s != "") {
			if not(dlc_ready(s)) {
				print("Loading dlc: ", s, "\n");
				localcmd("\ncurl --pak ", dlc_pk3_name(s), "\n");
			}
		}
	}
}

float(void) dlc_ready_all {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s != "")
		if not(dlc_ready(s))
			return FALSE;
	}
	if (dlc_repo_checker) {
		remove(dlc_repo_checker);
		dlc_repo_checker = NULL;
	}
	return TRUE;
}


void(string repos) dlc_set_repos {
	if (dlc_repo_finded)
		return;

	string s = strcat(repos, " ", dlc_repo_check_list);
	str_unzone_ifneeded(dlc_repo_check_list);
	dlc_repo_check_list = s;
	dlc_repo_check_list = str_zone_ifneeded(dlc_repo_check_list);
}
