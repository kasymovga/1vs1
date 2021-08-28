void(float ignore) ready_read {
	float nags, i, j, b, f;
	nags = net_read_byte();
	if(nags & 1) {
		for(i = 1; i <= maxclients; i += 8) {
			f = net_read_byte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if(player_slots[j]) {
					if (f & b)
						player_slots[j].ready = 1;
					else
						player_slots[j].ready = 0;
				}
		}
	} else
		for(i = 0; i < maxclients; i++)
			if(player_slots[i])
				player_slots[i].ready = 0;
}

