#!/bin/bash

echo 'RDEPEND="';
grep -h -F '## GENTOO_DEP:' usr/ -R |perl -ne 's/^## GENTOO_DEP: (.+)$/$1/; print "\t>=$_"' \
	|sort -u;
echo '"';
