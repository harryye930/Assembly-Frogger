# Assembly-Frogger
Using Assembly language to replicate an arcade game [Frogger](https://froggerclassic.appspot.com/), using registers, stacks and program counters to perform various loops, conditions and more. Show understanding on low level computer operation.

To run the program, following the following steps:
 1. Have Java ready and download [MARS MIPS simulator](http://courses.missouristate.edu/kenvollmar/mars/) 
 2. Download `frogger.asm` and open in MARS
 3. Setup Bitmap Display(MARS -> Tools -> Bitmap Display) with the following settings
	 - Set parameters like unit width & height (8) and base address for display. 
	 - Click “Connect to MIPS” once these are set.
	 - <img width="518" alt="Screen Shot 2022-05-01 at 9 47 28 AM" src="https://user-images.githubusercontent.com/89664586/166148760-90fbeae1-4069-4cd3-8b13-a8c6b2edf5a0.png">

 4. Set up keyboard: Tools > Keyboard and Display MMIO Simulator
	 - Click “Connect to MIPS”
 5. Run > Assemble
 6. Run > Go (to start running your program)
 7. Try entering characters (such as w, a, s or d) in Keyboard area (bottom white box) in Keyboard and Display MMIO Simulator window
