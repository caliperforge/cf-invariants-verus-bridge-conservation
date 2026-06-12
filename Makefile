# cf-invariants-verus-bridge-conservation — paired campaign runner
#
# `make install`          — forge install deps
# `make build`            — forge build
# `make foundry`          — forge-side CryticToFoundry smoke + replay
# `make clean-campaign`   — echidna against CryticCleanTester (expect 0 violations)
# `make planted-campaign` — echidna against CryticPlantedTester (expect ≥1)
# `make scorecard`        — re-render scorecard from the most recent capture
# `make wipe`             — wipe corpus + capture dirs

.PHONY: install build foundry clean-campaign planted-campaign scorecard wipe help

CAPTURE_DIR := .campaign-out
FINDINGS_BASE := findings/INV-CONS-bridge-balance

help:
	@echo "cf-invariants-verus-bridge-conservation make targets:"
	@echo "  install            forge install deps"
	@echo "  build              forge build"
	@echo "  foundry            CryticToFoundry replay + smoke"
	@echo "  clean-campaign     echidna on CryticCleanTester (expect 0 violations)"
	@echo "  planted-campaign   echidna on CryticPlantedTester (expect >=1)"
	@echo "  scorecard          re-render scorecard from latest capture"
	@echo "  wipe               clean corpus + capture dirs"

install:
	forge install foundry-rs/forge-std@v1.9.4
	forge install Recon-Fuzz/chimera@463c0d4134931de315234be94eb21f1f032ea138

build:
	forge build

foundry:
	forge test --match-path test/recon/CryticToFoundry.sol -vvv

clean-campaign: build
	@mkdir -p $(CAPTURE_DIR)
	echidna . --contract CryticCleanTester --config echidna-clean.yaml \
		2>&1 | tee $(CAPTURE_DIR)/echidna-clean.out
	@mkdir -p $(FINDINGS_BASE)/clean
	./scripts/capture_scorecard.sh \
		--campaign echidna --leg clean \
		--invariant INV-CONS-bridge-balance \
		--input $(CAPTURE_DIR)/echidna-clean.out \
		--out-dir $(FINDINGS_BASE)/clean

planted-campaign: build
	@mkdir -p $(CAPTURE_DIR)
	echidna . --contract CryticPlantedTester --config echidna-planted.yaml \
		2>&1 | tee $(CAPTURE_DIR)/echidna-planted.out || true
	@mkdir -p $(FINDINGS_BASE)/planted
	./scripts/capture_scorecard.sh \
		--campaign echidna --leg planted \
		--invariant INV-CONS-bridge-balance \
		--input $(CAPTURE_DIR)/echidna-planted.out \
		--out-dir $(FINDINGS_BASE)/planted

scorecard:
	@echo "Re-rendering scorecards from $(CAPTURE_DIR)/echidna-{clean,planted}.out"
	@./scripts/capture_scorecard.sh \
		--campaign echidna --leg clean \
		--invariant INV-CONS-bridge-balance \
		--input $(CAPTURE_DIR)/echidna-clean.out \
		--out-dir $(FINDINGS_BASE)/clean || true
	@./scripts/capture_scorecard.sh \
		--campaign echidna --leg planted \
		--invariant INV-CONS-bridge-balance \
		--input $(CAPTURE_DIR)/echidna-planted.out \
		--out-dir $(FINDINGS_BASE)/planted || true

wipe:
	rm -rf $(CAPTURE_DIR) echidna-corpus-clean echidna-corpus-planted crytic-export out cache
