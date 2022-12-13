# Copyright 2020 SkyWater PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

# The top directory where environment will be created.
TOP_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# A pip `requirements.txt` file.
# https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format
REQUIREMENTS_FILE := requirements.txt

# A conda `environment.yml` file.
# https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html
ENVIRONMENT_FILE := environment.yml

$(TOP_DIR)/third_party/make-env/conda.mk: $(TOP_DIR)/.gitmodules
	cd $(TOP_DIR); git submodule update --init third_party/make-env

-include $(TOP_DIR)/third_party/make-env/conda.mk

.DEFAULT_GOAL := all

FULL_VERSION := $(shell git describe --long)
TAG_VERSION  := $(firstword $(subst -, ,$(FULL_VERSION)))

RST_SRC = $(shell find -name *.src.rst)
RST_OUT = $(RST_SRC:.src.rst=.rst)

%.rst: %.src.rst $(TOP_DIR)/docs/*.rst Makefile | $(CONDA_ENV_PYTHON)
	@rm -f $@
	$(IN_CONDA_ENV) rst_include include $< - \
		| sed \
			-e's@|TAG_VERSION|@$(TAG_VERSION)@g' \
			-e's@:ref:`Versioning Information`@`Versioning Information <docs/versioning.rst>`_@g' \
			-e's@:ref:`Known Issues`@`Known Issues <docs/known_issues.rst>`_@g' \
			-e's@.. warning::@*Warning*@g' \
		> $@

update-rst:
	@echo Found $(RST_SRC) source files.
	@touch $(RST_SRC)
	make $(RST_OUT)


COPYRIGHT_HOLDER := SkyWater PDK Authors
FIND := find . -path ./env -prune -o -path ./.git -prune -o -path ./third_party -prune -o
ADDLICENSE := addlicense -f ./docs/license_header.txt
fix-licenses:
	@# Makefiles
	@$(FIND) -type f -name Makefile -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@$(FIND) -type f -name \*.mk -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@# Scripting files
	@$(FIND) -type f -name \*.sh -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@$(FIND) -type f -name \*.py -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@# Configuration files
	@$(FIND) -type f -name \*.yml  -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+

.PHONY: fix-licenses

check-licenses:
	@make --no-print-directory ADDLICENSE_EXTRA=--check fix-licenses

.PHONY: check-licenses

lint-python: | $(CONDA_ENV_PYTHON)
	@echo "Found python files:"
	@$(FIND) -type f -name *.py -print | sed -e's/^/  /'
	@echo
	@$(IN_CONDA_ENV) $(FIND) -type f -name *.py -exec flake8 \{\} \+ || echo
	@$(IN_CONDA_ENV) $(FIND) -type f -name *.py -exec flake8 --quiet --count --statistics \{\} \+

.PHONY: lint-python

check: check-licenses lint-python
	@true

all: README.rst
	@true


.PHONY: all
