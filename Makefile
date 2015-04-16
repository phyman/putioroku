.PHONY: clean

all: build/helloworld.zip

build: clean
	mkdir -p build

build/helloworld.zip: build
	zip -r -9 build/helloworld.zip . -x .DS_Store \*.git\* \*build\*

clean:
	rm -rf build
