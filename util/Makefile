
all: hex_binary load_prog

clean:
	rm -f sio_test hex_load *.o *~ \#*

hex_binary: hex_binary.o sio_cmd.o
	$(CC) -o hex_binary hex_binary.o sio_cmd.o

load_prog: load_prog.o sio_cmd.o
	$(CC) -o load_prog load_prog.o sio_cmd.o
