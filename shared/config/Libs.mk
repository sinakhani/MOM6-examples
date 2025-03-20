# Configuration
BUILD ?=
TARGET ?=
CODEBASE ?=
MAKEFILE_IN ?= ../config/Makefile.in
CONFIGURE_AC ?=

# Potentially configurabe, but not yet sure if we want to allow this.
MAKEPATH = $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
M4DIR ?= $(MAKEPATH)/../../src/MOM6/ac/m4
MAKEDEP = $(MAKEPATH)/../../src/MOM6/ac/makedep

# `export` disables autoconf defaults; this restores them
CFLAGS ?= -g -O2
FCFLAGS ?= -g -O2

# Autoconf configuration
export CPPFLAGS
export CC
export MPICC
export CFLAGS
export FC
export MPIFC
export FCFLAGS
export LDFLAGS
export LIBS
export PYTHON
export SRCDIRS

# Verify that BUILD is not set to the current directory (which would clobber this Makefile)
ifeq ($(MAKEPATH), $(realpath $(BUILD)))
  $(error BUILD cannot be set to the current directory)
endif

# Disable builtin rules and variables
MAKEFLAGS += -rR

#----

all: $(BUILD)/$(TARGET)

$(BUILD)/$(TARGET): $(BUILD)/Makefile $(call rwildcard,$(CODEBASE),*.h *.c *.inc *.F90)
	$(MAKE) -C $(BUILD) $(TARGET)

FORCE:

$(BUILD)/Makefile: $(BUILD)/Makefile.in $(BUILD)/configure
	cd $(BUILD) && \
	  PATH="${PATH}:$(dir $(abspath $(MAKEDEP)))" \
	  ./configure \
	    --srcdir=$(abspath $(CODEBASE)) \
	    --config-cache

$(BUILD)/Makefile.in: $(MAKEFILE_IN) | $(BUILD)
	cp $(MAKEFILE_IN) $(BUILD)/Makefile.in

$(BUILD)/configure: $(BUILD)/configure.ac
	autoreconf $(BUILD)

$(BUILD)/configure.ac: $(CONFIGURE_AC) | $(BUILD)
	cp $(CONFIGURE_AC) $(BUILD)/configure.ac
	cp -r $(M4DIR) $(BUILD)

$(BUILD):
	mkdir -p $@

# Recursive wildcard (finds all files in $1 with suffixes in $2)
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

.PHONY: clean
clean:
	rm -rf $(BUILD)
