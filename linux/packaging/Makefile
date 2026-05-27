PREFIX ?= /usr
ROOT := $(realpath $(CURDIR)/../..)
BUILDDIR := $(ROOT)/build/linux/x64/release/bundle
HELPER_BIN := $(ROOT)/helper/build/hosteditor-helper
APPDIR := $(DESTDIR)$(PREFIX)/lib/hosteditor

.PHONY: build install uninstall clean

build:
	# Workaround: flutter build linux expects build/native_assets/linux/ to
	# exist even when the project has no native asset deps. Pre-create it.
	mkdir -p $(ROOT)/build/native_assets/linux
	cd $(ROOT) && flutter build linux --release
	cd $(ROOT)/helper && dart pub get && mkdir -p build && dart compile exe bin/hosteditor_helper.dart -o build/hosteditor-helper

install:
	# Install the entire Flutter bundle (binary + data/ + lib/) into one
	# directory so the loader finds libflutter_linux_gtk.so next to the
	# executable.
	mkdir -p $(APPDIR)
	cp -r $(BUILDDIR)/. $(APPDIR)/
	chmod 755 $(APPDIR)/hosteditor
	# Wrapper on PATH that exec's into the bundle.
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	printf '#!/bin/sh\nexec %s/lib/hosteditor/hosteditor "$$@"\n' "$(PREFIX)" \
		> $(DESTDIR)$(PREFIX)/bin/hosteditor
	chmod 755 $(DESTDIR)$(PREFIX)/bin/hosteditor
	# Helper, polkit policy, desktop entry.
	install -Dm755 $(HELPER_BIN) $(DESTDIR)$(PREFIX)/libexec/hosteditor-helper
	install -Dm644 com.hosteditor.apply.policy $(DESTDIR)$(PREFIX)/share/polkit-1/actions/com.hosteditor.apply.policy
	install -Dm644 hosteditor.desktop $(DESTDIR)$(PREFIX)/share/applications/hosteditor.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/hosteditor
	rm -rf $(DESTDIR)$(PREFIX)/lib/hosteditor
	rm -rf $(DESTDIR)$(PREFIX)/share/hosteditor
	rm -f $(DESTDIR)$(PREFIX)/libexec/hosteditor-helper
	rm -f $(DESTDIR)$(PREFIX)/share/polkit-1/actions/com.hosteditor.apply.policy
	rm -f $(DESTDIR)$(PREFIX)/share/applications/hosteditor.desktop

clean:
	cd $(ROOT) && flutter clean
	rm -f $(HELPER_BIN)
