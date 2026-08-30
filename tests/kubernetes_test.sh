#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kube-utils-test.XXXXXX")"
TEST_LOG="$TEST_DIR/kubectl.log"
trap 'rm -rf "$TEST_DIR"' EXIT

# shellcheck source=../shell/kubernetes.sh
. "$REPO_DIR/shell/kubernetes.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_log() { grep -F -- "$1" "$TEST_LOG" >/dev/null || fail "missing kubectl call: $1"; }
reset_log() { : >"$TEST_LOG"; }

kubectl() {
  printf '%s\n' "$*" >>"$TEST_LOG"
  case "$*" in
    'config current-context') printf 'test-cluster\n' ;;
    'config view --minify -o jsonpath={..namespace}') printf 'test-ns' ;;
    'get namespace target') return 0 ;;
    'get deployment/api -o jsonpath={.spec.replicas}') printf '3' ;;
    get\ pods\ -n\ test-ns\ -l\ app=api*) printf 'api-abc\ttrue \n' ;;
    'get service api -o json')
      printf '%s\n' '{"apiVersion":"v1","kind":"Service","metadata":{"name":"api","namespace":"source","uid":"old","resourceVersion":"7","managedFields":[{}]},"spec":{"clusterIP":"10.0.0.1","clusterIPs":["10.0.0.1"],"ports":[{"port":80,"nodePort":30080}]},"status":{"loadBalancer":{}}}'
      ;;
    apply\ --dry-run=server*) return 0 ;;
    diff*) return 1 ;;
    apply\ -f*)
      local manifest="${3:-}"
      jq -e '.metadata.namespace == "target" and .metadata.name == "copy" and
             (.metadata.uid | not) and (.metadata.resourceVersion | not) and
             (.metadata.managedFields | not) and (.status | not) and
             (.spec.clusterIP | not) and (.spec.ports[0].nodePort | not)' "$manifest" >/dev/null
      ;;
  esac
}

[ "$(type -t k)" = function ] || fail 'k is not a dispatcher function'
[ "$(alias kc)" = "alias kc='kubectl'" ] || fail 'kc is not the direct kubectl alias'

reset_log
k pods -A >/dev/null
assert_log 'get pods -A'

reset_log
k svc api >/dev/null
assert_log 'get services api'

reset_log
k get configmaps >/dev/null
assert_log 'get configmaps'

reset_log
kbash app=api >/dev/null
assert_log 'get pods -n test-ns -l app=api --field-selector=status.phase=Running'
assert_log 'exec -it pod/api-abc -- sh -c'

reset_log
KUBE_AUTO_APPROVE=1 kscale deployment/api 3 >/dev/null
assert_log 'scale deployment/api --replicas=3'
assert_log 'rollout status deployment/api'

reset_log
KUBE_AUTO_APPROVE=1 kscale deployment/api +1 >/dev/null
assert_log 'get deployment/api -o jsonpath={.spec.replicas}'
assert_log 'scale deployment/api --current-replicas=3 --replicas=4'
assert_log 'rollout status deployment/api'

reset_log
KUBE_AUTO_APPROVE=1 kscale deployment/api -2 >/dev/null
assert_log 'scale deployment/api --current-replicas=3 --replicas=1'

reset_log
if KUBE_AUTO_APPROVE=1 kscale deployment/api -4 >/dev/null 2>&1; then fail 'scale below zero succeeded'; fi
if grep -F -- 'scale deployment/api' "$TEST_LOG" >/dev/null; then fail 'scale below zero reached kubectl scale'; fi

reset_log
kpf service/api 8080:80 >/dev/null
assert_log 'port-forward --address=127.0.0.1 service/api 8080:80'

reset_log
KUBE_AUTO_APPROVE=1 ksetimage deployment/api api=registry.example/api:v2 >/dev/null
assert_log 'set image deployment/api api=registry.example/api:v2'
if grep -F -- '--record' "$TEST_LOG" >/dev/null; then fail 'obsolete --record flag used'; fi

reset_log
KUBE_AUTO_APPROVE=1 kclone service api target copy >/dev/null
assert_log 'get service api -o json'
assert_log 'apply --dry-run=server -f'

reset_log
if printf 'no\n' | kdelete pod danger >/dev/null 2>&1; then fail 'cancelled delete succeeded'; fi
if grep -F -- 'delete pod danger' "$TEST_LOG" >/dev/null; then fail 'cancelled delete reached kubectl'; fi

printf 'PASS: kubernetes shell toolkit\n'
