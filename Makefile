# 2023-09-27 Manjot Randhawa

# delete the target of a rule if the rule fails and a command exits with non-zero exit status
.DELETE_ON_ERROR:
SHELL := /usr/bin/bash

#----------------
# global functions
error_logger      = $(error [ERROR] $1)
info_logger       = $(info [INFO] $1)
shell_variable    = $(shell which $1)
garbage_collector = $(foreach shit, $1, $(shell rm -rf ${shit} ||:))
#----------------

#----------------
# simple expansion variables
VENV_NAME  := venv
BASE_DIR   := $(shell pwd)

# executables
PYTHON3_LOCAL := $(call shell_variable, python3)
PIP3_LOCAL    := $(call shell_variable, pip3)
TERRAFORM     := $(call shell_variable, terraform)

# venv executables
PYTHON3 := ./$(VENV_NAME)/bin/python3
PIP3    := ./$(VENV_NAME)/bin/pip3
J2      := ./$(VENV_NAME)/bin/j2

# files
GENERATE_TEMPLATE_SCRIPT := $(BASE_DIR)/.pipeline/scripts/python/generate_temnplate.py

# dir
TERRAFORM_DIR              := $(BASE_DIR)/.pipeline/terraform
TEMPLATE_FOLDER            := $(BASE_DIR)/.pipeline/templates
SAMPLE_HTML_OUTPUT_FOLDER  := $(BASE_DIR)/src/fe/html
INDEX_HTML_OUTPUT_FOLDER   := $(BASE_DIR)/src/fe
#----------------

#----------------
# recipes

prep-virtual-environment:
	@$(call info_logger, Preparing python virtual environment)
	$(PYTHON3_LOCAL) -m venv ./$(VENV_NAME)
	$(PIP3) install -r $(BASE_DIR)/requirements.txt

generate-index-page:
	@$(call info_logger, Generating index HTML page)
	$(PYTHON3) $(GENERATE_TEMPLATE_SCRIPT) --template-folder $(TEMPLATE_FOLDER) --index-html-output-folder $(INDEX_HTML_OUTPUT_FOLDER) --num-sample-links 9 --index-html

generate-sample-pages:
	@$(call info_logger, Generating sample HTML pages)
	$(PYTHON3) $(GENERATE_TEMPLATE_SCRIPT) --template-folder $(TEMPLATE_FOLDER) --sample-html-output-folder $(SAMPLE_HTML_OUTPUT_FOLDER) --sample-html-number 9 --sample-html

tf-init:
	@$(call info_logger, Terrafomr Init)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) init

tf-fmt:
	@$(call info_logger, Terrafomr Format)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) fmt --recursive

tf-plan:
	@$(call info_logger, Terrafomr plan)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) plan -lock-timeout=5m

tf-apply:
	@$(call info_logger, Terrafomr apply)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) apply --auto-approve -lock-timeout=5m

tf-destroy:
	@$(call info_logger, Terrafomr Destroy)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) destroy --auto-approve -lock-timeout=5m

# cleanup
clean-virtualenv: garbage := "$(VENV_NAME)"
clean-virtualenv:
	@$(call info_logger, Cleaning python virtual environment)
	@$(call garbage_collector, $(garbage))

# master commands
clean: clean-virtualenv
	@$(call info_logger, Master Janitor cleaned up your garbage.)
