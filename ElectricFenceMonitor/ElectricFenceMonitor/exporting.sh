#!/bin/bash
folder="autoexport"
pcb="ElectricFenceMonitor.kicad_pcb"
mkdir -p "$folder"

kicad-cli pcb export svg -o "$folder/all.svg" -l "F.Cu,B.Cu,Edge.Cuts,User.Eco1,User.1,F.Fab,B.Fab" --black-and-white --page-size-mode 2 "$pcb"
kicad-cli pcb export svg -o "$folder/all_nogrid.svg" -l "F.Cu,B.Cu,Edge.Cuts,User.Eco1,F.Fab,B.Fab" --black-and-white --page-size-mode 2 "$pcb"
kicad-cli pcb export svg -o "$folder/tracks_holes_front.svg" -l "F.Cu,B.Cu,Edge.Cuts,User.Eco1,User.1" --black-and-white --page-size-mode 2 "$pcb"
kicad-cli pcb export svg -o "$folder/tracks_holes_back.svg" -l "F.Cu,B.Cu,Edge.Cuts,User.Eco1,User.1" --black-and-white --page-size-mode 2 --mirror "$pcb"