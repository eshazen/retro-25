
all: load_firmware load_prog clip_stack

clean:
	rm -f sio_test hex_load *.o *~ \#*

clip_stack: clip_stack.o sio_cmd.o
	$(CC) -o clip_stack clip_stack.o sio_cmd.o

load_firmware: load_firmware.o sio_cmd.o
	$(CC) -o load_firmware load_firmware.o sio_cmd.o

load_prog: load_prog.o sio_cmd.o
	$(CC) -o load_prog load_prog.o sio_cmd.o
