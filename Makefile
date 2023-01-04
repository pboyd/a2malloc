MERLIN=Merlin32
MERLINFLAGS=-V /opt/Merlin32_v1.0/Library
APPLECOMMANDER=ac
MICROM8=microm8

demo.dsk: test
	$(APPLECOMMANDER) -dos140 $@ && \
	$(APPLECOMMANDER) -p $@ $< bin 0x2000 < $<

test: test.s alloc.s
	$(MERLIN) $(MERLINFLAGS) test.s

.PHONY:
run: demo.dsk
	$(MICROM8) -drive1 contrib/Apple_DOS_v3.3_1980_Apple.do -drive2 demo.dsk
