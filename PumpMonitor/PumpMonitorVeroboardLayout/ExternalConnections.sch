EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Pump monitor off board wiring"
Date "2021-03-05"
Rev ""
Comp "Jotham Gates"
Comment1 "All blocks with red dash-dot borders contain mains potential."
Comment2 "This design involves mains electricity and water. Appropriate precautions MUST be taken."
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector:Conn_WallSocket_Earth P3
U 1 1 60440EC1
P 7700 1650
F 0 "P3" H 7150 2100 50  0000 C CNN
F 1 "Conn_WallSocket_Earth" H 7550 2000 50  0000 C CNN
F 2 "" H 7400 1750 50  0001 C CNN
F 3 "~" H 7400 1750 50  0001 C CNN
	1    7700 1650
	1    0    0    -1  
$EndComp
$Comp
L Transformer:CST2010 T1
U 1 1 6044191E
P 6250 2450
F 0 "T1" H 6250 2800 50  0000 C CNN
F 1 "CST2010" H 6250 2784 50  0001 C CNN
F 2 "Transformer_SMD:Transformer_Coilcraft_CST2010" H 6250 2450 50  0001 C CNN
F 3 "https://www.coilcraft.com/pdfs/cst2010.pdf" H 6250 2450 50  0001 C CNN
	1    6250 2450
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_WallPlug_Earth P2
U 1 1 604425E7
P 2250 1550
F 0 "P2" H 2150 1900 50  0000 C CNN
F 1 "Conn_WallPlug_Earth" H 2500 1800 50  0000 C CNN
F 2 "" H 2650 1550 50  0001 C CNN
F 3 "~" H 2650 1550 50  0001 C CNN
	1    2250 1550
	1    0    0    -1  
$EndComp
$Comp
L Converter_ACDC:TMLM04112 PS1
U 1 1 604443A9
P 5400 4400
F 0 "PS1" H 5400 4750 50  0000 C CNN
F 1 "Plugpack power supply internals" H 5550 4100 50  0000 C CNN
F 2 "Converter_ACDC:Converter_ACDC_TRACO_TMLM-04_THT" H 5400 4050 50  0001 C CNN
F 3 "https://www.tracopower.com/products/tmlm.pdf" H 5400 4400 50  0001 C CNN
	1    5400 4400
	1    0    0    -1  
$EndComp
$Comp
L Connector:AudioJack3 J6
U 1 1 60445859
P 8750 5750
F 0 "J6" H 8732 6075 50  0000 C CNN
F 1 "AudioJack3" H 8732 5984 50  0000 C CNN
F 2 "" H 8750 5750 50  0001 C CNN
F 3 "~" H 8750 5750 50  0001 C CNN
	1    8750 5750
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_WallPlug_Earth P6
U 1 1 604561E6
P 4400 4400
F 0 "P6" H 4250 4750 50  0000 C CNN
F 1 "Conn_WallPlug_Earth" H 4600 4650 50  0000 C CNN
F 2 "" H 4800 4400 50  0001 C CNN
F 3 "~" H 4800 4400 50  0001 C CNN
	1    4400 4400
	1    0    0    -1  
$EndComp
$Comp
L Connector:Barrel_Jack J4
U 1 1 60487344
P 7500 4400
F 0 "J4" H 7350 4750 50  0000 C CNN
F 1 "Barrel_Jack" H 7550 4650 50  0000 C CNN
F 2 "" H 7550 4360 50  0001 C CNN
F 3 "~" H 7550 4360 50  0001 C CNN
	1    7500 4400
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_Coaxial_Power J3
U 1 1 6048AF19
P 6750 4500
F 0 "J3" V 6600 4450 50  0000 C CNN
F 1 "Conn_Coaxial_Power" V 6850 4450 50  0000 C CNN
F 2 "" H 6750 4450 50  0001 C CNN
F 3 "~" H 6750 4450 50  0001 C CNN
	1    6750 4500
	0    1    1    0   
$EndComp
Wire Wire Line
	6550 4500 5800 4500
Wire Wire Line
	6850 4500 6950 4500
Wire Wire Line
	6950 4500 6950 4300
Wire Wire Line
	6950 4300 5800 4300
Wire Wire Line
	5000 4300 4700 4300
Wire Notes Line style dash_dot rgb(194, 0, 0)
	6250 3600 4100 3600
Wire Wire Line
	5000 4500 4700 4500
Text Notes 4450 3800 0    79   ~ 0
Plugpack power supply
$Comp
L Connector:Screw_Terminal_01x03 J5
U 1 1 604EB3A4
P 10450 4400
F 0 "J5" H 9950 4750 50  0000 C CNN
F 1 "Power & Current Sense" H 10300 4650 50  0000 C CNN
F 2 "" H 10450 4400 50  0001 C CNN
F 3 "~" H 10450 4400 50  0001 C CNN
	1    10450 4400
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x03 J7
U 1 1 604F6089
P 10450 5750
F 0 "J7" H 10050 5600 50  0000 L CNN
F 1 "Programming" H 10050 5500 50  0000 L CNN
F 2 "" H 10450 5750 50  0001 C CNN
F 3 "~" H 10450 5750 50  0001 C CNN
	1    10450 5750
	1    0    0    -1  
$EndComp
Wire Wire Line
	10250 5650 8950 5650
Wire Wire Line
	10250 5750 8950 5750
Wire Wire Line
	10250 5850 8950 5850
Wire Notes Line
	10550 5650 10550 5850
Wire Wire Line
	10250 4500 9200 4500
Wire Wire Line
	10250 4300 7800 4300
Wire Wire Line
	9200 2900 9200 4500
Connection ~ 9200 4500
Wire Wire Line
	9200 4500 7800 4500
Wire Wire Line
	10250 4400 9350 4400
Wire Wire Line
	9350 4400 9350 2800
Wire Wire Line
	2550 1450 3250 1450
Wire Wire Line
	2550 1650 3000 1650
Wire Wire Line
	5800 1650 5800 2250
Wire Wire Line
	5800 2250 6050 2250
Wire Wire Line
	6450 2250 6700 2250
Wire Wire Line
	6700 2250 6700 1650
Wire Wire Line
	6700 1650 7500 1650
$Comp
L Connector:Conn_01x02_Male J1
U 1 1 605364EC
P 7050 2800
F 0 "J1" H 7050 2900 50  0000 C CNN
F 1 "Conn_01x02_Male" H 7300 2600 50  0000 C CNN
F 2 "" H 7050 2800 50  0001 C CNN
F 3 "~" H 7050 2800 50  0001 C CNN
	1    7050 2800
	-1   0    0    -1  
$EndComp
Wire Wire Line
	6550 2450 6700 2450
Wire Wire Line
	6700 2450 6700 2800
Wire Wire Line
	6700 2800 6850 2800
Wire Wire Line
	6850 2900 5800 2900
Wire Wire Line
	5800 2900 5800 2450
Wire Wire Line
	5800 2450 5950 2450
Text Notes 3600 2400 0    50   ~ 0
Current transormer made from a ferrite choke. \nPrimary should be double insulated and well isolated.
Connection ~ 2750 1850
Wire Wire Line
	2750 1850 2550 1850
Connection ~ 3000 1650
Connection ~ 3250 1450
Wire Wire Line
	2750 1850 7500 1850
Wire Wire Line
	3250 1450 7500 1450
Wire Wire Line
	3000 1650 5800 1650
$Comp
L Motor:Motor_AC M1
U 1 1 6058FDFF
P 10150 1500
F 0 "M1" H 10308 1496 50  0000 L CNN
F 1 "Motor_AC" H 10308 1405 50  0000 L CNN
F 2 "" H 10150 1410 50  0001 C CNN
F 3 "~" H 10150 1410 50  0001 C CNN
	1    10150 1500
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_WallPlug_Earth P4
U 1 1 605972EC
P 8600 1550
F 0 "P4" H 8500 1800 50  0000 C CNN
F 1 "Conn_WallPlug_Earth" H 8900 1100 50  0000 C CNN
F 2 "" H 9000 1550 50  0001 C CNN
F 3 "~" H 9000 1550 50  0001 C CNN
	1    8600 1550
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_DPST SW1
U 1 1 6059DDF9
P 9350 1550
F 0 "SW1" H 9350 1900 50  0000 C CNN
F 1 "Pressure Switch" H 9350 1784 50  0000 C CNN
F 2 "" H 9350 1550 50  0001 C CNN
F 3 "~" H 9350 1550 50  0001 C CNN
	1    9350 1550
	1    0    0    -1  
$EndComp
Wire Wire Line
	8900 1450 9150 1450
Wire Wire Line
	8900 1650 9150 1650
Wire Wire Line
	9550 1450 9800 1450
Wire Wire Line
	9800 1450 9800 1200
Wire Wire Line
	9800 1200 10150 1200
Wire Wire Line
	10150 1200 10150 1300
Wire Wire Line
	9550 1650 9800 1650
Wire Wire Line
	9800 1650 9800 1900
Wire Wire Line
	9800 1900 10150 1900
Wire Wire Line
	10150 1900 10150 1800
$Comp
L Connector:Conn_WallSocket_Earth P1
U 1 1 605B0180
P 1450 1650
F 0 "P1" H 900 2100 50  0000 L CNN
F 1 "Conn_WallSocket_Earth" H 900 2000 50  0000 L CNN
F 2 "" H 1150 1750 50  0001 C CNN
F 3 "~" H 1150 1750 50  0001 C CNN
	1    1450 1650
	1    0    0    -1  
$EndComp
Wire Notes Line style dash_dot rgb(194, 0, 0)
	8250 800  8250 2100
Wire Notes Line style dash_dot rgb(194, 0, 0)
	8250 2100 10750 2100
Wire Notes Line style dash_dot rgb(194, 0, 0)
	10750 2100 10750 800 
Wire Notes Line style dash_dot rgb(194, 0, 0)
	10750 800  8250 800 
Text Notes 9100 1000 0    79   ~ 0
Pressure pump
Wire Notes Line style dash_dot rgb(194, 0, 0)
	1800 800  1800 2100
Text Notes 1000 1100 0    79   ~ 0
Mains\npowerpoint
Wire Wire Line
	3250 4300 3250 1450
Wire Wire Line
	3400 4300 3250 4300
Wire Wire Line
	3000 4500 3400 4500
Wire Wire Line
	3000 1650 3000 4500
Wire Wire Line
	2750 4700 2750 1850
Wire Wire Line
	3400 4700 2750 4700
$Comp
L Connector:Conn_WallSocket_Earth P5
U 1 1 604592A0
P 3600 4500
F 0 "P5" H 3100 4150 50  0000 L CNN
F 1 "Conn_WallSocket_Earth" H 2850 4050 50  0000 L CNN
F 2 "" H 3300 4600 50  0001 C CNN
F 3 "~" H 3300 4600 50  0001 C CNN
	1    3600 4500
	1    0    0    -1  
$EndComp
Wire Notes Line
	8350 4950 8350 6300
Wire Notes Line
	8350 6300 10800 6300
Wire Notes Line
	10800 6300 10800 4950
Wire Notes Line
	10800 4950 8350 4950
Text Notes 8700 5150 0    79   ~ 0
Programming cable adapter
Text Notes 10600 5650 0    39   ~ 0
TX
Text Notes 10600 5750 0    39   ~ 0
RX\n
Text Notes 10600 5850 0    39   ~ 0
GND
Wire Wire Line
	9350 2800 7900 2800
Wire Wire Line
	7900 2900 9200 2900
$Comp
L Connector:Conn_01x02_Female J2
U 1 1 60446D82
P 7700 2800
F 0 "J2" H 7700 3000 50  0000 C CNN
F 1 "Conn_01x02_Female" H 7350 2900 50  0000 C CNN
F 2 "" H 7700 2800 50  0001 C CNN
F 3 "~" H 7700 2800 50  0001 C CNN
	1    7700 2800
	-1   0    0    -1  
$EndComp
Wire Notes Line style dash_dot rgb(194, 0, 0)
	1950 5150 3950 5150
Wire Notes Line style dash_dot rgb(194, 0, 0)
	3950 5150 3950 3150
Wire Notes Line style dash_dot rgb(194, 0, 0)
	3950 3150 7250 3150
Wire Notes Line style dash_dot rgb(194, 0, 0)
	7250 3150 7250 2100
Wire Notes Line style dash_dot rgb(194, 0, 0)
	7250 2100 8050 2100
Wire Notes Line style dash_dot rgb(194, 0, 0)
	8050 2100 8050 800 
Wire Notes Line style dash_dot rgb(194, 0, 0)
	8050 800  1950 800 
Text Notes 3800 1000 0    79   ~ 0
Current sense and double adapter cable
Wire Notes Line
	7500 2350 10800 2350
Wire Notes Line
	10800 2350 10800 4700
Wire Notes Line
	10800 4700 7150 4700
Wire Notes Line
	7150 4700 7150 3950
Wire Notes Line
	7150 3950 7500 3950
Wire Notes Line
	7500 3950 7500 2350
Text Notes 8150 2550 0    79   ~ 0
Power and current sense adapter
Text Notes 10550 4300 0    39   ~ 0
+V
Text Notes 10550 4400 0    39   ~ 0
Sense
Text Notes 10550 4500 0    39   ~ 0
GND
NoConn ~ 1250 1850
NoConn ~ 1250 1650
NoConn ~ 1250 1450
Wire Notes Line style dash_dot rgb(194, 0, 0)
	6250 5000 6250 3600
Wire Notes Line style dash_dot rgb(194, 0, 0)
	4100 5000 6250 5000
Wire Notes Line style dash_dot rgb(194, 0, 0)
	4100 3600 4100 5000
Wire Notes Line style dash_dot rgb(194, 0, 0)
	1950 800  1950 5150
Wire Notes Line style dash_dot rgb(194, 0, 0)
	1800 2100 850  2100
Wire Notes Line style dash_dot rgb(194, 0, 0)
	850  2100 850  800 
Wire Notes Line style dash_dot rgb(194, 0, 0)
	850  800  1800 800 
$EndSCHEMATC
