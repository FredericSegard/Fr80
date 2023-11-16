# Fr80

 ## Z80 Homebrew computer, code-named Fr80, pronounced Freddy.
This repo will contain all the elements for a complete Z80 system (Work in progress)

### The Backplane:
The goal is to first make a ubiquitous backplane that could accommodate many 8 or 16-bit architectures, including most x86 that is compatible, Z80, eZ80, z8000, 65C02, 65C816, 6809... You name it, it should handle it. The only difference is in the PCB labeling. I have labeled the breadboard header as per the PC ISA standard on row 1, row 2 is for the Z80, and row 3 is for the 65C02. The breadboard pins are pin-to-pin mapped A1-A13 on the left, and B1-B31 on the right.
 
This backplane follows the ISA power rail standard. This means the +5, ground, +12V, and -12V lanes are where they should be. However, there is provision for a -5V regulator, since most ATX PSUs no longer support it. And since 3.3V is more prevalent these days, I have assigned the -5V lane to +3.3V. However, you can select which voltage you need by simply changing a jumper's position. There is an alternate barrel jack power input for 5 volts only. There is a provision for a 3.3V regulator should you need it. Both power sources are soft power-on. Jumpers are present to repurpose the button, since electrically, they could not be tied together.

It is a passive backplane, so there should be no interference with other signal types. So in theory, you could reassign all non-power rail buses, except for the reset lane and A7 and A8. The reset circuit, which is jumper selectable between active high or active low, cannot be reassigned. And the CPU activity LED, which monitors A7 or A8 (jumper selectable), can't also be moved.

I have just received the PCBs from the fab house. I will assemble it and let you know if everything works as intended.

![Front of board](https://github.com/FredericSegard/Fr80/blob/main/1%20-%20ATX%2016%20bit%20ISA%20passive%20backplane/Docs%20and%20Images/ATX%20backplane%20(front).jpg?raw=true)

### The Core CPU card:
I made several iterations of the CPU board, but now I'm satisfied with this revision 3. It's a very compact 100mm² 4-layer board, that contains the CPU, 128KB Flash, 512KM RAM, bank switching circuitry, a priority interrupt encoder, a CTC, and an SIO with USB ports (type A and type B).

I gave myself a challenge to fit as much as possible in a 100mm² PCB, all the while managing to put in a ZIF socket and some blinkenlights. The board is so stuffed with components, that I needed to place the bypass capacitors in the sockets, as well as some resistors. 

I will send out the Gerber for manufacturing, and keep you posted.

![Front of board](https://github.com/FredericSegard/Fr80/blob/main/2%20-%20CPU%20and%20core%20components%20(Rev%203)/Docs%20and%20Images/Front%20with%20components.jpg?raw=true)
