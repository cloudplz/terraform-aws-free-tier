.PHONY: diagram help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

diagram: ## Render architecture diagram from Mermaid source to SVG
	npx -y -p @mermaid-js/mermaid-cli mmdc -i docs/architecture.mmd -o docs/architecture.svg -t default
