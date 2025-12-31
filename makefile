CROSS_COMPILE ?= riscv32-linux-gnu-
CC      = $(CROSS_COMPILE)gcc
AS      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -fno-common 
LDFLAGS = -T link.ld -nostdlib -nostartfiles

SRCS_C  = test.c
SRCS_S  = start.S
OBJS    = $(SRCS_S:.S=.o) $(SRCS_C:.c=.o) 

ELF     = test.elf
BIN     = test.bin
MEM     = test.mem
MIF     = test.mif
MAP     = test.map
DUMP    = test.dump
VERILOG = picorv32.v  system_picorv32.v  tb_sys_picorv32.v ram1port8k_sim.v BCDto7seg.v 
VCD 	= tb_sys_picorv32.vcd
VVP 	= tb_sys_picorv32.vvp
TRACE	= trace.txt
QUARTUS = db incremental_db output_files simulation *.qws 

GENERATED = $(OBJS) $(ELF) $(BIN) $(MEM) $(MIF) $(MAP) $(DUMP) $(VCD) $(VVP)  $(TRACE) 

.PHONY: all clean 

all: $(DUMP) $(MEM) $(MIF) $(VCD)

$(ELF): $(SRCS_C) $(SRCS_S)
	@echo "1️⃣  Compilation 2️⃣  Edition de lien (linker) .s .c -> .elf"
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(MAP) -o $@ $^

$(DUMP): $(ELF)
	@echo "3️⃣ -A  Déassemblage de l'exécutable .elf -> .dump"
	$(OBJDUMP) -D $(ELF) > $(DUMP)
	
$(BIN): $(ELF)
	@echo "3️⃣ -B  Transcription executable en Binaire (ASCII) .elf -> .bin"
	$(OBJCOPY) -O binary $< $@

$(MEM): $(BIN)
	@echo "3️⃣ -C  Transcription executable pour Verilog-readmemh 32-bit little-endian .bin -> .mem"
	hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%02s%02s%02s%02s\n", $$4, $$3, $$2, $$1)}' > $(MEM)

$(MIF): $(BIN)
	@echo "3️⃣ -D  Transcription executable pour Quartus .bin -> .mif"
	@echo "(Voir les commandes @echo du makefile pour l'entete du fichier > MIF)"
	@echo "-- MIF file generated from $(BIN)"             >  $(MIF)
	@echo "WIDTH=32;"                                    >> $(MIF)
	@echo "DEPTH=8192;"                                  >> $(MIF)
	@echo "ADDRESS_RADIX=HEX;"                           >> $(MIF)
	@echo "DATA_RADIX=HEX;"                              >> $(MIF)
	@echo "CONTENT BEGIN"                                >> $(MIF)
	@# Génère les mots little-endian (4 octets → 1 mot)
	hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%04X : %02s%02s%02s%02s;\n", NR-1, $$4, $$3, $$2, $$1)}' >> $(MIF)
	@# Calcule la dernière adresse utilisée et ajoute le remplissage à zéro
	@LAST_ADDR=$$(expr `wc -c < $(BIN)` / 4); \
	if [ $$LAST_ADDR -lt 8192 ]; then \
	  printf "[%04X .. %04X] : 00000000;\n" $$LAST_ADDR 8191 >> $(MIF); \
	  echo "printf \"[$$LAST_ADDR .. 8191] : 00000000;\" >> $(MIF);"; \
	fi
	@echo "END;"                                         >> $(MIF)
	@echo "✅ Compilation logicielle OK."	

$(VVP)  : $(VERILOG) $(MEM)
	@echo "4️⃣  Compilation sources verilog (incluant .mem) .v -> .vvp"
	iverilog  -o $@  $(VERILOG) 
	
$(VCD) : $(VVP)
	@echo "5️⃣  Simulation verilog .vvp -> .vcd"
	vvp   $^ > $(TRACE) 
	@echo "✅ Simulation verilog OK : cycles bus > $(TRACE), chronogrammes > $(VCD)"
	@echo " ▶️  Visualiser les traces des cycles bus : more  $(TRACE)"
	@echo " ▶️  Visualiser les chronogrammes : gtkwave  $(VCD)"

clean:
	@echo "🚮 Nettoyage des fichiers générés..."
	rm -f $(GENERATED) ; rm -rf $(QUARTUS)
	
