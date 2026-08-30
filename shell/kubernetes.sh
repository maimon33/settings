# Kubernetes shell toolkit. Bash 3.2 compatible; kubectl is the only hard dependency.
# Run `khelp` for the command index. Mutating helpers ask before making changes;
# set KUBE_AUTO_APPROVE=1 only in deliberate automation.

_kube_need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'kube-utils: required command not found: %s\n' "$1" >&2
    return 127
  }
}

_kube_context() {
  kubectl config current-context 2>/dev/null
}

_kube_namespace() {
  local namespace
  namespace="$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)"
  printf '%s\n' "${namespace:-default}"
}

_kube_location() {
  local context namespace
  context="$(_kube_context)" || return
  namespace="$(_kube_namespace)" || return
  printf '%s / %s\n' "${context:-<no-context>}" "$namespace"
}

_kube_confirm() {
  local reply
  [ "${KUBE_AUTO_APPROVE:-0}" = 1 ] && return 0
  printf '%s\n' "$1" >&2
  printf 'Type yes to continue: ' >&2
  IFS= read -r reply
  [ "$reply" = yes ] || {
    printf 'Cancelled.\n' >&2
    return 1
  }
}

_kube_slug() {
  printf '%s' "$1" | tr '/:@ ' '----' | tr -cd '[:alnum:]_.-'
}

khelp() {
  cat <<'EOF'
Kubernetes shell toolkit

Command shortcuts
  k pods [ARGS...]           get pods (also: po)
  k svc [ARGS...]            get services
  k deploy [ARGS...]         get deployments
  k <resource> [ARGS...]     shorthand for common resource types
  k <kubectl command> ...    pass normal kubectl commands through unchanged
  kc ...                     direct alias to kubectl
  kbash TARGET [CONTAINER]   shell into a pod/workload or label-selected pod
                             TARGET: deploy/api, pod/api-123, app=api,
                                     label/app=api, or a bare pod/deploy name

Navigation
  kwhere                    current context and namespace
  kctx [CONTEXT]            list/switch contexts (fzf picker when available)
  kns [NAMESPACE]           show/switch the current context's namespace
  kconfig-export FILE       export the minified, flattened kubeconfig (mode 600)

Discovery
  kg ARGS...                kubectl get
  kga [RESOURCE...]         list resources across all namespaces
  kall [NAMESPACE]          list every safe, listable namespaced resource type
  kapi [FILTER]             discover API resources
  kimages [NAMESPACE]       list workload container images
  kowners POD               show a pod's ownership chain
  kexplain FIELD            recursively explain an API field

Inspect and access
  kd RESOURCE [NAME]        describe a resource
  kyaml RESOURCE [NAME]     print live YAML
  klogs TARGET [ARGS...]    logs with timestamps (for example deploy/api)
  klogs-all TARGET          logs from every container, prefixed
  kexec TARGET [CTR] -- CMD execute a command in a workload or pod
  kshell TARGET [CTR]       low-level interactive bash/ash/sh
  kpf TARGET PORTS...       port-forward on localhost
  kcp SRC DEST [ARGS...]    copy files to/from a container
  kdebug TARGET [IMAGE]     start an ephemeral debug container

Safe management
  kapply FILE...            server dry-run, diff, confirm, then apply
  kdiff FILE...             compare manifests with live state
  kdelete ARGS...           confirm context/namespace, then delete
  kscale TYPE/NAME N|+N|-N  confirm and scale to/by a replica count
  kautoscale WORKLOAD MIN MAX [CPU]
                           create/update an HPA (default target CPU: 80%)
  krestart TYPE/NAME        confirm and restart a rollout
  kstatus TYPE/NAME         watch rollout status
  khistory TYPE/NAME        show rollout history
  kpause TYPE/NAME          confirm and pause a rollout
  kresume TYPE/NAME         confirm and resume a rollout
  kundo TYPE/NAME [REV]     confirm and undo a rollout
  ksetimage WORKLOAD C=IMG  confirm and update a container image
  kwait CONDITION TARGET [TIMEOUT]
                           wait for a condition (default timeout: 5m)
  kscratch IMAGE [COMMAND]  disposable interactive pod, deleted on exit
  kjobfromcron CRONJOB [JOB] create a one-off Job from a CronJob
  kcordon NODE              confirm and cordon a node
  kdrain NODE               PDB-aware drain; does not delete emptyDir data
  kuncordon NODE            confirm and return a node to service

Export, clone, and backup
  kexport TYPE NAME [FILE]  atomically export one live object as YAML
  kclone TYPE NAME NS [NEW] clone a sanitized object (requires jq)
  kbackup-ns [NS] [DIR] [--include-secrets]
                            export all listable namespaced resources
  kbackup-cluster [DIR] [--include-secrets]
                            export cluster-scoped resources and every namespace

Monitoring and analysis
  kevents [NS]              events ordered by creation time
  kwarnings [NS]            warning events
  ktop [pod|node] [ARGS...] metrics-server usage
  kwatch RESOURCE [ARGS...]  continuously watch a resource list
  krestarts [NS]            pods sorted by restart count
  kunready [NS]             non-ready pods
  kpending [NS]             describe every pending pod
  kresources [NS]           requests/limits by container (requires jq)
  kcapacity                 node allocatable/capacity overview
  khealth [NS]              compact cluster and workload health report
  kdiagnose TARGET [NS]     get, describe, related events, and recent logs
  kcan VERB RESOURCE [NS]   RBAC check
  krbac [NS]                effective RBAC permissions

Useful read-only aliases: kc, kgp, kgpa, kgd, kgs, kgsts, kgj, kgcj, kgcm,
kgsec, kgns, kgn, kdp, kdd, kds, kl, klf. `kubectl` arguments still work.
EOF
}

# Friendly resource dispatcher. Unknown words are passed directly to kubectl,
# so `k get ...`, `k apply ...`, and new upstream commands keep working.
k() {
  _kube_need kubectl || return
  local command="${1:-help}"
  [ "$#" -gt 0 ] && shift
  case "$command" in
    help|-h|--help) khelp ;;
    pods|pod|po) kubectl get pods "$@" ;;
    services|service|svc) kubectl get services "$@" ;;
    deployments|deployment|deploy|dep) kubectl get deployments "$@" ;;
    statefulsets|statefulset|sts) kubectl get statefulsets "$@" ;;
    daemonsets|daemonset|ds) kubectl get daemonsets "$@" ;;
    jobs|job) kubectl get jobs "$@" ;;
    cronjobs|cronjob|cj) kubectl get cronjobs "$@" ;;
    ingresses|ingress|ing) kubectl get ingresses "$@" ;;
    configmaps|configmap|cm) kubectl get configmaps "$@" ;;
    secrets|secret|sec) kubectl get secrets "$@" ;;
    namespaces|ns) kubectl get namespaces "$@" ;;
    nodes|node|no) kubectl get nodes -o wide "$@" ;;
    persistentvolumes|pv) kubectl get persistentvolumes "$@" ;;
    persistentvolumeclaims|pvc) kubectl get persistentvolumeclaims "$@" ;;
    serviceaccounts|serviceaccount|sa) kubectl get serviceaccounts "$@" ;;
    horizontalpodautoscalers|hpa) kubectl get horizontalpodautoscalers "$@" ;;
    poddisruptionbudgets|pdb) kubectl get poddisruptionbudgets "$@" ;;
    events|event|ev) kevents "$@" ;;
    all) kga "$@" ;;
    contexts|ctx) kctx "$@" ;;
    namespace) kns "$@" ;;
    bash|shell) kbash "$@" ;;
    *) kubectl "$command" "$@" ;;
  esac
}

kwhere() {
  _kube_need kubectl || return
  _kube_location
}

kctx() {
  _kube_need kubectl || return
  local context
  if [ "$#" -gt 0 ]; then
    context="$1"
  elif command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
    context="$(kubectl config get-contexts -o name | fzf --prompt='context> ' --height=40%)" || return
    [ -n "$context" ] || return
  else
    kubectl config get-contexts
    return
  fi
  kubectl config use-context "$context" && kwhere
}

kns() {
  _kube_need kubectl || return
  local context namespace
  if [ "$#" -eq 0 ]; then
    _kube_namespace
    return
  fi
  namespace="$1"
  kubectl get namespace "$namespace" >/dev/null || return
  context="$(_kube_context)" || return
  [ -n "$context" ] || { printf 'kube-utils: no current context\n' >&2; return 1; }
  kubectl config set-context "$context" --namespace="$namespace" >/dev/null && kwhere
}

kconfig-export() {
  _kube_need kubectl || return
  [ "$#" -eq 1 ] || { printf 'usage: kconfig-export FILE\n' >&2; return 2; }
  local output tmp
  output="$1"
  tmp="$(mktemp "${output}.tmp.XXXXXX")" || return
  if (umask 077; kubectl config view --minify --flatten --raw >"$tmp"); then
    chmod 600 "$tmp" && mv -f "$tmp" "$output"
    printf 'Wrote credential-bearing kubeconfig: %s\n' "$output"
  else
    rm -f "$tmp"
    return 1
  fi
}

kg() { kubectl get "$@"; }

kga() {
  if [ "$#" -eq 0 ]; then kubectl get pods,deployments,statefulsets,daemonsets,services,ingresses,jobs,cronjobs -A -o wide
  else kubectl get "$@" -A; fi
}

kall() {
  _kube_need kubectl || return
  local namespace resource
  namespace="${1:-$(_kube_namespace)}"
  while IFS= read -r resource; do
    case "$resource" in secrets|events|events.events.k8s.io) continue ;; esac
    printf '\n### %s\n' "$resource"
    kubectl get "$resource" -n "$namespace" --ignore-not-found 2>/dev/null || true
  done < <(kubectl api-resources --namespaced=true --verbs=list -o name | sort -u)
}

kapi() {
  if [ "$#" -eq 0 ]; then kubectl api-resources -o wide
  else kubectl api-resources -o wide | { head -1; grep -i -- "$1"; }; fi
}

kimages() {
  local namespace
  namespace="${1:-$(_kube_namespace)}"
  kubectl get pods -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.initContainers[*]}init:{.name}={.image}{"\t"}{end}{range .spec.containers[*]}{.name}={.image}{"\t"}{end}{"\n"}{end}' | sort
}

kowners() {
  [ "$#" -eq 1 ] || { printf 'usage: kowners POD\n' >&2; return 2; }
  local kind name next_kind next_name
  kind=pod; name="$1"
  while [ -n "$name" ]; do
    printf '%s/%s\n' "$kind" "$name"
    next_kind="$(kubectl get "$kind" "$name" -o 'jsonpath={.metadata.ownerReferences[0].kind}' 2>/dev/null)"
    next_name="$(kubectl get "$kind" "$name" -o 'jsonpath={.metadata.ownerReferences[0].name}' 2>/dev/null)"
    [ -n "$next_name" ] || break
    kind="$(printf '%s' "$next_kind" | tr '[:upper:]' '[:lower:]')"
    name="$next_name"
  done
}

kexplain() { kubectl explain --recursive "$@"; }
kd() { kubectl describe "$@"; }
kyaml() { kubectl get "$@" -o yaml; }

klogs() {
  [ "$#" -ge 1 ] || { printf 'usage: klogs TARGET [kubectl logs options]\n' >&2; return 2; }
  local target="$1"; shift
  kubectl logs "$target" --timestamps "$@"
}

klogs-all() {
  [ "$#" -ge 1 ] || { printf 'usage: klogs-all TARGET [kubectl logs options]\n' >&2; return 2; }
  local target="$1"; shift
  kubectl logs "$target" --all-containers=true --prefix --timestamps "$@"
}

kexec() {
  [ "$#" -ge 2 ] || { printf 'usage: kexec TARGET [CONTAINER] -- COMMAND...\n' >&2; return 2; }
  local target="$1" container=
  shift
  if [ "${1:-}" != -- ]; then container="$1"; shift; fi
  [ "${1:-}" = -- ] && shift
  [ "$#" -gt 0 ] || { printf 'kexec: missing command\n' >&2; return 2; }
  if [ -n "$container" ]; then kubectl exec -it "$target" -c "$container" -- "$@"
  else kubectl exec -it "$target" -- "$@"; fi
}

kshell() {
  [ "$#" -ge 1 ] || { printf 'usage: kshell TARGET [CONTAINER]\n' >&2; return 2; }
  local target="$1" container="${2:-}"
  local probe='if command -v bash >/dev/null 2>&1; then exec bash; elif command -v ash >/dev/null 2>&1; then exec ash; else exec sh; fi'
  if [ -n "$container" ]; then kubectl exec -it "$target" -c "$container" -- sh -c "$probe"
  else kubectl exec -it "$target" -- sh -c "$probe"; fi
}

_kube_pod_for_selector() {
  local selector="$1" namespace="${2:-$(_kube_namespace)}"
  kubectl get pods -n "$namespace" -l "$selector" --field-selector=status.phase=Running \
    -o 'jsonpath={range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.ready}{" "}{end}{"\n"}{end}' |
    awk 'NF > 1 && $0 !~ /false/ { print $1; exit }'
}

kbash() {
  _kube_need kubectl || return
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || {
    printf 'usage: kbash TARGET [CONTAINER]\n' >&2
    printf 'TARGET may be deploy/api, pod/api-123, app=api, label/app=api, or a bare name.\n' >&2
    return 2
  }

  local requested="$1" container="${2:-}" target= pod=
  case "$requested" in
    label/*) pod="$(_kube_pod_for_selector "${requested#label/}")" || return ;;
    *=*|*' in ('*|*' notin ('*) pod="$(_kube_pod_for_selector "$requested")" || return ;;
    */*) target="$requested" ;;
    *)
      if kubectl get pod "$requested" -o name >/dev/null 2>&1; then
        target="pod/$requested"
      elif kubectl get deployment "$requested" -o name >/dev/null 2>&1; then
        target="deployment/$requested"
      else
        printf 'kbash: no pod or deployment named %s in %s\n' "$requested" "$(_kube_location)" >&2
        return 1
      fi
      ;;
  esac

  if [ -n "$pod" ]; then
    [ -n "$pod" ] || return
    target="pod/$pod"
  fi
  [ -n "$target" ] || {
    printf 'kbash: no running, ready pod matches %s in namespace %s\n' "$requested" "$(_kube_namespace)" >&2
    return 1
  }
  kshell "$target" "$container"
}

kpf() {
  [ "$#" -ge 2 ] || { printf 'usage: kpf TARGET LOCAL:REMOTE [more ports]\n' >&2; return 2; }
  kubectl port-forward --address=127.0.0.1 "$@"
}

kcp() { kubectl cp "$@"; }

kdebug() {
  [ "$#" -ge 1 ] || { printf 'usage: kdebug TARGET [IMAGE]\n' >&2; return 2; }
  kubectl debug -it "$1" --image="${2:-busybox:1.37}" --profile=general
}

kapply() {
  _kube_need kubectl || return
  [ "$#" -gt 0 ] || { printf 'usage: kapply FILE...\n' >&2; return 2; }
  local file args=()
  for file in "$@"; do args+=( -f "$file" ); done
  kubectl apply --dry-run=server "${args[@]}" >/dev/null || return
  if kubectl diff "${args[@]}"; then
    :
  else
    local diff_status=$?
    [ "$diff_status" -eq 1 ] || return "$diff_status"
  fi
  _kube_confirm "Apply to $(_kube_location)? Files: $*" || return
  kubectl apply "${args[@]}"
}

kdiff() {
  [ "$#" -gt 0 ] || { printf 'usage: kdiff FILE...\n' >&2; return 2; }
  local file args=()
  for file in "$@"; do args+=( -f "$file" ); done
  kubectl diff "${args[@]}"
}

kdelete() {
  [ "$#" -gt 0 ] || { printf 'usage: kdelete RESOURCE [NAME/options...]\n' >&2; return 2; }
  _kube_confirm "Delete from $(_kube_location)? kubectl delete $*" || return
  kubectl delete "$@"
}

kscale() {
  [ "$#" -eq 2 ] || { printf 'usage: kscale TYPE/NAME REPLICAS|+DELTA|-DELTA\n' >&2; return 2; }
  local requested="$2" current delta sign replicas prompt scale_current=''
  case "$requested" in
    +*|-*)
      delta="${requested#?}"
      case "$delta" in ''|*[!0-9]*) printf 'kscale: delta must be an integer prefixed with + or -\n' >&2; return 2 ;; esac
      sign="${requested%"$delta"}"
      current="$(kubectl get "$1" -o 'jsonpath={.spec.replicas}')" || return
      case "$current" in ''|*[!0-9]*) printf 'kscale: could not read the current replica count for %s\n' "$1" >&2; return 1 ;; esac
      while [ "${delta#0}" != "$delta" ] && [ "$delta" != 0 ]; do delta="${delta#0}"; done
      if [ "$sign" = + ]; then
        replicas=$((current + delta))
      else
        replicas=$((current - delta))
      fi
      [ "$replicas" -ge 0 ] || { printf 'kscale: resulting replica count cannot be negative (%s)\n' "$replicas" >&2; return 2; }
      scale_current="--current-replicas=$current"
      prompt="Scale $1 by $requested from $current to $replicas replicas"
      ;;
    *)
      case "$requested" in ''|*[!0-9]*) printf 'kscale: replicas must be a non-negative integer or a signed delta\n' >&2; return 2 ;; esac
      replicas="$requested"
      prompt="Scale $1 to $replicas replicas"
      ;;
  esac
  _kube_confirm "$prompt in $(_kube_location)?" || return
  kubectl scale "$1" ${scale_current:+"$scale_current"} --replicas="$replicas" && kubectl rollout status "$1"
}

kautoscale() {
  [ "$#" -ge 3 ] && [ "$#" -le 4 ] || { printf 'usage: kautoscale WORKLOAD MIN MAX [CPU_PERCENT]\n' >&2; return 2; }
  case "$2:$3:${4:-80}" in *[!0-9:]*) printf 'kautoscale: MIN, MAX, and CPU must be integers\n' >&2; return 2 ;; esac
  [ "$2" -le "$3" ] || { printf 'kautoscale: MIN cannot exceed MAX\n' >&2; return 2; }
  _kube_confirm "Autoscale $1 from $2 to $3 replicas at ${4:-80}% CPU in $(_kube_location)?" || return
  kubectl autoscale "$1" --min="$2" --max="$3" --cpu="${4:-80}%"
}

krestart() {
  [ "$#" -eq 1 ] || { printf 'usage: krestart TYPE/NAME\n' >&2; return 2; }
  _kube_confirm "Restart $1 in $(_kube_location)?" || return
  kubectl rollout restart "$1" && kubectl rollout status "$1"
}

kstatus() { kubectl rollout status "$@"; }
khistory() { kubectl rollout history "$@"; }

kpause() {
  [ "$#" -eq 1 ] || { printf 'usage: kpause TYPE/NAME\n' >&2; return 2; }
  _kube_confirm "Pause rollout of $1 in $(_kube_location)?" || return
  kubectl rollout pause "$1"
}

kresume() {
  [ "$#" -eq 1 ] || { printf 'usage: kresume TYPE/NAME\n' >&2; return 2; }
  _kube_confirm "Resume rollout of $1 in $(_kube_location)?" || return
  kubectl rollout resume "$1" && kubectl rollout status "$1"
}

kundo() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || { printf 'usage: kundo TYPE/NAME [REVISION]\n' >&2; return 2; }
  local revision=()
  [ "$#" -eq 2 ] && revision=( --to-revision="$2" )
  kubectl rollout history "$1" || return
  _kube_confirm "Undo rollout of $1 ${2:+to revision $2}in $(_kube_location)?" || return
  kubectl rollout undo "$1" "${revision[@]}" && kubectl rollout status "$1"
}

ksetimage() {
  [ "$#" -eq 2 ] || { printf 'usage: ksetimage WORKLOAD CONTAINER=IMAGE\n' >&2; return 2; }
  _kube_confirm "Set image on $1 to $2 in $(_kube_location)?" || return
  kubectl set image "$1" "$2" && kubectl rollout status "$1"
}

kwait() {
  [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { printf 'usage: kwait CONDITION TARGET [TIMEOUT]\n' >&2; return 2; }
  local condition="$1"
  case "$condition" in create|delete|condition=*|jsonpath=*) ;; *) condition="condition=$condition" ;; esac
  kubectl wait --for="$condition" "$2" --timeout="${3:-5m}"
}

kscratch() {
  [ "$#" -ge 1 ] || { printf 'usage: kscratch IMAGE [COMMAND...]\n' >&2; return 2; }
  local image="$1" name command=()
  shift
  name="shell-$(date +%s)"
  if [ "$#" -gt 0 ]; then command=( --command -- "$@" ); fi
  _kube_confirm "Start disposable pod $name with image $image in $(_kube_location)? It will be deleted on exit." || return
  kubectl run "$name" --image="$image" --restart=Never --rm -it "${command[@]}"
}

kjobfromcron() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || { printf 'usage: kjobfromcron CRONJOB [JOB_NAME]\n' >&2; return 2; }
  local job="${2:-$1-manual-$(date +%Y%m%d%H%M%S)}"
  _kube_confirm "Create job/$job from cronjob/$1 in $(_kube_location)?" || return
  kubectl create job "$job" --from="cronjob/$1"
}

kcordon() {
  [ "$#" -eq 1 ] || { printf 'usage: kcordon NODE\n' >&2; return 2; }
  _kube_confirm "Cordon node $1 in context $(_kube_context)?" || return
  kubectl cordon "$1"
}

kdrain() {
  [ "$#" -eq 1 ] || { printf 'usage: kdrain NODE\n' >&2; return 2; }
  kubectl get node "$1" -o wide || return
  _kube_confirm "Drain node $1 in context $(_kube_context)? This respects PDBs and preserves emptyDir data." || return
  kubectl drain "$1" --ignore-daemonsets
}

kuncordon() {
  [ "$#" -eq 1 ] || { printf 'usage: kuncordon NODE\n' >&2; return 2; }
  _kube_confirm "Return node $1 to service in context $(_kube_context)?" || return
  kubectl uncordon "$1"
}

kexport() {
  _kube_need kubectl || return
  [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { printf 'usage: kexport TYPE NAME [FILE]\n' >&2; return 2; }
  local type="$1" name="$2" output tmp context namespace stamp
  context="$(_kube_context)"; namespace="$(_kube_namespace)"; stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  output="${3:-$(_kube_slug "$type-$name-$context-$namespace-$stamp").yaml}"
  tmp="$(mktemp "${output}.tmp.XXXXXX")" || return
  if (umask 077; kubectl get "$type" "$name" -o yaml >"$tmp"); then
    chmod 600 "$tmp" && mv -f "$tmp" "$output"
    printf 'Exported live object to %s (includes server-managed fields).\n' "$output"
  else rm -f "$tmp"; return 1; fi
}

kclone() {
  _kube_need kubectl || return
  _kube_need jq || return
  [ "$#" -ge 3 ] && [ "$#" -le 4 ] || { printf 'usage: kclone TYPE NAME TARGET_NAMESPACE [NEW_NAME]\n' >&2; return 2; }
  local type="$1" name="$2" namespace="$3" new_name="${4:-$2}" tmp status
  kubectl get namespace "$namespace" >/dev/null || return
  tmp="$(mktemp "${TMPDIR:-/tmp}/kube-clone.XXXXXX.json")" || return
  if ! kubectl get "$type" "$name" -o json | jq --arg ns "$namespace" --arg name "$new_name" '
    del(.metadata.uid, .metadata.resourceVersion, .metadata.generation,
        .metadata.creationTimestamp, .metadata.managedFields, .metadata.selfLink,
        .metadata.ownerReferences, .status)
    | .metadata.namespace = $ns | .metadata.name = $name
    | if .kind == "Service" then
        (if .spec.clusterIP == "None" then
           del(.spec.clusterIPs, .spec.healthCheckNodePort,
               .spec.ipFamilies, .spec.ipFamilyPolicy)
         else
           del(.spec.clusterIP, .spec.clusterIPs, .spec.healthCheckNodePort,
               .spec.ipFamilies, .spec.ipFamilyPolicy)
         end)
        | .spec.ports = [(.spec.ports[]? | del(.nodePort))]
      elif .kind == "PersistentVolumeClaim" then
        del(.spec.volumeName)
      elif .kind == "Job" then
        del(.spec.selector,
            .metadata.labels."controller-uid",
            .metadata.labels."batch.kubernetes.io/controller-uid",
            .spec.template.metadata.labels."controller-uid",
            .spec.template.metadata.labels."batch.kubernetes.io/controller-uid")
      elif .kind == "ServiceAccount" then
        del(.secrets)
      else . end' >"$tmp"; then
    rm -f "$tmp"; return 1
  fi
  kubectl apply --dry-run=server -f "$tmp" -o name || { status=$?; rm -f "$tmp"; return "$status"; }
  if kubectl diff -f "$tmp"; then status=0; else status=$?; fi
  if [ "$status" -gt 1 ]; then rm -f "$tmp"; return "$status"; fi
  if _kube_confirm "Clone $type/$name to $namespace as $new_name in context $(_kube_context)?"; then
    kubectl apply -f "$tmp"; status=$?
  else status=$?; fi
  rm -f "$tmp"
  return "$status"
}

_kube_backup_scope() {
  local namespaced="$1" namespace="$2" destination="$3" include_secrets="$4" resource tmp
  mkdir -p "$destination" || return
  chmod 700 "$destination"
  while IFS= read -r resource; do
    case "$resource" in
      events|events.events.k8s.io) continue ;;
      secrets) [ "$include_secrets" = 1 ] || continue ;;
    esac
    tmp="$destination/.$(_kube_slug "$resource").tmp"
    if { [ "$namespaced" = true ] && kubectl get "$resource" -n "$namespace" -o yaml >"$tmp" 2>/dev/null; } ||
       { [ "$namespaced" = false ] && kubectl get "$resource" -o yaml >"$tmp" 2>/dev/null; }; then
      chmod 600 "$tmp"; mv -f "$tmp" "$destination/$(_kube_slug "$resource").yaml"
    else
      rm -f "$tmp"; printf 'Skipped %s (not readable)\n' "$resource" >&2
    fi
  done < <(kubectl api-resources --namespaced="$namespaced" --verbs=list -o name | sort -u)
}

kbackup-ns() {
  _kube_need kubectl || return
  local namespace= destination= include_secrets=0 arg context stamp
  for arg in "$@"; do
    case "$arg" in
      --include-secrets) include_secrets=1 ;;
      --*) printf 'kbackup-ns: unknown option: %s\n' "$arg" >&2; return 2 ;;
      *) if [ -z "$namespace" ]; then namespace="$arg"; elif [ -z "$destination" ]; then destination="$arg"; else printf 'usage: kbackup-ns [NS] [DIR] [--include-secrets]\n' >&2; return 2; fi ;;
    esac
  done
  namespace="${namespace:-$(_kube_namespace)}"; context="$(_kube_context)"; stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  destination="${destination:-kube-backup-$(_kube_slug "$context-$namespace-$stamp")}" 
  kubectl get namespace "$namespace" >/dev/null || return
  (umask 077; _kube_backup_scope true "$namespace" "$destination" "$include_secrets") || return
  printf 'Backed up namespace %s to %s%s.\n' "$namespace" "$destination" "$([ "$include_secrets" = 1 ] && printf ' including Secrets')"
  printf 'These are live snapshots with server-managed fields; review before restore.\n'
}

kbackup-cluster() {
  _kube_need kubectl || return
  local destination= include_secrets=0 arg context stamp namespace ns_dir
  for arg in "$@"; do
    case "$arg" in
      --include-secrets) include_secrets=1 ;;
      --*) printf 'kbackup-cluster: unknown option: %s\n' "$arg" >&2; return 2 ;;
      *) [ -z "$destination" ] || { printf 'usage: kbackup-cluster [DIR] [--include-secrets]\n' >&2; return 2; }; destination="$arg" ;;
    esac
  done
  context="$(_kube_context)"; stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  destination="${destination:-kube-backup-$(_kube_slug "$context-cluster-$stamp")}" 
  mkdir -p "$destination/namespaces" || return; chmod 700 "$destination" "$destination/namespaces"
  (umask 077; _kube_backup_scope false '' "$destination/cluster-scoped" "$include_secrets") || return
  while IFS= read -r namespace; do
    ns_dir="$destination/namespaces/$(_kube_slug "$namespace")"
    (umask 077; _kube_backup_scope true "$namespace" "$ns_dir" "$include_secrets") || return
  done < <(kubectl get namespaces -o 'jsonpath={range .items[*]}{.metadata.name}{"\n"}{end}')
  printf 'Backed up cluster context %s to %s%s.\n' "$context" "$destination" "$([ "$include_secrets" = 1 ] && printf ' including Secrets')"
  printf 'This is an API-object snapshot, not an etcd or persistent-volume backup.\n'
}

kevents() {
  local namespace="${1:-$(_kube_namespace)}"
  kubectl events -n "$namespace" --types=Normal,Warning 2>/dev/null || kubectl get events -n "$namespace" --sort-by=.metadata.creationTimestamp
}

kwarnings() {
  local namespace="${1:-$(_kube_namespace)}"
  kubectl events -n "$namespace" --types=Warning 2>/dev/null || kubectl get events -n "$namespace" --field-selector=type=Warning --sort-by=.metadata.creationTimestamp
}

ktop() { kubectl top "${1:-pod}" "${@:2}"; }

kwatch() {
  [ "$#" -ge 1 ] || { printf 'usage: kwatch RESOURCE [kubectl get options]\n' >&2; return 2; }
  kubectl get "$@" --watch
}

krestarts() {
  local namespace="${1:-$(_kube_namespace)}"
  kubectl get pods -n "$namespace" -o custom-columns='POD:.metadata.name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,REASON:.status.containerStatuses[*].state.waiting.reason,NODE:.spec.nodeName' --sort-by='.status.containerStatuses[0].restartCount'
}

kunready() {
  local namespace="${1:-$(_kube_namespace)}"
  kubectl get pods -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{range .status.containerStatuses[*]}{.name}{"="}{.ready}{":"}{.state.waiting.reason}{" "}{end}{"\n"}{end}' | awk '$0 ~ /false/ || $2 != "Running"'
}

kpending() {
  local namespace="${1:-$(_kube_namespace)}" pod found=0
  while IFS= read -r pod; do
    found=1; printf '\n### pod/%s\n' "$pod"; kubectl describe pod "$pod" -n "$namespace"
  done < <(kubectl get pods -n "$namespace" --field-selector=status.phase=Pending -o name | sed 's#^pod/##')
  [ "$found" -eq 1 ] || printf 'No pending pods in %s.\n' "$namespace"
}

kresources() {
  _kube_need jq || return
  local namespace="${1:-$(_kube_namespace)}"
  kubectl get pods -n "$namespace" -o json | jq -r '
    ["POD","CONTAINER","CPU_REQ","CPU_LIM","MEM_REQ","MEM_LIM"],
    (.items[] as $p | ($p.spec.initContainers[]?, $p.spec.containers[]?) |
      [$p.metadata.name, .name, (.resources.requests.cpu // "-"),
       (.resources.limits.cpu // "-"), (.resources.requests.memory // "-"),
       (.resources.limits.memory // "-")]) | @tsv' | column -t -s $'\t'
}

kcapacity() {
  kubectl get nodes -o custom-columns='NODE:.metadata.name,CPU_ALLOC:.status.allocatable.cpu,CPU_CAP:.status.capacity.cpu,MEM_ALLOC:.status.allocatable.memory,MEM_CAP:.status.capacity.memory,PODS_ALLOC:.status.allocatable.pods,PODS_CAP:.status.capacity.pods'
}

khealth() {
  local namespace="${1:-$(_kube_namespace)}"
  printf 'LOCATION\n'; _kube_location
  printf '\nNODES\n'; kubectl get nodes
  printf '\nWORKLOADS (%s)\n' "$namespace"; kubectl get deployments,statefulsets,daemonsets -n "$namespace"
  printf '\nUNREADY PODS (%s)\n' "$namespace"; kunready "$namespace"
  printf '\nRECENT WARNINGS (%s)\n' "$namespace"; kwarnings "$namespace" | tail -20
}

kdiagnose() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || { printf 'usage: kdiagnose TARGET [NAMESPACE]\n' >&2; return 2; }
  local target="$1" namespace="${2:-$(_kube_namespace)}" name
  name="${target#*/}"
  printf '### GET\n'; kubectl get "$target" -n "$namespace" -o wide
  printf '\n### DESCRIBE\n'; kubectl describe "$target" -n "$namespace"
  printf '\n### RELATED EVENTS\n'; kubectl get events -n "$namespace" --field-selector="involvedObject.name=$name" --sort-by=.metadata.creationTimestamp
  case "$target" in pod/*|pods/*|deploy/*|deployment/*|statefulset/*|sts/*|daemonset/*|ds/*|job/*)
    printf '\n### RECENT LOGS\n'; kubectl logs "$target" -n "$namespace" --all-containers=true --prefix --timestamps --tail=100 2>&1 || true ;;
  esac
}

kcan() {
  [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { printf 'usage: kcan VERB RESOURCE [NAMESPACE]\n' >&2; return 2; }
  kubectl auth can-i "$1" "$2" -n "${3:-$(_kube_namespace)}"
}

krbac() { kubectl auth can-i --list -n "${1:-$(_kube_namespace)}"; }

# High-frequency, read-only aliases. Destructive actions intentionally remain functions.
alias kc='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgsts='kubectl get statefulsets'
alias kgj='kubectl get jobs'
alias kgcj='kubectl get cronjobs'
alias kgcm='kubectl get configmaps'
alias kgsec='kubectl get secrets'
alias kgns='kubectl get namespaces'
alias kgn='kubectl get nodes -o wide'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe service'
alias kl='kubectl logs --timestamps'
alias klf='kubectl logs --timestamps --follow'

# Reuse kubectl's Bash completion when it has been loaded already.
if type __start_kubectl >/dev/null 2>&1; then
  complete -o default -F __start_kubectl kc 2>/dev/null || true
fi
