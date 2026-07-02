#!/bin/sh
set -eu

TEST_SH="${PHONECODE_TEST_SH:-sh}"

"$TEST_SH" -n scripts/install.sh
"$TEST_SH" -n scripts/setup.sh
"$TEST_SH" scripts/install.sh --dry-run --profile minimal --yes >/tmp/phonecode-test-minimal.log
"$TEST_SH" scripts/install.sh --dry-run --profile recommended --yes >/tmp/phonecode-test-recommended.log
"$TEST_SH" scripts/install.sh --dry-run --profile repair --yes >/tmp/phonecode-test-repair.log
printf 'n\n' | "$TEST_SH" scripts/install.sh --dry-run --profile custom >/tmp/phonecode-test-custom-no-ubuntu.log
NO_COLOR=1 "$TEST_SH" scripts/install.sh --dry-run --profile minimal --yes >/tmp/phonecode-test-plain.log

grep -q "PhoneCode is installing" /tmp/phonecode-test-minimal.log
grep -q "code from your phone" /tmp/phonecode-test-plain.log
grep -q "dry-run" /tmp/phonecode-test-minimal.log
grep -q "Terminal name:        root" /tmp/phonecode-test-minimal.log
grep -q "Git identity:         PhoneCode User <user@phonecode.local>" /tmp/phonecode-test-minimal.log
grep -q "create/update only if PhoneCode owns it" /tmp/phonecode-test-minimal.log
grep -q "  ocode --auto" /tmp/phonecode-test-minimal.log
grep -q "oa shortcut:          1" /tmp/phonecode-test-recommended.log
grep -q "pc help" /tmp/phonecode-test-recommended.log
grep -q "mkdir -p ~/projects/my-app" /tmp/phonecode-test-recommended.log
! grep -q "source ~/.bashrc" /tmp/phonecode-test-recommended.log
grep -q "proot-distro login ubuntu -- install selected tools" /tmp/phonecode-test-repair.log
grep -q "Skipping Ubuntu setup" /tmp/phonecode-test-custom-no-ubuntu.log
grep -q "PhoneCode setup finished without Ubuntu changes" /tmp/phonecode-test-custom-no-ubuntu.log
! grep -q "proot-distro login ubuntu -- install selected tools" /tmp/phonecode-test-custom-no-ubuntu.log
! grep -q "Example projects" /tmp/phonecode-test-recommended.log
! grep -q "LAN helper" /tmp/phonecode-test-recommended.log
grep -q "\[1/7\] Updating Termux packages 14%" /tmp/phonecode-test-recommended.log
