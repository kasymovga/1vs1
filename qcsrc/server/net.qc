void(entity e, float docull, float dt, float(entity, float) sendfunc) net_link_entity {
	vector mi, ma;
	if (e.classname == "")
		e.classname = "net_linked";

	if (e.model == "" || self.modelindex == 0) {
		mi = e.mins;
		ma = e.maxs;
		setmodel(e, "null");
		setsize(e, mi, ma);
	}
	e.SendEntity = sendfunc;
	e.SendFlags = 0xFFFFFF;
	if (!docull)
		e.effects |= EFFECT_NODEPTHTEST;

	if (dt) {
		e.nextthink = time + dt;
		e.think = stdproc_remove;
	}
}

void(float dest, float val) net_write_int24 {
	float v;
	net_write_short(dest, (v = floor(val / 256)));
	net_write_byte(dest, val - v * 256); // 0..255
}

// compressed vector format:
// like MD3, just even shorter
//   4 bit pitch (16 angles), 0 is -90, 8 is 0, 16 would be 90
//   5 bit yaw (32 angles), 0=0, 8=90, 16=180, 24=270
//   7 bit length (logarithmic encoding), 1/8 .. about 7844
//     length = 2^(length_encoded/8) / 8
// if pitch is 90, yaw does nothing and therefore indicates the sign (yaw is then either 11111 or 11110); 11111 is pointing DOWN
// thus, valid values are from 0000.11110.0000000 to 1111.11111.1111111
// the special value 0 indicates the zero vector

float(float x) net_invert_log_length {
	float l, r, m, lerr, rerr;

	if(x >= net_log_table[127])
		return 127;
	if(x <= net_log_table[0])
		return 0;

	l = 0;
	r = 127;

	while(r - l > 1)
	{
		m = floor((l + r) / 2);
		if(net_log_table[m] < x)
			l = m;
		else
			r = m;
	}

	// now: r is >=, l is <
	lerr = (x - net_log_table[l]);
	rerr = (net_log_table[r] - x);
	if(lerr < rerr)
		return l;
	return r;
}

float(vector vec) net_compress_vec {
	vector ang;
	float pitch, yaw, len;
	if(vlen(vec) == 0)
		return 0;
	//print("compress: ", vtos(vec), "\n");
	ang = vectoangles(vec);
	ang_x = -ang_x;
	if(ang_x < -90)
		ang_x += 360;
	if(ang_x < -90 && ang_x > +90)
		error("BOGUS vectoangles");
	//print("angles: ", vtos(ang), "\n");

	pitch = floor(0.5 + (ang_x + 90) * 16 / 180) & 15; // -90..90 to 0..14
	if(pitch == 0)
	{
		if(vec_z < 0)
			yaw = 31;
		else
			yaw = 30;
	}
	else
		yaw = floor(0.5 + ang_y * 32 / 360)          & 31; // 0..360 to 0..32
	len = net_invert_log_length(vlen(vec));

	//print("compressed: pitch ", ftos(pitch)); print("yaw ", ftos(yaw)); print("len ", ftos(len), "\n");

	return (pitch * 0x1000) + (yaw * 0x80) + len;
}

void(float t, vector v) net_write_vector {
	net_write_coord(t, v_x);
	net_write_coord(t, v_y);
	net_write_coord(t, v_z);
}

float(string s) net_ip_parse_v4 {
	float dot1, dot2, dot3;
	dot1 = strstrofs(s, ".", 0);
	if (dot1 <= 0) return FALSE;
	dot2 = strstrofs(s, ".", dot1 + 1);
	if (dot2 < 0) return FALSE;
	dot3 = strstrofs(s, ".", dot2 + 1);
	if (dot3 < 0) return FALSE;
	net_ip_pref1 = substring(s, 0, dot1);
	net_ip_pref2 = substring(s, 0, dot2);
	net_ip_pref3 = substring(s, 0, dot3);
	net_ip_pref4 = s;
	return TRUE;
}

float(string s) net_ip_parse_v6 {
	float colon_count = 0;
	float colon_pos = -1;
	float double_colon_pos;
	while ((colon_pos = strstrofs(s, ":", colon_pos + 1)) >= 0) colon_count++;
	if (colon_count <= 1) return FALSE;
	if (colon_count > 7) return FALSE;
	double_colon_pos = strstrofs(s, "::", 0);
	string s1, s2;
	if (double_colon_pos < 0 && colon_count < 7) {
		return FALSE;
	} else {
		s1 = substring(s, 0, double_colon_pos);
		s2 = substring(s, double_colon_pos + 1, -1);
		for (float i = colon_count - 1; i < 7; i++) {
			s1 = strcat(s1, ":0");
		}
		s1 = strcat(s1, s2);
	}
	if (substring(s1, 0, 1) == ":") s1 = strcat("0", s1);
	if (substring(s1, -1, 1) == ":") s1 = strcat(s1, "0");
	net_ip_pref4 = s1;
	colon_pos = -1;
	colon_count = 0;
	while ((colon_pos = strstrofs(s1, ":", colon_pos + 1)) >= 0) {
		colon_count++;
		if (colon_count == 2) { //32
			net_ip_pref1 = substring(s1, 0, colon_pos);
		} else if (colon_count == 3) { //48
			net_ip_pref2 = substring(s1, 0, colon_pos);
		} else if (colon_count == 4) { //64
			net_ip_pref3 = substring(s1, 0, colon_pos);
			break;
		}
	}
	return TRUE;
}

float(string s) net_ip_parse {
	if (strstrofs(s, ".", 0) >= 0) return net_ip_parse_v4(s);
	if (strstrofs(s, ":", 0) >= 0) return net_ip_parse_v6(s);
	return FALSE;
}

void(void) net_ip_clean {
	net_ip_pref1 = NULL;
	net_ip_pref2 = NULL;
	net_ip_pref3 = NULL;
	net_ip_pref4 = NULL;
}
