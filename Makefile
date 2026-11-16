# Direct-Mapped Cache Controller - Makefile
# Tools: Icarus Verilog, VVP

# Source files
SRC = src/address_decoder.v \
      src/cache_tag_ram.v \
      src/cache_valid_ram.v \
      src/cache_data_ram.v \
      src/tag_comparator.v \
      src/main_memory.v \
      src/cache_controller.v \
      src/top_module.v

TB  = testbench/cache_tb.v

# Output files
SIM_BIN = simulation/cache_sim
VCD     = simulation/cache_waveform.vcd
LOG     = report/simulation_log.txt

# Default target
all: simulate

# Compile Verilog sources and testbench
compile: $(SRC) $(TB)
	@mkdir -p simulation
	iverilog -g2012 -o $(SIM_BIN) $(SRC) $(TB)
	@echo "Compilation successful."

# Run the simulation and save log
simulate: compile
	@mkdir -p report
	vvp $(SIM_BIN) | tee $(LOG)
	@echo ""
	@echo "Simulation log saved to $(LOG)"
	@echo "Waveform saved to $(VCD)"

# Open waveform in Surfer (if installed)
waves: $(VCD)
	surfer $(VCD) &

# Remove generated files
clean:
	rm -f $(SIM_BIN) $(VCD) $(LOG)
	@echo "Clean complete."

.PHONY: all compile simulate waves clean
