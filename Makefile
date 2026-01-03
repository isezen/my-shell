# Makefile for my-shell project
# Provides convenient commands for linting, formatting, and testing

.PHONY: help lint lint-bash lint-fish format format-fish check install-hooks test clean

# Default target
.DEFAULT_GOAL := help

# Shell scripts to check
BASH_SCRIPTS := $(shell find . -name "*.sh" -not -path "./.git/*" -not -path "./docs/*")
FISH_SCRIPTS := $(shell find . -name "*.fish" -not -path "./.git/*" -not -path "./docs/*")

# Colors for output
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m

help: ## Show this help message
	@echo "$(COLOR_GREEN)my-shell Makefile Commands:$(COLOR_RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_YELLOW)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""

lint: lint-bash lint-fish ## Run all linting checks

lint-bash: ## Check bash/sh scripts with ShellCheck
	@echo "$(COLOR_GREEN)Checking bash/sh scripts with ShellCheck...$(COLOR_RESET)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck $(BASH_SCRIPTS) || exit 1; \
		echo "$(COLOR_GREEN)✓ All bash scripts passed ShellCheck$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ ShellCheck not found. Install with: brew install shellcheck$(COLOR_RESET)"; \
		exit 1; \
	fi

lint-fish: ## Check fish scripts syntax
	@echo "$(COLOR_GREEN)Checking fish scripts syntax...$(COLOR_RESET)"
	@if command -v fish >/dev/null 2>&1; then \
		for script in $(FISH_SCRIPTS); do \
			echo "Checking $$script..."; \
			fish -n "$$script" || exit 1; \
		done; \
		echo "$(COLOR_GREEN)✓ All fish scripts passed syntax check$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ fish not found. Please install fish shell$(COLOR_RESET)"; \
		exit 1; \
	fi

format: format-fish ## Format all scripts

format-fish: ## Format fish scripts with fish_indent
	@echo "$(COLOR_GREEN)Formatting fish scripts...$(COLOR_RESET)"
	@if command -v fish_indent >/dev/null 2>&1; then \
		for script in $(FISH_SCRIPTS); do \
			echo "Formatting $$script..."; \
			fish_indent -w "$$script"; \
		done; \
		echo "$(COLOR_GREEN)✓ Fish scripts formatted$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ fish_indent not found. Please install fish shell$(COLOR_RESET)"; \
		exit 1; \
	fi

check: lint ## Alias for lint (run all checks)

install-hooks: ## Install pre-commit hooks
	@echo "$(COLOR_GREEN)Installing pre-commit hooks...$(COLOR_RESET)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "$(COLOR_GREEN)✓ Pre-commit hooks installed$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ pre-commit not found. Install with: pip install pre-commit$(COLOR_RESET)"; \
		exit 1; \
	fi

test: lint ## Run tests (currently same as lint)
	@echo "$(COLOR_GREEN)Running tests...$(COLOR_RESET)"
	@$(MAKE) lint

clean: ## Clean temporary files
	@echo "$(COLOR_GREEN)Cleaning temporary files...$(COLOR_RESET)"
	@find . -type f -name "*.swp" -delete
	@find . -type f -name "*.swo" -delete
	@find . -type f -name "*~" -delete
	@find . -type f -name "*.bak" -delete
	@echo "$(COLOR_GREEN)✓ Cleaned$(COLOR_RESET)"

