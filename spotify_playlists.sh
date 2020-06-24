#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 09:30:53 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns spotify playlists for \$SPOTIFY_USER or current user to which the \$SPOTIFY_ACCESS_TOKEN belongs

Output Format:

<playlist_id>   <playlist_name>

Requires \$SPOTIFY_ACCESS_TOKEN in the environment (can generate from spotify_api_token.sh) or will auto generate from \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET if found in the environment

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

if [ -n "${SPOTIFY_USER:-}" ]; then
    user="users/$SPOTIFY_USER"
else
    # must not have 'users/' prefix (will go to an actual literal user called 'me' in that case)
    user="me"
fi

offset="${OFFSET:-0}"

# expands out to: /v1/users/harisekhon/playlists...
#             or: /v1/me/playlists...
url_path="/v1/$user/playlists?limit=50&offset=$offset"

output(){
    jq -r '.items[] | [.id, .name] | @tsv' <<< "$output"
}

get_next(){
    jq -r '.next' <<< "$output"
}

while [ -n "$url_path" ] && [ "$url_path" != null ]; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    # shellcheck disable=SC2181
    if [ $? != 0 ] || [ "$(jq -r '.error' <<< "$output")" != null ]; then
        echo "$output" >&2
        exit 1
    fi
    url_path="$(get_next)"
    output
done