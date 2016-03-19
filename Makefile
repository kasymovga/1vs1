SV_SOURCES=$(shell find qcsrc/server qcsrc/common -type f -regextype posix-egrep -regex '.*\.(qc|qh|src)')
CL_SOURCES=$(shell find qcsrc/client qcsrc/common -type f -regextype posix-egrep -regex '.*\.(qc|qh|src)')
FTEQCC=fteqcc

all: 1vs1.dat cl_1vs1.dat

1vs1.dat : $(SV_SOURCES)
	cd qcsrc/server && $(FTEQCC) -O3

cl_1vs1.dat : $(CL_SOURCES)
	cd qcsrc/client && $(FTEQCC) -O3
