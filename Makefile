SV_SOURCES=$(shell find qcsrc/server qcsrc/common -type f -regextype posix-egrep -regex '.*\.(qc|qh|src)')
CL_SOURCES=$(shell find qcsrc/client qcsrc/common -type f -regextype posix-egrep -regex '.*\.(qc|qh|src)')
FTEQCC=fteqcc

all: 1vs1.dat cl_1vs1.dat cl.pk3

1vs1.dat : $(SV_SOURCES)
	cd qcsrc/server && $(FTEQCC) -O3

cl_1vs1.dat : $(CL_SOURCES)
	cd qcsrc/client && $(FTEQCC) -O3

.PHONY: cl.pk3

cl.pk3 : cl_1vs1.dat
	HASH=`md5sum cl_1vs1.dat | head -c 8`; DATE=`stat -c %y cl_1vs1.dat | head -c 19 | sed 's/[ -:]//g'`; NAME="cl_1vs1-$$DATE$$HASH.pk3";\
if test ! -f "$$NAME" -o cl_1vs1.dat -nt "$$NAME"; then rm -f cl_1vs1*.pk3; zip "$$NAME" cl_1vs1.dat; fi
