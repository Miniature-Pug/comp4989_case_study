# 2023-09-27 Manjot Randhawa

# delete the target of a rule if the rule fails and a command exits with non-zero exit status
.DELETE_ON_ERROR:
ifeq ($(UNAME), Darwin)
	SHELL := /bin/zsh
else
	SHELL := /usr/bin/bash
endif

#----------------
# global functions
error_logger      = $(error [ERROR] $1)
info_logger       = $(info [INFO] $1)
shell_variable    = $(shell which $1)
garbage_collector = $(foreach shit, $1, $(shell rm -rf ${shit} ||:))
#----------------

#----------------
# simple expansion variables
VENV_NAME   := venv
BASE_DIR    := $(shell pwd)
NUM_SAMPLES := 8

# executables
PYTHON3_LOCAL := $(call shell_variable, python3)
PIP3_LOCAL    := $(call shell_variable, pip3)
TERRAFORM     := $(call shell_variable, terraform)
ZIP           := $(call shell_variable, zip)

# venv executables
PYTHON3 := ./$(VENV_NAME)/bin/python3
PIP3    := ./$(VENV_NAME)/bin/pip3
J2      := ./$(VENV_NAME)/bin/j2

# files
GENERATE_TEMPLATE_SCRIPT := $(BASE_DIR)/.pipeline/scripts/python/generate_temnplate.py
LAMBDA_ZIP               := $(BASE_DIR)/.pipeline/terraform/lambda_function.zip
LAMBDA_FUNCTION          := $(BASE_DIR)/src/be/serverless/lambda/lambda_function.py

# dir
TERRAFORM_DIR              := $(BASE_DIR)/.pipeline/terraform
TEMPLATE_FOLDER            := $(BASE_DIR)/.pipeline/templates
SAMPLE_HTML_OUTPUT_FOLDER  := $(BASE_DIR)/src/fe/html
INDEX_HTML_OUTPUT_FOLDER   := $(BASE_DIR)/src/fe
LAMBDA_DEPENDENCIES        := $(BASE_DIR)/$(VENV_NAME)/lib/python3.10/site-packages
#----------------

#----------------
# recipes

prep-virtual-environment:
	@$(call info_logger, Preparing python virtual environment)
	$(PYTHON3_LOCAL) -m venv ./$(VENV_NAME)
	$(PIP3) install -r $(BASE_DIR)/requirements.txt

zip-lambda-dependencies:
	@$(call info_logger, Zipping lambda function dependencies)
	cd $(LAMBDA_DEPENDENCIES) && $(ZIP) -r $(LAMBDA_ZIP) .
	$(ZIP) -j $(LAMBDA_ZIP) $(LAMBDA_FUNCTION)

generate-index-page:
	@$(call info_logger, Generating index HTML page)
	$(PYTHON3) $(GENERATE_TEMPLATE_SCRIPT) --template-folder $(TEMPLATE_FOLDER) --index-html-output-folder $(INDEX_HTML_OUTPUT_FOLDER) --num-sample-links $(NUM_SAMPLES) --index-html

generate-sample-pages:
	@$(call info_logger, Generating sample HTML pages)
	$(PYTHON3) $(GENERATE_TEMPLATE_SCRIPT) --template-folder $(TEMPLATE_FOLDER) --sample-html-output-folder $(SAMPLE_HTML_OUTPUT_FOLDER) --sample-html-number $(NUM_SAMPLES) --sample-html

tf-init:
	@$(call info_logger, Terrafomr Init)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) init

tf-fmt:
	@$(call info_logger, Terrafomr Format)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) fmt --recursive

tf-plan: prep-virtual-environment zip-lambda-dependencies
	@$(call info_logger, Terrafomr plan)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) plan -lock-timeout=5m

tf-apply: clean-virtualenv clean-zip prep-virtual-environment zip-lambda-dependencies
	@$(call info_logger, Terrafomr apply)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) apply --auto-approve -lock-timeout=5m

tf-destroy: prep-virtual-environment zip-lambda-dependencies
	@$(call info_logger, Terrafomr Destroy)
	cd $(TERRAFORM_DIR) && $(TERRAFORM) destroy --auto-approve -lock-timeout=5m

# cleanup
clean-virtualenv: garbage := "$(VENV_NAME)"
clean-virtualenv:
	@$(call info_logger, Cleaning python virtual environment)
	@$(call garbage_collector, $(garbage))

clean-zip: garbage := "$(LAMBDA_ZIP)"
clean-zip:
	@$(call info_logger, Cleaning lambda zip file)
	@$(call garbage_collector, $(garbage))

clean-samples: garbage := "sample"
clean-samples:
	@for i in $$(seq 0 $(NUM_SAMPLES)); do \
		rm -rf "$(SAMPLE_HTML_OUTPUT_FOLDER)/sample_$$i.html"; \
	done
	rm -rf "$(INDEX_HTML_OUTPUT_FOLDER)/index.html"; \

# master commands
clean: clean-virtualenv
	@$(call info_logger, Master Janitor cleaned up your garbage.)
