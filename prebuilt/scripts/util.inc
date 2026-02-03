# Common script functions

# Download url to file
# Download url to file (robust)
fetchUrl() {
    local url="$1"
    local savepath="$2"

    if [ -z "$url" ] || [ -z "$savepath" ]; then
        echo "fetchUrl: usage: fetchUrl <url> <savepath>" >&2
        return 2
    fi

    # Ensure parent directory exists (safe even if savepath is just a filename)
    local parent
    parent="$(dirname "$savepath")"
    if [ -n "$parent" ] && [ "$parent" != "." ]; then
        mkdir -p "$parent" || return 1
    fi

    # Prefer curl, then wget, then perl (last resort)
    if command -v curl >/dev/null 2>&1; then
        # --fail: non-2xx -> exit non-zero
        # -L: follow redirects
        # --retry*: tolerate transient failures
        # --connect-timeout / --max-time: avoid hanging forever
        curl --fail -L \
            --retry 3 --retry-delay 2 --retry-all-errors \
            --connect-timeout 15 --max-time 600 \
            "$url" -o "$savepath"
        local rc=$?
        if [ $rc -ne 0 ]; then
            echo "fetchUrl: curl failed (rc=$rc) url='$url' savepath='$savepath'" >&2
        fi
        return $rc

    elif command -v wget >/dev/null 2>&1; then
        # --tries / --timeout: basic robustness
        wget --tries=3 --timeout=30 "$url" -O "$savepath"
        local rc=$?
        if [ $rc -ne 0 ]; then
            echo "fetchUrl: wget failed (rc=$rc) url='$url' savepath='$savepath'" >&2
        fi
        return $rc

    elif command -v perl >/dev/null 2>&1; then
        # Perl fallback. Follow redirects if possible and accept 2xx.
        perl -MLWP::UserAgent -e '
            my ($url,$path)=@ARGV;
            my $ua = LWP::UserAgent->new(
                agent => "fetchUrl/1.0",
                timeout => 600,
                max_redirect => 10,
            );
            my $res = $ua->mirror($url, $path);
            exit($res->is_success ? 0 : 1);
        ' "$url" "$savepath"
        local rc=$?
        if [ $rc -ne 0 ]; then
            echo "fetchUrl: perl failed (rc=$rc) url='$url' savepath='$savepath'" >&2
        fi
        return $rc

    else
        echo "fetchUrl: no downloader found (need curl or wget or perl)" >&2
        return 127
    fi
}

