void(void) net_compress_vector_init {
	float l, f, i;
	l = 1;
	f = pow(2, 1/8);
	for(i = 0; i < 128; ++i) {
		net_log_table[i] = l;
		l *= f;
	}
}
