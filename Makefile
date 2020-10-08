
GATEBOYDIR := ./gateboy
SCREENCTRL := ./screen

SOURCES := $(shell find . -name '*.v')

YOSYS_SCRIPT:=syn.ys

DOCKER=docker

PWD = $(shell pwd)
DOCKERARGS = run --rm -v $(PWD):/src -w /src
#
GHDL      = $(DOCKER) $(DOCKERARGS) ghdl/synth:beta ghdl
GHDLSYNTH = ghdl
YOSYS     = $(DOCKER) $(DOCKERARGS) ghdl/synth:beta yosys
NEXTPNR   = $(DOCKER) $(DOCKERARGS) ghdl/synth:nextpnr-ecp5 nextpnr-ecp5
ECPPACK   = $(DOCKER) $(DOCKERARGS) ghdl/synth:trellis ecppack
OPENOCD   = $(DOCKER) $(DOCKERARGS) --device /dev/bus/usb ghdl/synth:prog openocd


LPF=constraints/ecp5-hub-5a-75b-v6.1.lpf
PACKAGE=CABGA381
# Maybe --timing-allow-fail
NEXTPNR_FLAGS=--25k --freq 125 --speed 6 --write top-post-route.json
OPENOCD_JTAG_CONFIG=openocd/ft232.cfg
OPENOCD_DEVICE_CONFIG=openocd/LFE5UM5G-25F.cfg

all : top.svf

$(YOSYS_SCRIPT):
	echo "" > $(YOSYS_SCRIPT)
	for file in $(SOURCES);	do echo "read_verilog $$file" >> $(YOSYS_SCRIPT); done
	echo "synth_ecp5 -retime" >> $(YOSYS_SCRIPT)

top.json : $(YOSYS_SCRIPT) $(SOURCE)
	$(YOSYS) -s $< -o $@

top.config : top.json $(LPF)
	#									       CABGA381
	#									       CABGA256
	$(NEXTPNR) --json $< --lpf $(LPF) --textcfg $@ $(NEXTPNR_FLAGS) --package $(PACKAGE)

top.svf : top.config
	$(ECPPACK) --svf top.svf $< $@

prog: top.svf
	$(OPENOCD) -f $(OPENOCD_JTAG_CONFIG) -f $(OPENOCD_DEVICE_CONFIG) -c "transport select jtag; init; svf $<; exit"

clean:
	@rm -f work-obj08.cf *.bit *.json *.svf *.config syn.ys

.PHONY: clean prog
.PRECIOUS: top.json top_out.config top.bit

