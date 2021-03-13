EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "PICAXE Pressure pump monitor"
Date "2021-03-05"
Rev ""
Comp "Jotham Gates"
Comment1 "This design involves mains electricity and water. Appropriate precautions MUST be taken."
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Regulator_Linear:LM317_TO-220 U1
U 1 1 600C0EA9
P 2000 1450
F 0 "U1" H 2000 1692 50  0000 C CNN
F 1 "LM317_TO-220" H 2000 1601 50  0000 C CNN
F 2 "Package_TO_SOT_THT:TO-220-3_Vertical" H 2000 1700 50  0001 C CIN
F 3 "http://www.ti.com/lit/ds/symlink/lm317.pdf" H 2000 1450 50  0001 C CNN
	1    2000 1450
	1    0    0    -1  
$EndComp
$Comp
L Device:R R1
U 1 1 600C3F5E
P 2550 1700
F 0 "R1" H 2620 1746 50  0000 L CNN
F 1 "270" H 2620 1655 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 2480 1700 50  0001 C CNN
F 3 "~" H 2550 1700 50  0001 C CNN
	1    2550 1700
	1    0    0    -1  
$EndComp
$Comp
L Device:R R2
U 1 1 600C4F13
P 2550 2150
F 0 "R2" H 2620 2196 50  0000 L CNN
F 1 "470" H 2620 2105 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 2480 2150 50  0001 C CNN
F 3 "~" H 2550 2150 50  0001 C CNN
	1    2550 2150
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C3
U 1 1 600C561D
P 3000 1950
F 0 "C3" H 3118 1996 50  0000 L CNN
F 1 "100u" H 3118 1905 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm" H 3038 1800 50  0001 C CNN
F 3 "~" H 3000 1950 50  0001 C CNN
	1    3000 1950
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C1
U 1 1 600C612E
P 1250 1950
F 0 "C1" H 1368 1996 50  0000 L CNN
F 1 "100u" H 1368 1905 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm" H 1288 1800 50  0001 C CNN
F 3 "~" H 1250 1950 50  0001 C CNN
	1    1250 1950
	1    0    0    -1  
$EndComp
$Comp
L Device:C C5
U 1 1 600C66DC
P 9200 4500
F 0 "C5" V 8948 4500 50  0000 C CNN
F 1 "100n" V 9039 4500 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P2.50mm" H 9238 4350 50  0001 C CNN
F 3 "~" H 9200 4500 50  0001 C CNN
	1    9200 4500
	-1   0    0    1   
$EndComp
$Comp
L power:Earth #PWR02
U 1 1 600C8067
P 2000 2500
F 0 "#PWR02" H 2000 2250 50  0001 C CNN
F 1 "Earth" H 2000 2350 50  0001 C CNN
F 2 "" H 2000 2500 50  0001 C CNN
F 3 "~" H 2000 2500 50  0001 C CNN
	1    2000 2500
	1    0    0    -1  
$EndComp
Wire Wire Line
	1700 1450 1250 1450
Wire Wire Line
	1250 1450 1250 1800
Wire Wire Line
	1250 2100 1250 2450
Wire Wire Line
	1250 2450 2000 2450
Connection ~ 2000 2450
Wire Wire Line
	2000 2450 2000 2500
Wire Wire Line
	2000 2450 2550 2450
Wire Wire Line
	2550 2450 2550 2300
Wire Wire Line
	2550 2000 2550 1900
Wire Wire Line
	2550 1550 2550 1450
Wire Wire Line
	2550 1450 2300 1450
Wire Wire Line
	2550 1450 3000 1450
Wire Wire Line
	3000 1450 3000 1800
Connection ~ 2550 1450
Wire Wire Line
	3000 2100 3000 2450
Wire Wire Line
	3000 2450 2550 2450
Connection ~ 2550 2450
Wire Wire Line
	2000 1750 2000 1900
Wire Wire Line
	2000 1900 2550 1900
Connection ~ 2550 1900
Wire Wire Line
	2550 1900 2550 1850
$Comp
L power:+3.3V #PWR07
U 1 1 600CB14A
P 3500 1350
F 0 "#PWR07" H 3500 1200 50  0001 C CNN
F 1 "+3.3V" H 3515 1523 50  0000 C CNN
F 2 "" H 3500 1350 50  0001 C CNN
F 3 "" H 3500 1350 50  0001 C CNN
	1    3500 1350
	1    0    0    -1  
$EndComp
$Comp
L power:+12V #PWR01
U 1 1 600CD7BD
P 1250 1350
F 0 "#PWR01" H 1250 1200 50  0001 C CNN
F 1 "+12V" H 1265 1523 50  0000 C CNN
F 2 "" H 1250 1350 50  0001 C CNN
F 3 "" H 1250 1350 50  0001 C CNN
	1    1250 1350
	1    0    0    -1  
$EndComp
Wire Wire Line
	1250 1350 1250 1450
Connection ~ 1250 1450
$Comp
L Device:LED D1
U 1 1 600D1871
P 3500 2200
F 0 "D1" V 3539 2082 50  0000 R CNN
F 1 "Power" V 3448 2082 50  0000 R CNN
F 2 "LED_THT:LED_D5.0mm_Clear" H 3500 2200 50  0001 C CNN
F 3 "~" H 3500 2200 50  0001 C CNN
	1    3500 2200
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R6
U 1 1 600D4097
P 3500 1700
F 0 "R6" H 3570 1746 50  0000 L CNN
F 1 "150" H 3570 1655 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3430 1700 50  0001 C CNN
F 3 "~" H 3500 1700 50  0001 C CNN
	1    3500 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3000 1450 3500 1450
Wire Wire Line
	3500 1450 3500 1350
Connection ~ 3000 1450
Wire Wire Line
	3500 1450 3500 1550
Connection ~ 3500 1450
Wire Wire Line
	3500 1850 3500 2050
Wire Wire Line
	3500 2350 3500 2450
Wire Wire Line
	3500 2450 3000 2450
Connection ~ 3000 2450
$Comp
L Memory_EEPROM:24LC16 U2
U 1 1 6011323E
P 2700 4700
F 0 "U2" H 2700 5181 50  0000 C CNN
F 1 "24LC16" H 2700 5090 50  0000 C CNN
F 2 "Package_DIP:DIP-8_W7.62mm_Socket" H 2700 4700 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/21703d.pdf" H 2700 4700 50  0001 C CNN
	1    2700 4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	7800 4700 7800 4500
Wire Wire Line
	7800 4500 7600 4500
$Comp
L power:Earth #PWR08
U 1 1 6013A903
P 5350 5200
F 0 "#PWR08" H 5350 4950 50  0001 C CNN
F 1 "Earth" H 5350 5050 50  0001 C CNN
F 2 "" H 5350 5200 50  0001 C CNN
F 3 "~" H 5350 5200 50  0001 C CNN
	1    5350 5200
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR05
U 1 1 6013B624
P 2700 4050
F 0 "#PWR05" H 2700 3900 50  0001 C CNN
F 1 "+3.3V" H 2715 4223 50  0000 C CNN
F 2 "" H 2700 4050 50  0001 C CNN
F 3 "" H 2700 4050 50  0001 C CNN
	1    2700 4050
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR010
U 1 1 6013D862
P 9200 4000
F 0 "#PWR010" H 9200 3850 50  0001 C CNN
F 1 "+3.3V" H 9215 4173 50  0000 C CNN
F 2 "" H 9200 4000 50  0001 C CNN
F 3 "" H 9200 4000 50  0001 C CNN
	1    9200 4000
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x03 J2
U 1 1 6013F855
P 4800 3500
F 0 "J2" H 4718 3175 50  0000 C CNN
F 1 "Programming" H 4718 3266 50  0000 C CNN
F 2 "Connector_Molex:Molex_KK-254_AE-6410-03A_1x03_P2.54mm_Vertical" H 4800 3500 50  0001 C CNN
F 3 "~" H 4800 3500 50  0001 C CNN
	1    4800 3500
	-1   0    0    -1  
$EndComp
Wire Wire Line
	5350 5050 5350 5200
$Comp
L Device:R R9
U 1 1 6015065A
P 5350 3750
F 0 "R9" H 5420 3796 50  0000 L CNN
F 1 "10k" H 5420 3705 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 5280 3750 50  0001 C CNN
F 3 "~" H 5350 3750 50  0001 C CNN
	1    5350 3750
	1    0    0    -1  
$EndComp
$Comp
L Device:R R10
U 1 1 60150F53
P 6350 3900
F 0 "R10" V 6250 3900 50  0000 C CNN
F 1 "22k" V 6350 3900 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 6280 3900 50  0001 C CNN
F 3 "~" H 6350 3900 50  0001 C CNN
	1    6350 3900
	0    1    1    0   
$EndComp
Wire Wire Line
	6600 3900 6500 3900
Wire Wire Line
	6200 3900 5600 3900
Wire Wire Line
	5000 3400 5850 3400
Wire Wire Line
	5850 3800 6600 3800
Wire Wire Line
	9200 4650 9200 5050
Wire Wire Line
	9200 5050 8850 5050
Wire Wire Line
	9200 4350 9200 4100
Wire Wire Line
	7600 4100 9200 4100
Connection ~ 9200 4100
Wire Wire Line
	9200 4100 9200 4000
$Comp
L power:+3.3V #PWR011
U 1 1 601890EF
P 10050 2550
F 0 "#PWR011" H 10050 2400 50  0001 C CNN
F 1 "+3.3V" H 10065 2723 50  0000 C CNN
F 2 "" H 10050 2550 50  0001 C CNN
F 3 "" H 10050 2550 50  0001 C CNN
	1    10050 2550
	1    0    0    -1  
$EndComp
$Comp
L power:Earth #PWR09
U 1 1 6018BE47
P 9250 2500
F 0 "#PWR09" H 9250 2250 50  0001 C CNN
F 1 "Earth" H 9250 2350 50  0001 C CNN
F 2 "" H 9250 2500 50  0001 C CNN
F 3 "~" H 9250 2500 50  0001 C CNN
	1    9250 2500
	1    0    0    -1  
$EndComp
Wire Wire Line
	10050 2550 10050 2650
Wire Wire Line
	10050 2650 9900 2650
Wire Wire Line
	6600 4300 4300 4300
Wire Wire Line
	4300 4300 4300 4600
Wire Wire Line
	4300 4600 3550 4600
Wire Wire Line
	2700 5000 2700 5050
Wire Wire Line
	2700 5050 5350 5050
Wire Wire Line
	5000 3500 5350 3500
Wire Wire Line
	5350 3900 5350 4100
Wire Wire Line
	5600 3500 5600 3900
Wire Wire Line
	5850 3400 5850 3800
Wire Wire Line
	5350 3600 5350 3500
Wire Wire Line
	5000 3600 5100 3600
Wire Wire Line
	5100 4100 5350 4100
Wire Wire Line
	5350 4100 5350 5050
Wire Wire Line
	5100 3600 5100 4100
Wire Wire Line
	6600 4000 4450 4000
Wire Wire Line
	4450 4000 4450 3100
Wire Wire Line
	9900 2950 10000 2950
Wire Wire Line
	10000 2950 10000 3100
Wire Wire Line
	4300 2950 4300 4200
Wire Wire Line
	9400 2650 9350 2650
Wire Wire Line
	9350 2650 9350 2450
Wire Wire Line
	9350 2450 9250 2450
Wire Wire Line
	9250 2450 9250 2500
Wire Wire Line
	4300 2950 9400 2950
Wire Wire Line
	9400 2850 7850 2850
Wire Wire Line
	7850 2850 7850 3800
Wire Wire Line
	7850 3800 7600 3800
Wire Wire Line
	9400 2750 7700 2750
Wire Wire Line
	7700 2750 7700 3700
Wire Wire Line
	7700 3700 7600 3700
Wire Wire Line
	9900 2850 10150 2850
Wire Wire Line
	10150 2850 10150 3250
Wire Wire Line
	10150 3250 8000 3250
Wire Wire Line
	8000 3250 8000 3900
Wire Wire Line
	8000 3900 7600 3900
Wire Wire Line
	9900 2750 10300 2750
Wire Wire Line
	10300 2750 10300 3350
Wire Wire Line
	10300 3350 8150 3350
Wire Wire Line
	8150 3350 8150 4000
Wire Wire Line
	8150 4000 7600 4000
Wire Wire Line
	3100 4700 3250 4700
$Comp
L Device:LED D3
U 1 1 60275328
P 8250 4800
F 0 "D3" V 8289 4682 50  0000 R CNN
F 1 "Pump On" V 8198 4682 50  0000 R CNN
F 2 "LED_THT:LED_D5.0mm_Clear" H 8250 4800 50  0001 C CNN
F 3 "~" H 8250 4800 50  0001 C CNN
	1    8250 4800
	0    -1   -1   0   
$EndComp
$Comp
L Switch:SW_Push SW1
U 1 1 602773CD
P 8850 4800
F 0 "SW1" V 8896 4752 50  0000 R CNN
F 1 "SW_Push" V 8805 4752 50  0000 R CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 8850 5000 50  0001 C CNN
F 3 "~" H 8850 5000 50  0001 C CNN
	1    8850 4800
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8850 5000 8850 5050
Connection ~ 8850 5050
Wire Wire Line
	8850 5050 8250 5050
Wire Wire Line
	8850 4600 8850 4200
Wire Wire Line
	8850 4200 7600 4200
Wire Wire Line
	8250 4950 8250 5050
Connection ~ 8250 5050
$Comp
L Device:R R12
U 1 1 60299AE6
P 8000 4300
F 0 "R12" V 7793 4300 50  0000 C CNN
F 1 "150" V 7884 4300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 7930 4300 50  0001 C CNN
F 3 "~" H 8000 4300 50  0001 C CNN
	1    8000 4300
	0    1    1    0   
$EndComp
Wire Wire Line
	7600 4300 7850 4300
Wire Wire Line
	8150 4300 8250 4300
Wire Wire Line
	8250 4300 8250 4650
$Comp
L Ra01_Breakout_Module:Ra01_Breakout_Module J3
U 1 1 600C2733
P 9600 2750
F 0 "J3" H 9650 3075 50  0000 C CNN
F 1 "Ra01_Breakout_Module" H 9650 2984 50  0000 C CNN
F 2 "Package_DIP:DIP-8_W7.62mm_Socket" H 9600 2750 50  0001 C CNN
F 3 "~" H 9600 2750 50  0001 C CNN
	1    9600 2750
	1    0    0    -1  
$EndComp
Wire Wire Line
	10000 3100 4450 3100
Wire Wire Line
	6600 4500 6450 4500
$Comp
L Device:R R11
U 1 1 600FF7EC
P 6350 3700
F 0 "R11" V 6150 3800 50  0000 R CNN
F 1 "180" V 6250 3800 50  0000 R CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 6280 3700 50  0001 C CNN
F 3 "~" H 6350 3700 50  0001 C CNN
	1    6350 3700
	0    1    1    0   
$EndComp
$Comp
L Device:LED D2
U 1 1 60100F8C
P 6050 4500
F 0 "D2" V 6089 4382 50  0000 R CNN
F 1 "Alarm" V 5998 4382 50  0000 R CNN
F 2 "LED_THT:LED_D5.0mm_Clear" H 6050 4500 50  0001 C CNN
F 3 "~" H 6050 4500 50  0001 C CNN
	1    6050 4500
	0    -1   -1   0   
$EndComp
$Comp
L Picaxe:PICAXE-18M2 U3
U 1 1 600D6DAD
P 7100 4100
F 0 "U3" H 7100 4765 50  0000 C CNN
F 1 "PICAXE-18M2" H 7100 4674 50  0000 C CNN
F 2 "Package_DIP:DIP-18_W7.62mm_Socket" H 7100 4800 50  0001 C CNN
F 3 "" H 7100 4800 50  0001 C CNN
	1    7100 4100
	1    0    0    -1  
$EndComp
$Comp
L power:Earth #PWR04
U 1 1 60186723
P 2650 7100
F 0 "#PWR04" H 2650 6850 50  0001 C CNN
F 1 "Earth" H 2650 6950 50  0001 C CNN
F 2 "" H 2650 7100 50  0001 C CNN
F 3 "~" H 2650 7100 50  0001 C CNN
	1    2650 7100
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR06
U 1 1 60187653
P 3700 5900
F 0 "#PWR06" H 3700 5750 50  0001 C CNN
F 1 "+3.3V" H 3715 6073 50  0000 C CNN
F 2 "" H 3700 5900 50  0001 C CNN
F 3 "" H 3700 5900 50  0001 C CNN
	1    3700 5900
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C2
U 1 1 60188123
P 3450 6700
F 0 "C2" V 3195 6700 50  0000 C CNN
F 1 "10u" V 3286 6700 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm" H 3488 6550 50  0001 C CNN
F 3 "~" H 3450 6700 50  0001 C CNN
	1    3450 6700
	0    1    1    0   
$EndComp
$Comp
L Transistor_BJT:BC548 Q1
U 1 1 6018A649
P 3900 6700
F 0 "Q1" H 4091 6746 50  0000 L CNN
F 1 "BC548" H 4091 6655 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 4100 6625 50  0001 L CIN
F 3 "https://www.onsemi.com/pub/Collateral/BC550-D.pdf" H 3900 6700 50  0001 L CNN
	1    3900 6700
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:BC548 Q2
U 1 1 6018CA38
P 4650 6700
F 0 "Q2" H 4841 6746 50  0000 L CNN
F 1 "BC548" H 4841 6655 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 4850 6625 50  0001 L CIN
F 3 "https://www.onsemi.com/pub/Collateral/BC550-D.pdf" H 4650 6700 50  0001 L CNN
	1    4650 6700
	1    0    0    -1  
$EndComp
$Comp
L Device:R R5
U 1 1 6018DD9A
P 4000 6250
F 0 "R5" H 4070 6296 50  0000 L CNN
F 1 "2.2k" H 4070 6205 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3930 6250 50  0001 C CNN
F 3 "~" H 4000 6250 50  0001 C CNN
	1    4000 6250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 6018F8C5
P 3700 6250
F 0 "R3" H 3770 6296 50  0000 L CNN
F 1 "220k" H 3770 6205 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3630 6250 50  0001 C CNN
F 3 "~" H 3700 6250 50  0001 C CNN
	1    3700 6250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2550 6700 3300 6700
Wire Wire Line
	3600 6700 3700 6700
Wire Wire Line
	2650 7100 2650 7000
Wire Wire Line
	2650 6800 2550 6800
Wire Wire Line
	4000 6900 4000 7000
Wire Wire Line
	4000 7000 2650 7000
Connection ~ 2650 7000
Wire Wire Line
	2650 7000 2650 6800
Wire Wire Line
	4000 6500 4000 6450
Wire Wire Line
	3700 6400 3700 6700
Connection ~ 3700 6700
Wire Wire Line
	3700 5900 3700 6000
Wire Wire Line
	3700 6000 4000 6000
Wire Wire Line
	4000 6000 4000 6100
Connection ~ 3700 6000
Wire Wire Line
	3700 6000 3700 6100
$Comp
L Device:R R8
U 1 1 601DBCEC
P 4750 6250
F 0 "R8" H 4820 6296 50  0000 L CNN
F 1 "2.2k" H 4820 6205 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4680 6250 50  0001 C CNN
F 3 "~" H 4750 6250 50  0001 C CNN
	1    4750 6250
	1    0    0    -1  
$EndComp
Wire Wire Line
	4450 6700 4350 6700
Wire Wire Line
	4350 6700 4350 6450
Wire Wire Line
	4350 6450 4000 6450
Connection ~ 4000 6450
Wire Wire Line
	4000 6450 4000 6400
Wire Wire Line
	4750 6500 4750 6450
Wire Wire Line
	4750 6900 4750 7000
Wire Wire Line
	4750 7000 4000 7000
Connection ~ 4000 7000
Wire Wire Line
	4750 6100 4750 6000
Wire Wire Line
	4750 6000 4000 6000
Connection ~ 4000 6000
$Comp
L Device:CP C4
U 1 1 601F52F5
P 5150 6250
F 0 "C4" H 5268 6296 50  0000 L CNN
F 1 "33u" H 5268 6205 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm" H 5188 6100 50  0001 C CNN
F 3 "~" H 5150 6250 50  0001 C CNN
	1    5150 6250
	1    0    0    -1  
$EndComp
Wire Wire Line
	5150 6100 5150 6000
Wire Wire Line
	5150 6000 4750 6000
Connection ~ 4750 6000
Wire Wire Line
	5150 6400 5150 6450
Wire Wire Line
	5150 6450 4750 6450
Connection ~ 4750 6450
Wire Wire Line
	4750 6450 4750 6400
Wire Wire Line
	6450 6450 5150 6450
Wire Wire Line
	6450 4500 6450 6450
Connection ~ 5150 6450
$Comp
L Device:R R7
U 1 1 6028D0F4
P 3550 4350
F 0 "R7" H 3620 4396 50  0000 L CNN
F 1 "10k" H 3620 4305 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3480 4350 50  0001 C CNN
F 3 "~" H 3550 4350 50  0001 C CNN
	1    3550 4350
	1    0    0    -1  
$EndComp
$Comp
L Device:R R4
U 1 1 6028E118
P 3250 4350
F 0 "R4" H 3320 4396 50  0000 L CNN
F 1 "10k" H 3320 4305 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3180 4350 50  0001 C CNN
F 3 "~" H 3250 4350 50  0001 C CNN
	1    3250 4350
	1    0    0    -1  
$EndComp
Wire Wire Line
	2700 4050 2700 4100
Wire Wire Line
	3550 4500 3550 4600
Connection ~ 3550 4600
Wire Wire Line
	3550 4600 3100 4600
Wire Wire Line
	3250 4500 3250 4700
Connection ~ 3250 4700
Wire Wire Line
	3550 4200 3550 4100
Wire Wire Line
	3550 4100 3250 4100
Connection ~ 2700 4100
Wire Wire Line
	2700 4100 2700 4400
Wire Wire Line
	3250 4200 3250 4100
Connection ~ 3250 4100
Wire Wire Line
	3250 4100 2700 4100
NoConn ~ 2300 4800
NoConn ~ 2300 4700
NoConn ~ 2300 4600
NoConn ~ 3100 4800
NoConn ~ 7600 4400
NoConn ~ 6600 4400
$Comp
L Connector:Screw_Terminal_01x03 J1
U 1 1 602FC145
P 2350 6700
F 0 "J1" H 2268 6375 50  0000 C CNN
F 1 "Power & Current Sense" H 2268 6466 50  0000 C CNN
F 2 "TerminalBlock:TerminalBlock_bornier-3_P5.08mm" H 2350 6700 50  0001 C CNN
F 3 "~" H 2350 6700 50  0001 C CNN
	1    2350 6700
	-1   0    0    -1  
$EndComp
$Comp
L power:+12V #PWR03
U 1 1 60319B84
P 2650 5900
F 0 "#PWR03" H 2650 5750 50  0001 C CNN
F 1 "+12V" H 2665 6073 50  0000 C CNN
F 2 "" H 2650 5900 50  0001 C CNN
F 3 "" H 2650 5900 50  0001 C CNN
	1    2650 5900
	1    0    0    -1  
$EndComp
Wire Wire Line
	2650 5900 2650 6600
Wire Wire Line
	2650 6600 2550 6600
Connection ~ 5350 3500
Connection ~ 5350 4100
Wire Wire Line
	5350 3500 5600 3500
Connection ~ 5350 5050
Wire Wire Line
	5350 4100 6600 4100
Wire Wire Line
	5350 5050 6050 5050
Wire Wire Line
	4300 4200 6600 4200
Wire Wire Line
	3250 4700 7800 4700
Wire Wire Line
	6600 3700 6500 3700
Wire Wire Line
	6200 3700 6050 3700
Wire Wire Line
	6050 3700 6050 4350
Wire Wire Line
	6050 4650 6050 5050
Connection ~ 6050 5050
Wire Wire Line
	6050 5050 8250 5050
Wire Notes Line
	4900 3350 4900 3650
$EndSCHEMATC
