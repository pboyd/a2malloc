MERLIN=Merlin32
MERLINFLAGS=-V /opt/Merlin32_v1.0/Library
APPLECOMMANDER=ac
MICROM8=microm8

demo.dsk: demo
	$(APPLECOMMANDER) -dos140 $@ && \
	$(APPLECOMMANDER) -p $@ $< bin 0x2000 < $<

demo: demo.s alloc.s
	$(MERLIN) $(MERLINFLAGS) demo.s

.PHONY:
run: demo.dsk
	$(MICROM8) -drive1 contrib/Apple_DOS_v3.3_1980_Apple.do -drive2 demo.dsk
