#
# Makefile to build NEUTRINO
#
$(targetprefix)/var/etc/.version:
	echo "imagename=Neutrino" > $@
	echo "homepage=http://gitorious.org/open-duckbox-project-sh4" >> $@
	echo "creator=`id -un`" >> $@
	echo "docs=http://gitorious.org/open-duckbox-project-sh4/pages/Home" >> $@
	echo "forum=http://gitorious.org/open-duckbox-project-sh4" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git describe`" >> $@

#
#
#
NEUTRINO_DEPS  = bootstrap libcrypto libcurl libid3tag libmad libvorbisidec libpng libjpeg libgif libfreetype
NEUTRINO_DEPS += ffmpeg liblua libdvbsipp libopenthreads libusb libalsa
NEUTRINO_DEPS += $(EXTERNALLCD_DEP) $(MEDIAFW_DEP)

N_CFLAGS   = -Wall -W -Wshadow -pipe -Os -fno-strict-aliasing
#-rdynamic

N_CPPFLAGS = -I$(driverdir)/bpamem
N_CPPFLAGS += -I$(targetprefix)/usr/include/

if BOXTYPE_SPARK
N_CPPFLAGS += -I$(driverdir)/frontcontroller/aotom_spark
endif

if BOXTYPE_SPARK7162
N_CPPFLAGS += -I$(driverdir)/frontcontroller/aotom_spark
endif

N_CONFIG_OPTS = --enable-silent-rules --enable-freesatepg
# --enable-pip

if ENABLE_EXTERNALLCD
N_CONFIG_OPTS += --enable-graphlcd
endif

if ENABLE_MEDIAFWGSTREAMER
N_CONFIG_OPTS += --enable-gstreamer
else
N_CONFIG_OPTS += --enable-libeplayer3
endif

OBJDIR = $(buildprefix)/BUILD
N_OBJDIR = $(OBJDIR)/neutrino-mp
LH_OBJDIR = $(OBJDIR)/libstb-hal

################################################################################
#
# neutrino-mp-github
#
yaud-neutrino-mp-github: yaud-none lirc \
		boot-elf neutrino-mp-github release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# libstb-hal-github
#
$(D)/libstb-hal-github.do_prepare:
	rm -rf $(appsdir)/libstb-hal-github
	rm -rf $(appsdir)/libstb-hal-github.org
	[ -d "$(archivedir)/libstb-hal-github.git" ] && \
	(cd $(archivedir)/libstb-hal-github.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/libstb-hal-github.git" ] || \
	git clone https://github.com/MaxWiesel/libstb-hal.git $(archivedir)/libstb-hal-github.git; \
	cp -ra $(archivedir)/libstb-hal-github.git $(appsdir)/libstb-hal-github;\
	cp -ra $(appsdir)/libstb-hal-github $(appsdir)/libstb-hal-github.org
	touch $@

$(appsdir)/libstb-hal-github/config.status: | $(NEUTRINO_DEPS)
	cd $(appsdir)/libstb-hal-github && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--host=$(target) \
			--build=$(build) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/libstb-hal-github.do_compile: $(appsdir)/libstb-hal-github/config.status
	cd $(appsdir)/libstb-hal-github && \
		$(MAKE)
	touch $@

$(D)/libstb-hal-github: libstb-hal-github.do_prepare libstb-hal-github.do_compile
	$(MAKE) -C $(appsdir)/libstb-hal-github install DESTDIR=$(targetprefix)
	touch $@

libstb-hal-github-clean:
	rm -f $(D)/libstb-hal-github
	cd $(appsdir)/libstb-hal-github && \
		$(MAKE) distclean

libstb-hal-github-distclean:
	rm -f $(D)/libstb-hal-github
	rm -f $(D)/libstb-hal-github.do_compile
	rm -f $(D)/libstb-hal-github.do_prepare

#
# neutrino-mp-github
#
NEUTRINO_MP_GH_PATCHES =

$(D)/neutrino-mp-github.do_prepare: | $(NEUTRINO_DEPS) libstb-hal-github
	rm -rf $(appsdir)/neutrino-mp-github
	rm -rf $(appsdir)/neutrino-mp-github.org
	[ -d "$(archivedir)/neutrino-mp-github.git" ] && \
	(cd $(archivedir)/neutrino-mp-github.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/neutrino-mp-github.git" ] || \
	git clone https://github.com/MaxWiesel/neutrino-mp.git $(archivedir)/neutrino-mp-github.git; \
	cp -ra $(archivedir)/neutrino-mp-github.git $(appsdir)/neutrino-mp-github; \
	cp -ra $(appsdir)/neutrino-mp-github $(appsdir)/neutrino-mp-github.org
	for i in $(NEUTRINO_MP_GH_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		cd $(appsdir)/neutrino-mp-github && patch -p1 -i $$i; \
	done;
	touch $@

$(appsdir)/neutrino-mp-github/config.status:
	cd $(appsdir)/neutrino-mp-github && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--build=$(build) \
			--host=$(target) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--enable-lua \
			--enable-upnp \
			--enable-ffmpegdec \
			--enable-giflib \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-stb-hal-includes=$(appsdir)/libstb-hal-github/include \
			--with-stb-hal-build=$(appsdir)/libstb-hal-github \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			CPPFLAGS="$(N_CPPFLAGS)"

##			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"

$(D)/neutrino-mp-github.do_compile: $(appsdir)/neutrino-mp-github/config.status
	cd $(appsdir)/neutrino-mp-github && \
		$(MAKE) all
	touch $@

$(D)/neutrino-mp-github: neutrino-mp-github.do_prepare neutrino-mp-github.do_compile
	$(MAKE) -C $(appsdir)/neutrino-mp-github install DESTDIR=$(targetprefix) && \
	rm -f $(targetprefix)/var/etc/.version
	make $(targetprefix)/var/etc/.version
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	$(target)-strip $(targetprefix)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-github-clean:
	rm -f $(D)/neutrino-mp-github
	cd $(appsdir)/neutrino-mp-github && \
		$(MAKE) distclean

neutrino-mp-github-distclean:
	rm -f $(D)/neutrino-mp-github
	rm -f $(D)/neutrino-mp-github.do_compile
	rm -f $(D)/neutrino-mp-github.do_prepare

################################################################################
#
# neutrino-mp-martii
#
yaud-neutrino-mp-martii-github: yaud-none lirc \
		boot-elf neutrino-mp-martii-github release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# neutrino-mp-martii-github
#
NEUTRINO_MP_MARTII_GH_PATCHES =

$(D)/neutrino-mp-martii-github.do_prepare: | $(NEUTRINO_DEPS) libstb-hal-github
	rm -rf $(appsdir)/neutrino-mp-martii-github
	rm -rf $(appsdir)/neutrino-mp-martii-github.org
	[ -d "$(archivedir)/neutrino-mp-martii-github.git" ] && \
	(cd $(archivedir)/neutrino-mp-martii-github.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/neutrino-mp-martii-github.git" ] || \
	git clone https://github.com/MaxWiesel/neutrino-mp-martii.git $(archivedir)/neutrino-mp-martii-github.git; \
	cp -ra $(archivedir)/neutrino-mp-martii-github.git $(appsdir)/neutrino-mp-martii-github; \
	cp -ra $(appsdir)/neutrino-mp-martii-github $(appsdir)/neutrino-mp-martii-github.org
	for i in $(NEUTRINO_MP_MARTII_GH_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		cd $(appsdir)/neutrino-mp-martii-github && patch -p1 -i $$i; \
	done;
	touch $@

$(appsdir)/neutrino-mp-martii-github/config.status:
	cd $(appsdir)/neutrino-mp-martii-github && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--build=$(build) \
			--host=$(target) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--enable-giflib \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-stb-hal-includes=$(appsdir)/libstb-hal-github/include \
			--with-stb-hal-build=$(appsdir)/libstb-hal-github \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/neutrino-mp-martii-github.do_compile: $(appsdir)/neutrino-mp-martii-github/config.status
	cd $(appsdir)/neutrino-mp-martii-github && \
		$(MAKE) all
	touch $@

$(D)/neutrino-mp-martii-github: neutrino-mp-martii-github.do_prepare neutrino-mp-martii-github.do_compile
	$(MAKE) -C $(appsdir)/neutrino-mp-martii-github install DESTDIR=$(targetprefix) && \
	rm -f $(targetprefix)/var/etc/.version
	make $(targetprefix)/var/etc/.version
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	$(target)-strip $(targetprefix)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-martii-github-clean:
	rm -f $(D)/neutrino-mp-martii-github
	cd $(appsdir)/neutrino-mp-martii-github && \
		$(MAKE) distclean

neutrino-mp-martii-github-distclean:
	rm -f $(D)/neutrino-mp-martii-github
	rm -f $(D)/neutrino-mp-martii-github.do_compile
	rm -f $(D)/neutrino-mp-martii-github.do_prepare

################################################################################
#
# yaud-neutrino-mp
#
yaud-neutrino-mp: yaud-none lirc \
		boot-elf neutrino-mp release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

yaud-neutrino-mp-plugins: yaud-none lirc \
		boot-elf neutrino-mp neutrino-mp-plugins release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

yaud-neutrino-mp-all: yaud-none lirc \
		boot-elf neutrino-mp neutrino-mp-plugins shairport release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# libstb-hal
#
NEUTRINO_MP_LIBSTB_PATCHES =

$(D)/libstb-hal.do_prepare:
	rm -rf $(appsdir)/libstb-hal
	rm -rf $(appsdir)/libstb-hal.org
	[ -d "$(archivedir)/libstb-hal.git" ] && \
	(cd $(archivedir)/libstb-hal.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/libstb-hal.git" ] || \
	git clone git://gitorious.org/neutrino-hd/max10s-libstb-hal.git $(archivedir)/libstb-hal.git; \
	cp -ra $(archivedir)/libstb-hal.git $(appsdir)/libstb-hal;\
	cp -ra $(appsdir)/libstb-hal $(appsdir)/libstb-hal.org
	for i in $(NEUTRINO_MP_LIBSTB_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		cd $(appsdir)/libstb-hal && patch -p1 -i $$i; \
	done;
	touch $@

$(appsdir)/libstb-hal/config.status: bootstrap
	cd $(appsdir)/libstb-hal && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--host=$(target) \
			--build=$(build) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/libstb-hal.do_compile: $(appsdir)/libstb-hal/config.status
	cd $(appsdir)/libstb-hal && \
		$(MAKE)
	touch $@

$(D)/libstb-hal: libstb-hal.do_prepare libstb-hal.do_compile
	$(MAKE) -C $(appsdir)/libstb-hal install DESTDIR=$(targetprefix)
	touch $@

libstb-hal-clean:
	rm -f $(D)/libstb-hal
	cd $(appsdir)/libstb-hal && \
		$(MAKE) distclean

libstb-hal-distclean:
	rm -f $(D)/libstb-hal
	rm -f $(D)/libstb-hal.do_compile
	rm -f $(D)/libstb-hal.do_prepare

#
# neutrino-mp
#
$(D)/neutrino-mp.do_prepare: | $(NEUTRINO_DEPS) libstb-hal
	rm -rf $(appsdir)/neutrino-mp
	rm -rf $(appsdir)/neutrino-mp.org
	[ -d "$(archivedir)/neutrino-mp.git" ] && \
	(cd $(archivedir)/neutrino-mp.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/neutrino-mp.git" ] || \
	git clone git://gitorious.org/neutrino-mp/max10s-neutrino-mp.git $(archivedir)/neutrino-mp.git; \
	cp -ra $(archivedir)/neutrino-mp.git $(appsdir)/neutrino-mp; \
	cp -ra $(appsdir)/neutrino-mp $(appsdir)/neutrino-mp.org
	touch $@

$(appsdir)/neutrino-mp/config.status:
	cd $(appsdir)/neutrino-mp && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--build=$(build) \
			--host=$(target) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--enable-giflib \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-stb-hal-includes=$(appsdir)/libstb-hal/include \
			--with-stb-hal-build=$(appsdir)/libstb-hal \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/neutrino-mp.do_compile: $(appsdir)/neutrino-mp/config.status
	cd $(appsdir)/neutrino-mp && \
		$(MAKE) all
	touch $@

$(D)/neutrino-mp: neutrino-mp.do_prepare neutrino-mp.do_compile
	$(MAKE) -C $(appsdir)/neutrino-mp install DESTDIR=$(targetprefix) && \
	rm -f $(targetprefix)/var/etc/.version
	make $(targetprefix)/var/etc/.version
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	$(target)-strip $(targetprefix)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-clean:
	rm -f $(D)/neutrino-mp
	cd $(appsdir)/neutrino-mp && \
		$(MAKE) distclean

neutrino-mp-distclean:
	rm -f $(D)/neutrino-mp
	rm -f $(D)/neutrino-mp.do_compile
	rm -f $(D)/neutrino-mp.do_prepare

neutrino-mp-updateyaud: neutrino-mp-clean neutrino-mp
	mkdir -p $(prefix)/release_neutrino/usr/local/bin
	cp $(targetprefix)/usr/local/bin/neutrino $(prefix)/release_neutrino/usr/local/bin/
	cp $(targetprefix)/usr/local/bin/pzapit $(prefix)/release_neutrino/usr/local/bin/
	cp $(targetprefix)/usr/local/bin/sectionsdcontrol $(prefix)/release_neutrino/usr/local/bin/
	mkdir -p $(prefix)/release_neutrino/usr/local/sbin
	cp $(targetprefix)/usr/local/sbin/udpstreampes $(prefix)/release_neutrino/usr/local/sbin/

################################################################################
#
# yaud-neutrino-mp-next
#
yaud-neutrino-mp-next: yaud-none lirc \
		boot-elf neutrino-mp-next release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

yaud-neutrino-mp-next-plugins: yaud-none lirc \
		boot-elf neutrino-mp-next neutrino-mp-plugins release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

yaud-neutrino-mp-next-all: yaud-none lirc \
		boot-elf neutrino-mp-next neutrino-mp-plugins shairport release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# libstb-hal-next
#
$(D)/libstb-hal-next.do_prepare:
	rm -rf $(appsdir)/libstb-hal-next
	rm -rf $(appsdir)/libstb-hal-next.org
	rm -rf $(LH_OBJDIR)
	[ -d "$(archivedir)/libstb-hal.git" ] && \
	(cd $(archivedir)/libstb-hal.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/libstb-hal.git" ] || \
	git clone git://gitorious.org/neutrino-hd/max10s-libstb-hal.git $(archivedir)/libstb-hal.git; \
	cp -ra $(archivedir)/libstb-hal.git $(appsdir)/libstb-hal-next;\
	(cd $(appsdir)/libstb-hal-next; git checkout next; cd "$(buildprefix)";); \
	cp -ra $(appsdir)/libstb-hal-next $(appsdir)/libstb-hal-next.org
	touch $@

$(D)/libstb-hal-next.config.status: bootstrap
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR) && \
	cd $(LH_OBJDIR) && \
		$(appsdir)/libstb-hal-next/autogen.sh && \
		$(BUILDENV) \
		$(appsdir)/libstb-hal-next/configure \
			--host=$(target) \
			--build=$(build) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"
	touch $@

$(D)/libstb-hal-next.do_compile: libstb-hal-next.config.status
	cd $(appsdir)/libstb-hal-next && \
		$(MAKE) -C $(LH_OBJDIR)

$(D)/libstb-hal-next: libstb-hal-next.do_prepare libstb-hal-next.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(targetprefix)
	touch $@

libstb-hal-next-clean:
	rm -f $(D)/libstb-hal-next
	cd $(LH_OBJDIR) && \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-next-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal-next*

#
# neutrino-mp-next
#
NEUTRINO_MP_NEXT_PATCHES =

$(D)/neutrino-mp-next.do_prepare: | $(NEUTRINO_DEPS) libstb-hal-next
	rm -rf $(appsdir)/neutrino-mp-next
	rm -rf $(appsdir)/neutrino-mp-next.org
	rm -rf $(N_OBJDIR)
	[ -d "$(archivedir)/neutrino-mp.git" ] && \
	(cd $(archivedir)/neutrino-mp.git; git pull; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/neutrino-mp.git" ] || \
	git clone git://gitorious.org/neutrino-mp/max10s-neutrino-mp.git $(archivedir)/neutrino-mp.git; \
	cp -ra $(archivedir)/neutrino-mp.git $(appsdir)/neutrino-mp-next; \
	(cd $(appsdir)/neutrino-mp-next; git checkout next; cd "$(buildprefix)";); \
	cp -ra $(appsdir)/neutrino-mp-next $(appsdir)/neutrino-mp-next.org
	for i in $(NEUTRINO_MP_NEXT_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		cd $(appsdir)/neutrino-mp-next && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/neutrino-mp-next.config.status:
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR) && \
	cd $(N_OBJDIR) && \
		$(appsdir)/neutrino-mp-next/autogen.sh && \
		$(BUILDENV) \
		$(appsdir)/neutrino-mp-next/configure \
			--build=$(build) \
			--host=$(target) \
			$(N_CONFIG_OPTS) \
			--enable-ffmpegdec \
			--enable-giflib \
			--with-boxtype=$(BOXTYPE) \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-stb-hal-includes=$(appsdir)/libstb-hal-next/include \
			--with-stb-hal-build=$(LH_OBJDIR) \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(appsdir)/neutrino-mp-next/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(appsdir)/libstb-hal-next ; then \
		pushd $(appsdir)/libstb-hal-next ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(appsdir)/neutrino-mp-next ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(buildprefix) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'-next_NMP-rev'$$NMP_REV'-next"' >> $@ ; \
	fi


$(D)/neutrino-mp-next.do_compile: neutrino-mp-next.config.status $(appsdir)/neutrino-mp-next/src/gui/version.h
	cd $(appsdir)/neutrino-mp-next && \
		$(MAKE) -C $(N_OBJDIR) all
	touch $@

$(D)/neutrino-mp-next: neutrino-mp-next.do_prepare neutrino-mp-next.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(targetprefix) && \
	rm -f $(targetprefix)/var/etc/.version
	make $(targetprefix)/var/etc/.version
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	$(target)-strip $(targetprefix)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-next-clean:
	rm -f $(D)/neutrino-mp-next
	rm -f $(appsdir)/neutrino-mp-next/src/gui/version.h
	cd $(N_OBJDIR) && \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-mp-next-distclean:
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-mp-next*

################################################################################
#
# yaud-neutrino-hd2-exp
#
yaud-neutrino-hd2-exp: yaud-none lirc \
		boot-elf neutrino-hd2-exp release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

yaud-neutrino-hd2-exp-plugins: yaud-none lirc \
		boot-elf neutrino-hd2-exp neutrino-mp-plugins release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# neutrino-hd2-exp
#
NEUTRINO_HD2_PATCHES =

$(D)/neutrino-hd2-exp.do_prepare: | $(NEUTRINO_DEPS) libflac
	rm -rf $(appsdir)/nhd2-exp
	rm -rf $(appsdir)/nhd2-exp.org
	[ -d "$(archivedir)/neutrino-hd2-exp.svn" ] && \
	(cd $(archivedir)/neutrino-hd2-exp.svn; svn up ; cd "$(buildprefix)";); \
	[ -d "$(archivedir)/neutrino-hd2-exp.svn" ] || \
	svn co http://neutrinohd2.googlecode.com/svn/branches/nhd2-exp $(archivedir)/neutrino-hd2-exp.svn; \
	cp -ra $(archivedir)/neutrino-hd2-exp.svn $(appsdir)/nhd2-exp; \
	cp -ra $(appsdir)/nhd2-exp $(appsdir)/nhd2-exp.org
	for i in $(NEUTRINO_HD2_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		cd $(appsdir)/nhd2-exp && patch -p1 -i $$i; \
	done;
	touch $@

$(appsdir)/nhd2-exp/config.status:
	cd $(appsdir)/nhd2-exp && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--build=$(build) \
			--host=$(target) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-isocodesdir=/usr/share/iso-codes \
			--enable-standaloneplugins \
			--enable-radiotext \
			--enable-upnp \
			--enable-scart \
			--enable-ci \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS) \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/neutrino-hd2-exp: neutrino-hd2-exp.do_prepare neutrino-hd2-exp.do_compile
	$(MAKE) -C $(appsdir)/nhd2-exp install DESTDIR=$(targetprefix) && \
	rm -f $(targetprefix)/var/etc/.version
	make $(targetprefix)/var/etc/.version
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	touch $@

$(D)/neutrino-hd2-exp.do_compile: $(appsdir)/nhd2-exp/config.status
	cd $(appsdir)/nhd2-exp && \
		$(MAKE) all
	touch $@

neutrino-hd2-exp-clean:
	rm -f $(D)/neutrino-hd2-exp
	cd $(appsdir)/nhd2-exp && \
		$(MAKE) clean

neutrino-hd2-exp-distclean:
	rm -f $(D)/neutrino-hd2-exp
	rm -f $(D)/neutrino-hd2-exp.do_compile
	rm -f $(D)/neutrino-hd2-exp.do_prepare

################################################################################
#
# yaud-old-neutrino
#
yaud-neutrino: yaud-none lirc \
		boot-elf neutrino release_neutrino
	@TUXBOX_YAUD_CUSTOMIZE@

#
# old neutrino
#
$(appsdir)/neutrino/config.status: bootstrap $(EXTERNALLCD_DEP) libfreetype libpng libid3tag openssl libcurl libmad libboost libgif ffmpeg_old
	cd $(appsdir)/neutrino && \
		./autogen.sh && \
		$(BUILDENV) \
		./configure \
			--build=$(build) \
			--host=$(target) \
			--without-libsdl \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/local/share \
			--with-fontdir=/usr/local/share/fonts \
			--with-configdir=/usr/local/share/config \
			--with-gamesdir=/usr/local/share/games \
			--with-plugindir=/usr/lib/tuxbox/plugins \
			PKG_CONFIG=$(hostprefix)/bin/pkg-config \
			PKG_CONFIG_PATH=$(targetprefix)/usr/lib/pkgconfig \
			$(PLATFORM_CPPFLAGS)

$(D)/neutrino.do_prepare:
	touch $@

$(D)/neutrino.do_compile: $(appsdir)/neutrino/config.status
	cd $(appsdir)/neutrino && \
		$(MAKE) all
	touch $@

$(D)/neutrino: neutrino.do_prepare neutrino.do_compile
	$(MAKE) -C $(appsdir)/neutrino install DESTDIR=$(targetprefix) DATADIR=$(targetprefix)/usr/local/share/
	$(target)-strip $(targetprefix)/usr/local/bin/neutrino
	$(target)-strip $(targetprefix)/usr/local/bin/pzapit
	$(target)-strip $(targetprefix)/usr/local/bin/sectionsdcontrol
	touch $@

neutrino-clean neutrino-distclean:
	rm -f $(D)/neutrino
	rm -f $(D)/neutrino.do_compile
	rm -f $(D)/neutrino.do_prepare
	cd $(appsdir)/neutrino && \
		$(MAKE) distclean
