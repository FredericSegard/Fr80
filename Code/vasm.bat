@echo off
vasmz80_oldstyle -dotdir -chklabels -nocase %1.asm -Fbin -o %1.out -L %1.txt
vasmz80_oldstyle -dotdir -chklabels -nocase %1.asm -Fihex