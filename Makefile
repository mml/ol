test: runtime.h
	./test-driver.rb

runtime.h: runtime.rb
	ruby $< > $@

driver.o: driver.c runtime.h
