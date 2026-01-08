```text
.
├── codex
│   ├── snapshots
│   │   ├── env
│   │   │   ├── activate
│   │   │   ├── activate.bash
│   │   │   ├── activate.fish
│   │   │   └── activate.zsh
│   │   ├── scripts
│   │   │   └── bin
│   │   │       ├── dus
│   │   │       ├── dusf
│   │   │       ├── dusf.
│   │   │       ├── ll
│   │   │       ├── ll_linux
│   │   │       └── ll_macos
│   │   ├── shell
│   │   │   ├── bash
│   │   │   │   ├── aliases.bash
│   │   │   │   ├── env.bash
│   │   │   │   ├── init.bash
│   │   │   │   └── prompt.bash
│   │   │   ├── fish
│   │   │   │   ├── aliases.fish
│   │   │   │   ├── env.fish
│   │   │   │   ├── init.fish
│   │   │   │   └── prompt.fish
│   │   │   └── zsh
│   │   │       ├── aliases.zsh
│   │   │       ├── env.zsh
│   │   │       ├── init.zsh
│   │   │       └── prompt.zsh
│   │   ├── tests
│   │   │   ├── ll
│   │   │   │   └── 10_wrapper_stub.bats
│   │   │   ├── ll_linux
│   │   │   │   ├── 00_harness.bash
│   │   │   │   └── 10_core.bats
│   │   │   └── ll_macos
│   │   │       ├── 00_harness.bash
│   │   │       └── 10_core.bats
│   │   ├── install.sh
│   │   ├── Makefile
│   │   └── missing.txt
│   ├── bats-ll-macos.txt
│   ├── bats-ll-wrapper.txt
│   ├── codex-control.md
│   ├── file-tree.txt
│   ├── ll-wrapper-evidence.md
│   ├── make-test-after.txt
│   ├── make-test-before.txt
│   ├── make-tests.txt
│   ├── repo-meta.txt
│   ├── scripts-bin.txt
│   ├── shellcheck-after.txt
│   ├── shellcheck-before.txt
│   ├── shellcheck-files.txt
│   ├── shellcheck-fixed.txt
│   ├── shellcheck-invocations.md
│   ├── shellcheck-invocations.raw
│   ├── shellcheck-root-cause.md
│   ├── shellcheck.txt
│   ├── test-count-by-file.txt
│   ├── test-count.txt
│   ├── test-entrypoints.txt
│   └── tooling.txt
├── docs
│   ├── ACTIVATION_SPECIFICATION.md
│   ├── proj_summary.md
│   └── project_folder_structure.md
├── env
│   ├── activate
│   ├── activate.bash
│   ├── activate.fish
│   └── activate.zsh
├── scripts
│   ├── bin
│   │   ├── dus
│   │   ├── dusf
│   │   ├── dusf.
│   │   ├── ll
│   │   ├── ll_linux
│   │   └── ll_macos
│   └── dev
│       ├── ll-compare
│       ├── ll-perf
│       ├── ls-compare
│       ├── ls-compare-canon-ls.pl
│       ├── ls-compare-canon-script.pl
│       └── run-shellcheck
├── shell
│   ├── bash
│   │   ├── aliases.bash
│   │   ├── env.bash
│   │   ├── init.bash
│   │   └── prompt.bash
│   ├── fish
│   │   ├── aliases.fish
│   │   ├── env.fish
│   │   ├── init.fish
│   │   └── prompt.fish
│   ├── zsh
│   │   ├── aliases.zsh
│   │   ├── env.zsh
│   │   ├── init.zsh
│   │   └── prompt.zsh
│   └── aliases.yml
├── tests
│   ├── ll
│   │   ├── fixtures
│   │   │   └── ll_stub_impl.bash
│   │   └── 10_wrapper_stub.bats
│   ├── ll_linux
│   │   ├── 00_harness.bash
│   │   ├── 10_core.bats
│   │   ├── 20_paths.bats
│   │   ├── 30_edge.bats
│   │   └── 40_color.bats
│   ├── ll_macos
│   │   ├── 00_harness.bash
│   │   └── 10_core.bats
│   ├── test_helper
│   │   ├── bats-assert
│   │   │   └── load.bash
│   │   └── bats-support
│   │       └── load.bash
│   ├── alias-sync.bats
│   ├── alias.bats
│   ├── bash.bats
│   ├── install.bats
│   ├── README.md
│   ├── scripts_dus.bats
│   ├── scripts_ll.bats
│   └── TEST_COVERAGE.md
├── wip
│   ├── IMPROVEMENTS.md
│   ├── ll-before.md
│   ├── ll-decision.md
│   ├── ll-perf.md
│   ├── ls-compare.md
│   └── todo.md
├── CHANGELOG.md
├── colortable.sh
├── CONTRIBUTING.md
├── install.sh
├── LICENSE
├── Makefile
├── plan-ll-control.md
├── README.md
└── REQUIREMENTS.md

31 directories, 118 files
```