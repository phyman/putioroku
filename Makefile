.PHONY: clean

all: out/helloworld.zip

out: clean
	mkdir -p out

out/helloworld.zip: out
	zip -r -9 out/helloworld.zip . -x .DS_Store \*.git\* \*out\*

clean:
	rm -rf out
