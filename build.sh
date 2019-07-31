#!/bin/bash

make COQC=~/Source/HoTT-Local/hoqc COQDEP=~/Source/HoTT-Local/hoqdep COQTOP=~/Source/HoTT-Local/hoqtop theory/fpmod.vo $@
