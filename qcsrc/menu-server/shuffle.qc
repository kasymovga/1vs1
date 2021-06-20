void(float n, swapfunc_t swap, entity pass) shuffle {
	float i, j;
	for (i = 1; i < n; ++i) {
		// swap i-th item at a random position from 0 to i
		// proof for even distribution:
		//   n = 1: obvious
		//   n -> n+1:
		//     item n+1 gets at any position with chance 1/(n+1)
		//     all others will get their 1/n chance reduced by factor n/(n+1)
		//     to be on place n+1, their chance will be 1/(n+1)
		//     1/n * n/(n+1) = 1/(n+1)
		//     q.e.d.
		j = floor(random() * (i + 1));
		if (j != i)
			swap(j, i, pass);
	}
}

string(string s, float b, float e) shuffle_substring_range {
	return substring(s, b, e - b);
}

string(string str, float i, float j) shuffle_swap_words {
	float n;
	string s1, s2, s3, s4, s5;
	float si, ei, sj, ej, s0, en;
	n = tokenizebyseparator(str, " "); // must match g_maplist processing in ShuffleMaplist and "shuffle"
	si = argv_start_index(i);
	sj = argv_start_index(j);
	ei = argv_end_index(i);
	ej = argv_end_index(j);
	s0 = argv_start_index(0);
	en = argv_end_index(n-1);
	s1 = shuffle_substring_range(str, s0, si);
	s2 = shuffle_substring_range(str, si, ei);
	s3 = shuffle_substring_range(str, ei, sj);
	s4 = shuffle_substring_range(str, sj, ej);
	s5 = shuffle_substring_range(str, ej, en);
	return strcat(s1, s4, s3, s2, s5);
}

string _shuffle_words_str;
void(float i, float j, entity pass) _shuffle_words_swapfunc {
	_shuffle_words_str = shuffle_swap_words(_shuffle_words_str, i, j);
}

string(string str) shuffle_words {
	float n;
	_shuffle_words_str = str;
	n = tokenizebyseparator(str, " ");
	shuffle(n, _shuffle_words_swapfunc, NULL);
	str = _shuffle_words_str;
	_shuffle_words_str = NULL;
	return str;
}
