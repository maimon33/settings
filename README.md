# Settings manager

This repository makes personal workstation configuration repeatable without
turning the repository into a copy of private credentials. It currently has
two jobs:

- maintain Bash aliases and functions from one source-controlled location;
- make encrypted, local backups of explicitly selected sensitive paths, with a
  small audit trail and a localhost-only dashboard.

## Shell setup

Run this once from a clone of the repository:

```bash
./install.sh
```

That adds this single, idempotent line to both `~/.bash_profile` and
`~/.bashrc`:

```bash
[ -r "$HOME/.config/settings/profile.sh" ] && . "$HOME/.config/settings/profile.sh"
```

The generated profile points at this clone and loads `shell/aliases.sh`,
`shell/functions.sh`, the Kubernetes toolkit (`shell/kubernetes.sh`), cleanup
utilities (`shell/cleanup.sh`), and AWS helpers (`shell/aws.sh`). Add shared shell
behavior to those files. Put machine-specific exports, tokens, and personal aliases
in `~/.config/settings/local.sh`; it is deliberately outside the repository.
Open a new shell (or run `settings-reload`) after updating the clone. The
`settings` alias opens the management CLI. Later updates are a single command:

```bash
settings-sync
```

It fast-forwards this clone from Git, then reloads every shared alias and
function in the current shell.

## Kubernetes shell toolkit

If `kubectl` is installed, run `khelp` for the complete command index. The
toolkit covers context and namespace switching, resource discovery, logs and
shell access, guarded deploy/scale/rollout/node operations, YAML exports,
cross-namespace cloning, backups, RBAC checks, monitoring, and diagnostics.
`kubectl` is the only hard dependency; clone and resource-request analysis use
`jq`, while `fzf` adds an interactive context picker.

Mutating helpers show the current context and namespace and require typing
`yes`. Direct read-only shortcuts such as `kgp`, `kgd`, `kgn`, and `klf` do not
prompt. Namespace and cluster backups exclude Secrets unless
`--include-secrets` is explicitly supplied, create owner-only files, and are
API object snapshots—not substitutes for etcd or persistent-volume backups.

Examples:

```bash
k pods -A                     # friendly resource dispatcher
k svc                         # services in the current namespace
k get configmaps             # regular kubectl commands pass through
kc get pods                  # kc is the direct kubectl alias
kbash deployment/api         # shell into a running workload pod
kbash app=api sidecar        # select a ready pod by label and container
kctx                          # list contexts
kctx production              # switch context
kctx show production          # inspect context with credentials redacted
kctx export production prod.kubeconfig
kctx namespace production payments
kctx rename old-name new-name
kctx delete unused-context    # refuses to delete the current context
kctx create local docker-desktop docker-desktop default
kns payments                  # validate and switch namespace
khealth                       # compact operational health report
kapply k8s/                   # server dry-run, diff, confirm, apply
kscale deployment/api 4       # confirm, scale, wait for rollout
kclone configmap app dev      # sanitize and clone to namespace dev
kbackup-ns payments backups/payments
kbackup-cluster backups/all --include-secrets
```

Context exports are flattened, self-contained kubeconfig files and therefore
may contain credentials. They are written atomically with mode `600`. Context
rename, deletion, creation, and namespace changes require confirmation;
`kctx delete` protects the currently selected context. Run `kctx help` for the
full management command list.

## Cleanup and maintenance utilities

Cleanup commands are safe: all mutating operations prompt for confirmation before
proceeding. Run `_cleanup_help` for the complete command reference.

Cleanup operations:
```bash
cleanup-cache              delete ~/.cache and .cache folders recursively
cleanup-terraform          find and delete .terraform folders in current tree
cleanup-docker             run docker system prune -a
cleanup-tmp                purge ~/tmp and old /tmp files
cleanup-all                run all cleanup functions in sequence
```

Utilities and scheduling:
```bash
app-list                   show installed applications
app-usage                  show top running processes by memory usage
schedule-task CMD [WHEN]   schedule a command as a launchd agent
                           WHEN: daily (02:00), hourly, weekly, or HH:MM
```

Examples:
```bash
cleanup-terraform
schedule-task 'brew update' daily
schedule-task 'cleanup-all' 03:00
```

## AWS CLI helpers

AWS helpers wrap common CLI operations with sensible defaults and readable output.
All functions require `aws-cli` to be installed. Run `_aws_help` for the complete
command reference.

Identity and configuration:
```bash
aws_whoami                show current AWS account/user/role/credentials
aws_region [REGION]       show or set AWS region
```

EKS and EC2:
```bash
eks_ami KUBE_VERSION      get recommended EKS AMI ID (1.32+ supported)
eks_ami --list            check version availability and AWS docs
ec2_instances [TAG VAL]   list running instances (optionally filter by tag)
ec2_start INSTANCE_ID     start EC2 instance
ec2_stop INSTANCE_ID      stop EC2 instance
```

Secrets, IAM, and encryption:
```bash
secretsmanager_get NAME   fetch secret value
secretsmanager_list       list all secrets
iam_policies ROLE_NAME    list policies attached to IAM role
kms_decrypt FILE          decrypt KMS-encrypted file
```

RDS, Lambda, and CloudFormation:
```bash
rds_snapshots [DB_ID]     list DB snapshots
lambda_logs FUNCTION      tail Lambda function logs
cloudformation_stack_status STACK  show CloudFormation stack status
```

Examples:
```bash
eks_ami 1.32                              # get AL2023 AMI for EKS 1.32
ec2_instances Environment production      # list prod instances
lambda_logs my-function                   # stream logs
secretsmanager_get database-password      # fetch secret
aws_region us-west-2                      # change region
```

## Encrypted backups

Backups are opt-in. The tool does not scan your home directory, and it refuses
to keep an unencrypted archive. It uses GnuPG symmetric AES-256 encryption;
install `gpg` before running a backup.

1. Run `./install.sh`.
2. Create a protected passphrase file:

   ```bash
   umask 077
   mkdir -p ~/.config/settings-manager
   openssl rand -base64 48 > ~/.config/settings-manager/backup-passphrase
   ```

3. Edit `~/.config/settings-manager/settings.env` and ensure
   `BACKUP_PASSPHRASE_FILE` names that file. Optionally choose a backup
   destination and retention period there.
4. Add the only paths you want protected:

   ```bash
   ./bin/settingsctl edit-targets
   ./bin/settingsctl backup
   ```

`backup-paths.conf`, the passphrase, archives, and logs live under your user
configuration/state directories and are ignored by Git. Keep the passphrase
separate from the backup destination; losing it makes the archives
unrecoverable. Test restoring a copy before relying on these backups.

To schedule a daily 02:00 backup, run:

```bash
./bin/settingsctl schedule
```

On macOS this installs a per-user `launchd` agent that also runs once when it
is loaded. On other systems it installs a user crontab entry. The scheduled
job inherits the same opt-in target list and encryption requirement.

## Management console

The CLI is the main interface:

```text
settingsctl status             show configuration and most recent activity
settingsctl edit-targets       safely create/edit the target list
settingsctl targets            print the target list
settingsctl backup             run an encrypted backup now
settingsctl logs [lines]       view audit records (default: 100)
settingsctl schedule           install the daily scheduler
settingsctl serve              start the web dashboard
```

Run `./bin/settingsctl serve` and visit <http://127.0.0.1:8765>. The dashboard
binds only to loopback, displays the latest 100 activity records, and can edit
the target list. It does not expose the passphrase, archive contents, or an
operation to run backups from a browser.

## Repository layout

```text
shell/       shared aliases and functions
config/      safe examples, never your private values
bin/         installer, backup worker, CLI and scheduler installer
service/     macOS launchd template
web/         localhost dashboard
lib/         shared shell helpers
```

The previous one-file shell profile is retained as historical source material
at `source/.bash_profile`; it is no longer installed or overwritten.
