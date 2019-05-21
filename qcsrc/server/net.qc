void(entity e, float docull, float dt, float(entity, float) sendfunc) net_link_entity {
    vector mi, ma;

    if (e.classname == "")
        e.classname = "net_linked";

    if (e.model == "" || self.modelindex == 0)
    {
        mi = e.mins;
        ma = e.maxs;
        setmodel(e, "null");
        setsize(e, mi, ma);
    }

    e.SendEntity = sendfunc;
    e.SendFlags = 0xFFFFFF;

    if (!docull)
        e.effects |= EF_NODEPTHTEST;

    if (dt)
    {
        e.nextthink = time + dt;
        e.think = SUB_Remove;
    }
}

void(float dest, float val) net_write_int24 {
	float v;
	WriteShort(dest, (v = floor(val / 256)));
	WriteByte(dest, val - v * 256); // 0..255
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

	if(x >= lengthLogTable[127])
		return 127;
	if(x <= lengthLogTable[0])
		return 0;

	l = 0;
	r = 127;

	while(r - l > 1)
	{
		m = floor((l + r) / 2);
		if(lengthLogTable[m] < x)
			l = m;
		else
			r = m;
	}

	// now: r is >=, l is <
	lerr = (x - lengthLogTable[l]);
	rerr = (lengthLogTable[r] - x);
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
