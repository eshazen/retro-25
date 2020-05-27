
all: load_firmware load_prog

clean:
	rm -f sio_test hex_load *.o *~ \#*

load_firmware: load_firmware.o sio_cmd.o
	$(CC) -o load_firmware load_firmware.o sio_cmd.o

load_prog: load_prog.o sio_cmd.o
	$(CC) -o load_prog load_prog.o sio_cmd.o
