#!/bin/bash
[[ $1 == --version ]] && echo "fake" && exit 0
sleep "${JOB_RUNTIME:-300}"
