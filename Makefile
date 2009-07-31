.PHONY: test clean todo run

test: lib/runtime.h
	./test-driver.rb

todo: lib/runtime.h
	./test-driver.rb -t

clean:
	rm -f lib/runtime.h driver.o test test.s

run: testdriver
	./$@

lib/runtime.h: lib/runtime.rb
	ruby $< > $@

driver.o: driver.c lib/runtime.h

testdriver: driver.o test.s
	gcc -o $@ $^
