# Utility software

This folder contains some utility software which runs on a PC connected to the Retro-25.

`make_table.pl` reads the text file `internal_storage.txt` elsewhere
in the repository and generates C initializers for encoding/decoding
the internal program storage.

`table.c` is the output of the above script, hand-edited to include
reasonable aliases for the program steps.
