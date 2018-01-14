# ansible-role-strongswan

Manage strongswan

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `strongswan_user` | User of `strongswan` | `{{ __strongswan_user }}` |
| `strongswan_group` | Group of `strongswan` | `{{ __strongswan_group }}` |
| `strongswan_package` | Package name of `strongswan` | `{{ __strongswan_package }}` |
| `strongswan_extra_packages` | List of additional package names to install | `[]` |
| `strongswan_log_dir` | Path to directory to create for logging | `""` |
| `strongswan_service` | Service name of `strongswan` | `strongswan` |
| `strongswan_conf_dir` | Path to configuration directory | `{{ __strongswan_conf_dir }}` |
| `strongswan_conf_file` | Path to `strongswan.conf` | `{{ __strongswan_conf_dir }}/strongswan.conf` |
| `strongswan_conf_d_dir` | Path to `strongswan.d` | `{{ __strongswan_conf_dir }}/strongswan.d` |
| `strongswan_config` | Content of `strongswan_conf_file` | `""` |
| `strongswan_ipsec_config` | Content of `ipsec.conf` | `""` |
| `strongswan_ipsec_secrets` | Content of `ipsec.secrets` | `{}` |
| `strongswan_config_fragments` | see below | `[]` |

## `strongswan_config_fragments`

A list of files under `strongswan_conf_d_dir`. Each element is a dict.

| Key | Description | Mandatory |
|-----|-------------|-----------|
| `name` | File name | yes |
| `path` | Path to the file | no |
| `mode` | File mode | no |
| `owner` | Owner of the file | no |
| `group` | group of the file | no |
| `content` | Content of the file | yes |

## Debian

| Variable | Default |
|----------|---------|
| `__strongswan_user` | `strongswan` |
| `__strongswan_group` | `nogroup` |
| `__strongswan_conf_dir` | `/etc` |
| `__strongswan_package` | `strongswan` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__strongswan_user` | `root` |
| `__strongswan_group` | `wheel` |
| `__strongswan_conf_dir` | `/usr/local/etc` |
| `__strongswan_package` | `security/strongswan` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-strongswan
  vars:
    strongswan_log_dir: /var/log/strongswan
    strongswan_ipsec_secrets:
      no_log: no
      path: "{{ strongswan_conf_d_dir }}/ipsec.secrets"
      owner: daemon
      group: daemon
      mode: "0640"
      content: |
        192.168.0.1 : PSK "v+NkxY9LLZvwj4qCC2o/gGrWDF2d21jL"
        192.168.0.2 : PSK "v+NkxY9LLZvwj4qCC2o/gGrWDF2d21jL"
    strongswan_config_fragments:
      - name: empty
        path: "{{ strongswan_conf_d_dir }}/empty.conf"
        mode: "0640"
        owner: daemon
        group: daemon
        no_log: no
        content: |
          # intentinally empty
      - name: charon-logging.conf
        content: |
          charon {
            syslog {
              daemon {
                default = 2
              }
              auth {
                default = 2
              }
            }
          }
    strongswan_config: |
      charon {
        load_modular = yes
        plugins {
          include {{ strongswan_conf_d_dir }}/charon/*.conf
        }
      }
      include strongswan.d/*.conf
    strongswan_ipsec_config: |
      config setup

      conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2

      conn rw-eap
        left={{ ansible_default_ipv4.address }}
        leftsubnet=172.16.0.0/24
        leftcert=moonCert.pem
        leftauth=eap-peap
        leftfirewall=yes
        rightauth=eap-peap
        rightsendcert=never
        right=%any
        auto=add
```

# License

```
Copyright (c) 2018 Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

This README was created by [qansible](https://github.com/trombik/qansible)
