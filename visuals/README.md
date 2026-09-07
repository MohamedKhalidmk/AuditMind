# AuditMind

Smart contract vulnerability detection. Solidity contracts are routed through static analysis and
LLM reasoning; this repo contains the benchmark that decided how the first stage should work.

**The question:** for a first-pass triage lane, is a static analyser or a fast LLM the better detector?

**The answer:** neither. They have near-disjoint blind spots, and routing each category to whichever
tool handles it beats both.

---

## Notebooks

| | |
|---|---|
| [`01_data_engineering.ipynb`](notebooks/01_data_engineering.ipynb) | Builds the corpus from four sources, audits labels, strips comments, freezes and hashes it |
| [`02_comparison.ipynb`](notebooks/02_comparison.ipynb) | Runs Slither and Claude Haiku over the frozen corpus, scores every arm |
| [`03_analysis.ipynb`](notebooks/03_analysis.ipynb) | Loads the scores and plots them |

---

## Corpus

723 files, frozen and SHA256-hashed in `data/manifests/frozen_corpus_record.json`.

| source | corpus | scored |
|---|---|---|
| SmartBugs-curated | 116 | 105 |
| SWC Registry | 13 | 10 |
| DAppSCAN | 83 | 67 |
| clean (OpenZeppelin, Aave v3, Seaport, Uniswap v4, Comet, Morpho, Solmate, 1inch, Yearn) | 511 | 485 |
| **total** | **723** | **667** |

Five scored categories: reentrancy, access control, unchecked low-level calls, denial of service,
time manipulation.

Two exclusions, applied to **both** tools so neither gets credit on a file its competitor never saw:
11 `bad_randomness` files fall outside the five categories, and 45 files Slither could not analyse
after a successful compile.

<img src="visuals/SmartBugs_dataset.png" width="70%">
<img src="visuals/SWC_Registry_dataset.png" width="70%">
<img src="visuals/DAppSCAN_dataset.png" width="70%">
<img src="visuals/clean_dataset.png" width="70%">

---

## Arms

Slither ran once; its raw JSON is stored unparsed, so detector-to-category mapping happens at
scoring time and stays revisable. Haiku ran at temperature 0 through the Batch API, with the prompts
reproduced verbatim in `data/manifests/`.

| arm | what it is |
|---|---|
| Slither H/M | High and Medium severity findings only |
| Slither all | every severity, including Low and Informational |
| Haiku multi-label | all five categories judged independently |
| Haiku forced choice | one category or `none` |
| Routed | Slither for reentrancy and unchecked calls, Haiku forced for the other three |

**Severity matters more than it looks.** Several detectors that map to these categories only ever
fire at Low or Informational — `timestamp` on almost any `block.timestamp` use, `low-level-calls`
meaning a call merely exists. Under High/Medium, denial of service and time manipulation have **no
qualifying detector at all**, so Slither scores zero there by construction rather than by weakness.

---

## Results

Macro over five categories, 182 vulnerable and 485 clean files.

| arm | precision | recall | F1 | flagged on clean | exact localization |
|---|---|---|---|---|---|
| Slither H/M | 0.31 | 0.40 | 0.35 | **1.9%** | 0.80 |
| Slither all | 0.28 | 0.68 | 0.39 | 10.7% | 0.85 |
| Haiku multi-label | 0.31 | **0.83** | 0.43 | 19.4% | 0.87 |
| Haiku forced choice | 0.49 | 0.57 | 0.48 | 12.6% | 0.69 |
| **Routed** | **0.53** | 0.69 | **0.56** | 7.2% | **0.91** |

<img src="visuals/per_category_f1.png" width="90%">

The tools own opposite halves. Slither takes reentrancy (0.73) and unchecked calls (0.83); Haiku
takes access control (0.49), denial of service (0.38) and time manipulation (0.40). Neither comes
close on the other's categories.

<img src="visuals/routed_per_category.png" width="90%">

Routing matches the better tool in every column, which is why it wins on macro F1 without the
precision cost of unioning the two.

### False positives on clean code

<img src="visuals/clean_false_positives.png" width="90%">

The number that decides production use. Slither H/M fires on 1.9% of clean files, Haiku multi-label
on 19.4%. Routing lands at 7.2%, and inverts the shape of the noise: reentrancy drops to a single
clean file because Slither answers it there.

### Precision is partly an artefact of the ground truth

<img src="visuals/forced_vs_multilabel.png" width="90%">

70% of Haiku's multi-label false positives are on *vulnerable* files, flagged with a category the
label omits — and 178 of 182 vulnerable files carry exactly one label. Constraining the output to
one answer nearly doubles precision (0.31 to 0.49) without changing the model. Neither figure is the
truth; together they bracket it.

### Academic corpora flatter both tools

<img src="visuals/by_source.png" width="90%">

Every arm loses more than half its F1 moving from SmartBugs to DAppSCAN. That cross-source drop is
larger than any gap between the tools.

---

## Caveats

**The routing rule was chosen after seeing which categories each tool won**, on 182 vulnerable files
with two categories at n=16 and n=22. That is selection on the test set and 0.56 is optimistic. What
defends it is that the split follows the syntactic/semantic line you would predict in advance, and
Slither's zero on two categories is structural.

**DAppSCAN is the source most like real audited code and the weakest evidence here.** 403 files were
compile-checked, 89 survived, 67 were scored. The survivors are the simpler import graphs.

**Temperature 0 is near-deterministic, not deterministic.** 96 of 99 triplicated files returned
identical verdicts, so single-call results carry roughly a 3% chance of a category flipping.

---

## Running it

Requires solc 0.4.26 through 0.8.28 via `solc-select`, Foundry (`forge` — several clean-pool repos
ship a `foundry.toml` and Slither shells out to it), and both OpenZeppelin v4 and v5 under
`node_modules_oz*`.

Slither reads the original nested source trees, which are not in this repo — its output is already in
`data/stage2_results/slither_results.json`, and `03_analysis.ipynb` needs only `data/stage3_scored/`.

Total Haiku spend across all arms: about $5 at Batch API rates.
