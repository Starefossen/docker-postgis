#!/bin/bash
# Derived from https://github.com/docker-library/postgres/blob/master/update.sh
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

packagesUrl='http://apt.postgresql.org/pub/repos/apt/dists/wheezy-pgdg/main/binary-amd64/Packages'
packages="$(echo "$packagesUrl" | sed -r 's/[^a-zA-Z.-]+/-/g')"
curl -sSL "${packagesUrl}.bz2" | bunzip2 > "$packages"

for version in "${versions[@]}"; do
  IFS=- read pg_major postgis_major <<< "$version"
	postgisVersion="$(grep -m1 -A10 "^Package: postgresql-$pg_major-postgis-$postgis_major\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
	pgRoutingVersion="$(grep -m1 -A10 "^Package: postgresql-$pg_major-pgrouting\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
	(
    set -x
		cp Dockerfile.template initdb-postgis.sh README.md "$version/"
		mv "$version/Dockerfile.template" "$version/Dockerfile"
		sed -i 's/%%PG_MAJOR%%/'$pg_major'/g; s/%%POSTGIS_MAJOR%%/'$postgis_major'/g; s/%%POSTGIS_VERSION%%/'$postgisVersion'/g; s/%%PG_ROUTING_VERSION%%/'$pgRoutingVersion'/g' "$version/Dockerfile"
	)
done

rm "$packages"
