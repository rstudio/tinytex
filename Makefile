all: base custom

base:
	./tools/install-base.sh

custom:
	./texlive/bin/*/tlmgr install $(cat tools/pkgs-custom.txt | tr '\n' ' ')

bin:
	mkdir bin && cd bin && ln -s ../texlive/bin/*/* ./

clean:
	$(RM) -r install-tl* texlive bin
