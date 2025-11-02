CROSS_COMPILE ?= riscv32-linux-gnu-
CC      = $(CROSS_COMPILE)gcc
AS      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -fno-common -nostdlib -nostartfiles
LDFLAGS = -T link.ld -nostdlib -nostartfiles

SRCS_C  = test.c
SRCS_S  = start.S
OBJS    = $(SRCS_S:.S=.o) $(SRCS_C:.c=.o) 

ELF     = test.elf
BIN     = test.bin
HEX     = test.hex
MEM     = test.mem
MIF     = test.mif
MAP     = test.map
DUMP    = test.dump
VERILOG = picorv32.v  system_picorv32.v  tb_sys_picorv32.v ram1port8k_sim.v BCDto7seg.v 
VCD 	= tb_sys_picorv32.vcd
VVP 	= tb_sys_picorv32.vvp
TRACE	= trace.txt
QUARTUS = db incremental_db output_files simulation *.qws 

GENERATED = $(OBJS) $(ELF) $(BIN) $(HEX) $(MEM) $(MIF) $(MAP) $(DUMP) $(VCD) $(VVP)  $(TRACE) 

.PHONY: all clean dump

all: $(HEX) $(MEM) $(MIF) $(VCD)

# Link
$(ELF): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(MAP) -o $@ $(OBJS)

%.o: %.S
	$(AS) $(CFLAGS) -c $< -o $@

# Compile .c
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# ELF -> BIN/HEX
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

# MEM: 32-bit little-endian words (pour $readmemh)
$(MEM): $(BIN)
	@echo "Génération du fichier MEM (Verilog 32-bit LE)..."
	@hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%02s%02s%02s%02s\n", $$4, $$3, $$2, $$1)}' > $(MEM)
	@echo "✅ $(MEM)"

# ---------------------------------------------------------------
# Génération du fichier MIF (Quartus 32-bit words, little-endian)
# ---------------------------------------------------------------
$(MIF): $(BIN)
	@echo "Génération du fichier MIF (Quartus 32-bit, little-endian)..."
	@echo "-- MIF file generated from $(BIN)"             >  $(MIF)
	@echo "WIDTH=32;"                                    >> $(MIF)
	@echo "DEPTH=8192;"                                  >> $(MIF)
	@echo "ADDRESS_RADIX=HEX;"                           >> $(MIF)
	@echo "DATA_RADIX=HEX;"                              >> $(MIF)
	@echo "CONTENT BEGIN"                                >> $(MIF)
	@# Génère les mots little-endian (4 octets → 1 mot)
	@hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%04X : %02s%02s%02s%02s;\n", NR-1, $$4, $$3, $$2, $$1)}' >> $(MIF)
	@# Calcule la dernière adresse utilisée et ajoute le remplissage à zéro
	@LAST_ADDR=$$(expr `wc -c < $(BIN)` / 4); \
	if [ $$LAST_ADDR -lt 8192 ]; then \
	  printf "[%04X .. %04X] : 00000000;\n" $$LAST_ADDR 8191 >> $(MIF); \
	fi
	@echo "END;"                                         >> $(MIF)
	@echo "✅ Fichier MIF généré (32-bit LE, complété à 0x2000) : $(MIF)"

dump: $(ELF)
	$(OBJDUMP) -D $(ELF) > $(DUMP)
	
tb_sys_picorv32.vvp  :  $(VERILOG) $(MEM)
	iverilog  -o $@  $(VERILOG) 
tb_sys_picorv32.vcd :tb_sys_picorv32.vvp
	vvp   $^ > $(TRACE) 

clean:
	@echo "🧹 Nettoyage des fichiers générés..."
	rm -f $(GENERATED) ; rm -rf $(QUARTUS)
