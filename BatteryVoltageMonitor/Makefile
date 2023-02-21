calculations:
	cd include; python3 ./calculations.py

syntax: calculations
	@echo "\e[33m\e[1mSyntax\e[0m"
	picaxepreprocess.py --tablesertxd -s -i BatteryVoltsMonitor.bas -o compiled.bas
	@rm compiled.err

upload: calculations
	@echo "\e[33m\e[1mUpload\e[0m"
	picaxepreprocess.py --tablesertxd -u -i BatteryVoltsMonitor.bas -o compiled.bas
	@rm compiled.err