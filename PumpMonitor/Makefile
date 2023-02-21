syntax:
	@echo "\e[33m\e[1mSlot 0 (Bootloader)\e[0m"
	picaxepreprocess.py --tablesertxd -s -i PumpMonitor_slot0.bas -o compiled_slot0.bas
	@echo
	@echo "\e[33m\e[1mSlot 1 (Main program)\e[0m"
	picaxepreprocess.py --tablesertxd -s -i PumpMonitor_slot1.bas -o compiled_slot1.bas
	@rm compiled_slot0.err
	@rm compiled_slot1.err

upload:
	@echo "\e[33m\e[1mSlot 0 (Bootloader)\e[0m"
	picaxepreprocess.py --tablesertxd -u -i PumpMonitor_slot0.bas -o compiled_slot0.bas
	@echo
	@echo "\e[33m\e[1mSlot 1 (Main program)\e[0m"
	picaxepreprocess.py --tablesertxd -u -i PumpMonitor_slot1.bas -o compiled_slot1.bas
	@rm compiled_slot0.err
	@rm compiled_slot1.err