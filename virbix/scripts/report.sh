#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
TIMESTAMP=`date '+%s'`

SECTION="${1:-all}"

if [[ ${SECTION} == "all" ]]; then
    node=`${SCRIPT_DIR}/report_node.sh all source`
    domains=`${SCRIPT_DIR}/report_domains.sh all source`
    pools=`${SCRIPT_DIR}/report_pools.sh all source`

    jq -s add "${node}" "${domains}" "${pools}"
fi
