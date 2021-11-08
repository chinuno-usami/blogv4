#!/bin/bash
# Copyright (c) 2017 Xu Shaohua<shaohua@biofan.org>. All rights reserved.
# Use of this source is governed by General Public License that can be found
# in the LICENSE file.

set -xe

# Create a new article template.

ARTICLE=$1
if [ -z "${ARTICLE}" ]; then
	  echo "$0 article-name"
	    exit 1
fi
TIMESTAMPE=$(date --rfc-3339=seconds)
FILENAME="content/${ARTICLE}.md"
URL_PATH="${ARTICLE}"
echo "TIMESTMAP: ${TIMESTAMPE}"
echo "FILENAME: ${FILENAME}"
echo "URL_PATH: ${URL_PATH}"

if [ ! -f "${FILENAME}" ]; then
	  cat > "${FILENAME}" << EOF
+++
title = "${ARTICLE}"
description = ""
date = ${TIMESTAMPE}
path = "${URL_PATH}"
[taxonomies]
tags = []
categories = ["blog"]
+++

<!-- more -->

EOF

fi

vim "${FILENAME}"
