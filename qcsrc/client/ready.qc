void(float ignore) ready_read {
	float nags, i, j, b, f;
	nags = ReadByte();
	if(nags & 1) {
		for(i = 1; i <= maxclients; i += 8) {
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if(playerslots[j]) {
					if (f & b)
						playerslots[j].ready = 1;
					else
						playerslots[j].ready = 0;
				}
		}
	} else
		for(i = 0; i < maxclients; i++)
			if(playerslots[i])
				playerslots[i].ready = 0;
}

