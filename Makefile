WORDS_DIR ?= data/words
# Expected filenames: top500.csv, top1000.csv, top2000.csv, function_words*.csv, content_words*.csv.

.PHONY: import-all import-all-local

import-all:
	@if [ -f /.dockerenv ]; then \
		$(MAKE) import-all-local; \
	else \
		docker compose exec app make import-all-local; \
	fi

import-all-local:
	@set -e; \
	if [ ! -d "$(WORDS_DIR)" ]; then \
		echo "Words dir not found: $(WORDS_DIR)"; exit 1; \
	fi; \
	for file in $(WORDS_DIR)/*.csv; do \
		[ -f "$$file" ] || continue; \
		base=$$(basename "$$file" .csv); \
		case "$$base" in \
			function_words* ) pack=function ;; \
			content_words* ) pack=content ;; \
			* ) pack="$$base" ;; \
		esac; \
		echo "Importing $$file as $$pack"; \
		task=$$(printf 'import:words[%s,%s]' "$$pack" "$$file"); \
		bundle exec rake "$$task"; \
	done
