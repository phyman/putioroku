.PHONY: clean

all: build/bingewatchr.zip

build: clean
	mkdir -p build

build/bingewatchr.zip: build
	zip -r -9 build/bingewatchr.zip . -x .DS_Store \*.git\* \*build\*

clean:
	rm -rf build
