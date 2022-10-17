.DEFAULT_GOAL = main

words.inc: colon.inc

%.o: %.asm words.inc colon.inc lib.inc dict.inc
	nasm -felf64 -g -o $@ $<

main: main.o lib.o dict.o
	ld -o $@ $^

.PHONY: clean
clean:
	rm *.o
	rm main