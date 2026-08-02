#!/bin/sh
#
# Move the "local" routing lookup after the VRF lookup.
#
# Without this, SIP realms silently do not work, and the way they fail is genuinely hard to
# read: the carrier side comes up, the proxy starts and answers from inside its own realm, and
# yet the phone system cannot reach it at all. No error appears anywhere.
#
# The reason is that rule 0 ("from all lookup local") is global and is consulted before the
# VRF's own rule. Both ends of a realm's private link are addresses on this same machine, so
# every packet between them matches the local table first and is delivered straight back up the
# stack through loopback. It never crosses into the realm, and the realm's routing context is
# lost on the way. Measured on Ubuntu 24.04: with rule 0 in place a ping across the link gets
# 100% loss; moved, the same ping succeeds and the proxy answers.
#
# Putting the local lookup at 32765 keeps it ahead of "main" at 32766, so ordinary traffic is
# unaffected — it is only the relative order against the VRF rule that changes. This is the
# arrangement the kernel's own VRF documentation asks for.
#
# Idempotent: safe to run again, and a no-op once it has been applied.

set -e

move_local_after_vrf() {
    family="$1"

    if ip "$family" rule list 2>/dev/null | grep -q '^32765:.*lookup local'; then
        return 0
    fi

    # Added before the old one is removed, so there is never a moment without a local lookup.
    ip "$family" rule add pref 32765 table local
    ip "$family" rule del pref 0 2>/dev/null || true
}

move_local_after_vrf -4
move_local_after_vrf -6

exit 0
