all: base custom

base:
	./install-base.sh

custom: base
	./texlive/bin/*/tlmgr install $(cat pkgs-custom.txt | tr '\n' ' ')

bin:
	mkdir bin && cd bin && ln -s ../texlive/bin/*/* ./

clean:
	$(RM) -r install-tl* texlive bin
