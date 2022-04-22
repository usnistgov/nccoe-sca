#!/bin/bash

# Adapted from HIRS-ACA .ci tests 
# https://github.com/nsacyber/HIRS/.ci

set -e
yum -y install /root/HIRS_AttestationCA-*.rpm
echo "ACA Loaded!"
tail -f /dev/null
