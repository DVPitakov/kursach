@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\MC\kursach\labels.tmp" -fI -W+ie -C V2E -o "C:\MC\kursach\Kurs.hex" -d "C:\MC\kursach\Kurs.obj" -e "C:\MC\kursach\Kurs.eep" -m "C:\MC\kursach\Kurs.map" "C:\MC\kursach\Kurs.asm"
