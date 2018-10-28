#!/bin/bash

BUILDDIR=/tmp/build

latexmk -outdir=$BUILDDIR
if [ -d $BUILDDIR ]; then
  for f in $(find $BUILDDIR -iname '*.pdf'); do
    cp --remove-destination -f $f /workspace
  done
fi
