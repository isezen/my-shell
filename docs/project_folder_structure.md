```text
.
├── codex
├── docs
│   ├── issues
│   │   └── fish-non-interactive-breakage.md
│   ├── ACTIVATION_SPECIFICATION.md
│   ├── LL_SPECS.md
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
│   │   ├── ll_common.awk
│   │   ├── ll_linux
│   │   ├── ll_linux.awk
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
│   ├── fixtures
│   │   └── ll_baseline
│   │       ├── ll_linux
│   │       │   ├── 001_default.out
│   │       │   ├── 002_d.out
│   │       │   ├── 003_directory.out
│   │       │   ├── 004_d.out
│   │       │   ├── 005_g.out
│   │       │   ├── 006_g.out
│   │       │   ├── 007_o.out
│   │       │   ├── 008_no_group.out
│   │       │   ├── 009_g_g.out
│   │       │   ├── 010_s.out
│   │       │   ├── 011_size.out
│   │       │   ├── 012_h.out
│   │       │   ├── 013_human_readable.out
│   │       │   ├── 014_si.out
│   │       │   ├── 015_n.out
│   │       │   ├── 016_numeric_uid_gid.out
│   │       │   ├── 017_s_h.out
│   │       │   ├── 018_s_si.out
│   │       │   ├── 019_n_h.out
│   │       │   ├── 020_n_si.out
│   │       │   ├── 021_s_g.out
│   │       │   ├── 022_s_h_g_g.out
│   │       │   ├── 023_file_then_no_group.out
│   │       │   ├── 024_file_then_g.out
│   │       │   ├── 025_no_group_then_file.out
│   │       │   ├── 026_h_file1_txt.out
│   │       │   ├── 027_no_group_file2_txt.out
│   │       │   ├── 028_space_filename.out
│   │       │   ├── 029_leading_space_filename.out
│   │       │   ├── 030_tab_filename.out
│   │       │   ├── 031_unicode_filename.out
│   │       │   ├── 032_symlink.out
│   │       │   ├── 033_broken_symlink.out
│   │       │   ├── 034_fifo.out
│   │       │   ├── 035_setuid_file.out
│   │       │   ├── 036_setgid_file.out
│   │       │   ├── 037_setgid_dir.out
│   │       │   ├── 038_sticky_dir.out
│   │       │   ├── 039_mtime_now_1s.out
│   │       │   ├── 040_mtime_now_119s.out
│   │       │   ├── 041_mtime_now_120s.out
│   │       │   ├── 042_mtime_now_3599s.out
│   │       │   ├── 043_mtime_now_3600s.out
│   │       │   ├── 044_mtime_now_2days.out
│   │       │   ├── 045_mtime_now_3yr.out
│   │       │   ├── 046_mtime_now_35yr.out
│   │       │   ├── 047_mtime_now_125yr.out
│   │       │   ├── 048_symlink_target_space.out
│   │       │   ├── 049_symlink_target_tab.out
│   │       │   ├── 050_symlink_all_in_one_dir.out
│   │       │   ├── 051_future_only.out
│   │       │   └── 052_mixed_time_width.out
│   │       └── ll_macos
│   │           ├── 001_default.out
│   │           ├── 002_d.out
│   │           ├── 003_directory.out
│   │           ├── 004_d.out
│   │           ├── 005_g.out
│   │           ├── 006_g.out
│   │           ├── 007_o.out
│   │           ├── 008_no_group.out
│   │           ├── 009_g_g.out
│   │           ├── 010_s.out
│   │           ├── 011_size.out
│   │           ├── 012_h.out
│   │           ├── 013_human_readable.out
│   │           ├── 014_si.out
│   │           ├── 015_n.out
│   │           ├── 016_numeric_uid_gid.out
│   │           ├── 017_s_h.out
│   │           ├── 018_s_si.out
│   │           ├── 019_n_h.out
│   │           ├── 020_n_si.out
│   │           ├── 021_s_g.out
│   │           ├── 022_s_h_g_g.out
│   │           ├── 023_file_then_no_group.out
│   │           ├── 024_file_then_g.out
│   │           ├── 025_no_group_then_file.out
│   │           ├── 026_h_file1_txt.out
│   │           ├── 027_no_group_file2_txt.out
│   │           ├── 028_space_filename.out
│   │           ├── 029_leading_space_filename.out
│   │           ├── 030_tab_filename.out
│   │           ├── 031_unicode_filename.out
│   │           ├── 032_symlink.out
│   │           ├── 033_broken_symlink.out
│   │           ├── 034_fifo.out
│   │           ├── 035_setuid_file.out
│   │           ├── 036_setgid_file.out
│   │           ├── 037_setgid_dir.out
│   │           ├── 038_sticky_dir.out
│   │           ├── 039_mtime_now_1s.out
│   │           ├── 040_mtime_now_119s.out
│   │           ├── 041_mtime_now_120s.out
│   │           ├── 042_mtime_now_3599s.out
│   │           ├── 043_mtime_now_3600s.out
│   │           ├── 044_mtime_now_2days.out
│   │           ├── 045_mtime_now_3yr.out
│   │           ├── 046_mtime_now_35yr.out
│   │           ├── 047_mtime_now_125yr.out
│   │           ├── 048_symlink_target_space.out
│   │           ├── 049_symlink_target_tab.out
│   │           ├── 050_symlink_all_in_one_dir.out
│   │           ├── 051_future_only.out
│   │           └── 052_mixed_time_width.out
│   ├── ll
│   │   ├── fixtures
│   │   │   └── ll_stub_impl.bash
│   │   ├── 10_wrapper_stub.bats
│   │   └── 20_baseline_snapshot.bats
│   ├── ll_linux
│   │   ├── 00_harness.bash
│   │   ├── 00_harness.bash.bak
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
│   ├── bench_awk_from_stat.sh
│   ├── bench_stat.sh
│   ├── bench_stat_glob.sh
│   ├── benchmark.sh
│   ├── git.diff
│   ├── ll_current_state_report.md
│   ├── ll_macos_perf_after.md
│   ├── ll_macos_perf_analysis.md
│   ├── ll_macos_perf_baseline.md
│   ├── ll_macos_perf_final_report.md
│   ├── ll_macos_specs.md
│   ├── test-gls-symlink-resolve.sh
│   ├── test-gls.txt
│   └── todo.md
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── colortable.sh
├── CONTRIBUTING.md
├── install.sh
├── LICENSE
├── Makefile
├── README.md
└── REQUIREMENTS.md

24 directories, 185 files
```