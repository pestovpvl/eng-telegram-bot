WORDS_DIR ?= data/words

.PHONY: import-all

import-all:
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
		task="import:words[$$pack,$$file]"; \
		bundle exec rake "$$task"; \
	done
