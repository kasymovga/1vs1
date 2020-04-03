vector(float data) net_decompress_vec {
	vector out;
	float pitch, yaw, len;
	if(data == 0)
		return '0 0 0';
	pitch = (data & 0xF000) / 0x1000;
	yaw =   (data & 0x0F80) / 0x80;
	len =   (data & 0x007F);

	//print("\ndecompress: pitch ", ftos(pitch)); print("yaw ", ftos(yaw)); print("len ", ftos(len), "\n");

	if(pitch == 0)
	{
		out_x = 0;
		out_y = 0;
		if(yaw == 31)
			out_z = -1;
		else
			out_z = +1;
	}
	else
	{
		yaw   = .19634954084936207740 * yaw;
		pitch = .19634954084936207740 * pitch - 1.57079632679489661922;
		out_x = cos(yaw) *  cos(pitch);
		out_y = sin(yaw) *  cos(pitch);
		out_z =            -sin(pitch);
	}

	//print("decompressed: ", vtos(out), "\n");

	return out * net_log_table[len];
}

