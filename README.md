# Fr80

 ## Z80 Homebrew computer, code-named Fr80, pronounced Freddy.
This repo will contains all the elements for a complete Z80 system (Work in progress)

### The Backplane:
The goal is to first make a ubiquitous backplane that could accommodate many 8 or 16-bit architectures, including most x86 that is compatible, Z80, eZ80, z8000, 65C02, 65C816, 6809... You name it, it should handle it. The only difference is in the PCB labeling. I have labeled the breadboard header as per the PC ISA standard on row 1, row 2 is for the Z80, and row 3 is for the 65C02. The breadboard pins are pin-to-pin mapped A1-A13 on the left, and B1-B31 on the right.
 
This backplane follows the ISA power rail standard. This means the +5, ground, +12V, and -12V lanes are where they should be. However, there is provision for a -5V regulator, since most ATX PSUs no longer support it. And since 3.3V is more prevalent these days, I have assigned the -5V lane to +3.3V. However, you can select which voltage you need by simply changing a jumper's position. There is an alternate barrel jack power input for 5 volts only. There is a provision for a 3.3V regulator should you need it. Both power sources are soft power-on. Jumpers are present to repurpose the button, since electrically, they could not be tied together.

It is a passive backplane, so there should be no interference with other signal types. So in theory, you could reassign all non-power rail buses, except for the reset lane and A7 and A8. The reset circuit, which is jumper selectable between active high or active low, cannot be reassigned. And the CPU activity LED, which monitors A7 or A8 (jumper selectable), can't also be moved.

I have not sent it for manufacturing yet. Since I may do a few more tweaks to it. Such as the Z80 IEI-IEO interrupt-enable daisy chaining, where I will but a series of jumpers to facilitate daisy-chaining between the physical connectors.

### The Core CPU card:

Work in Progress...
