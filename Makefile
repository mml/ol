test: runtime.h
	./test-driver.rb

todo: runtime.h
	./test-driver.rb -t

run: testdriver
	./$@

runtime.h: runtime.rb
	ruby $< > $@

driver.o: driver.c runtime.h

testdriver: driver.o test.s
	gcc -o $@ $^
