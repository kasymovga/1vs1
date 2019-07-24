float dlc_repo_finded;

string dlc_pk3_name(string dlc_name) {
	return strcat("zzz-rexdlc_", dlc_name, ".pk3");
}

string dlc_serverpackage_name(string dlc_name) {
	return strcat("rexdlc_", dlc_name, ".serverpackage");
}
string dlc_url(string dlc_name) {
	return strcat(dlc_repo, dlc_pk3_name(dlc_name));
}

float dlc_ready(string dlc_name) {
	return file_exists(dlc_serverpackage_name(dlc_name));
}

string dlc_load_queue;
float dlc_load_queue_sumit() {
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

void dlc_find_working_repo_callback(float id, float status, string data) {
	if (dlc_repo_finded)
		return;

	if not(status) {
		str_unzone_ifneeded(dlc_repo);
		dlc_repo = dlc_repo_check;
		dlc_repo_check = "";
		print("DLC repository succeeded: ", dlc_repo, "\n");
		dlc_repo_finded = 1;
		dlc_load_queue_sumit();
		return;
	} else {
		print("DLC repository failed: ", dlc_repo_check, " ", ftos(status), "\n");
		str_unzone_ifneeded(dlc_repo_check);
		dlc_repo_check = "";
	}
	if (dlc_repo_check_list != "")
		dlc_find_working_repo();
}

void dlc_find_working_repo() {
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

float dlc_load(string dlc_name, float force_local) {
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
#ifndef MENUQC
		if not(force_local)
		if not(dlc_repo_checker) {
			dlc_repo_checker = spawn();
			dlc_repo_checker.think = dlc_find_working_repo;
			dlc_repo_checker.nextthink = time + 2;
		}
#endif
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

float dlc_ready_all() {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s != "")
		if not(dlc_ready(s))
			return FALSE;
	}
#ifndef MENUQC
	if (dlc_repo_checker) {
		remove(dlc_repo_checker);
		dlc_repo_checker = world;
	}
#endif
	return TRUE;
}


void dlc_set_repos(string repos) {
	if (dlc_repo_finded)
		return;

	string s = strcat(repos, " ", dlc_repo_check_list);
	str_unzone_ifneeded(dlc_repo_check_list);
	dlc_repo_check_list = s;
	dlc_repo_check_list = str_zone_ifneeded(dlc_repo_check_list);
}
