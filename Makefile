# Low-tech Makefile to build and install dylan-playground.

# This Makefile assumes you have an Open Dylan that can build static
# executables. That is, a post-2020.1 release.

DYLAN		?= $${HOME}/dylan
environment	?= dev
install_dir     = /opt/dylan-playground/$(environment)
install_bin     = $(install_dir)/bin

.PHONY: build clean install dist distclean

build:
	dylan update
	dylan build --unify dylan-playground

install: build
	mkdir -p $(install_bin)
	mkdir -p $(install_dir)/shares
	cp _build/sbin/dylan-playground.dbg $(install_bin)/dylan-playground
	cp -p playground.dsp $(install_dir)/
	cp -r static $(install_dir)/
	cp -p config.$(environment).xml $(install_dir)/config.xml

dist: distclean install

clean:
	rm -rf _build

distclean: clean
	rm -rf $(install_dir)
