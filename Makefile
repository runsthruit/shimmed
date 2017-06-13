# /dev/null/make

# Disable built-in implicit rules.
.SUFFIXES:

# What to install to bindir.
OPTBASE  = shimmed
OPTSRCS  = $(wildcard *.bash)

# Init path variables.
OPTDIR  ?= /opt
OPTTGTD  = $(OPTDIR)/$(OPTBASE)
OPTTGTS  = $(addprefix $(OPTDIR)/$(OPTBASE)/,$(basename $(OPTSRCS)))

# Init commands.
MKDIR    = mkdir -vp
INSTALL  = install -vp
RM       = rm -vf
RMDIR    = rmdir -p

# By default, show help.
.DEFAULT_GOAL	:=	help

# HELP
.PHONY:		help usage
help:
	@echo "USAGE:"
	@echo "    make install"
	@echo "    make uninstall"
	@echo "ALT:"
	@echo "    make OPTDIR=~/.opt install"
usage:	help

# Generate install targets.
OPT_template = $(OPTTGTD)/$(basename $(1)): $(1); @$(INSTALL) $(1) $(OPTTGTD)/$(basename $(1))
$(foreach OPTSRC,$(OPTSRCS),$(eval $(call OPT_template,$(OPTSRC))))

# Install / Uninstall
install:	$(OPTTGTD) $(OPTTGTS)

$(OPTTGTD):
	@$(MKDIR) $(OPTTGTD)

uninstall:
	@$(RM) $(OPTTGTS)
	@$(RMDIR) $(OPTTGTD)
