#!/bin/bash

test "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`"
