# chef-workstation-cosmic

A Chef-Workstation Docker image for use with Cosmic

## Usage

All the magic is in the [entrypoint](docker-entrypoint.sh). Run the image with the following variables for the desired effect:

| Variable           | Effect                                                                                        |
| ------------------ | --------------------------------------------------------------------------------------------- |
| `$GIT_PRIVATE_KEY` | Loads an SSH agent and adds the specified SSH key                                             |
| `$CHEF_REPO`       | Git path to a chef-repo to install at `~/.chef` (used in combination with `$GIT_PRIVATE_KEY`) |
| `$CHEF_USER`       | Chef user                                                                                     |
| `$CHEF_PEM`        | Chef user pem (is written to `~/.chef/${CHEF_USER}.pem`)                                      |

Example:

```shell
$ docker run --rm -it -e GIT_PRIVATE_KEY="$(cat ~/.ssh/id_rsa_no_password)" missioncriticalcloud/chef-workstation-cosmic:latest /bin/bash
Chef Workstation version: 0.16.31
Chef Infra Client version: 15.8.23
Chef InSpec version: 4.18.85
Chef CLI version: 2.0.0
Test Kitchen version: 2.3.4
Cookstyle version: 5.21.9

Setting up SSH Agent...
Adding private key...
Identity added: /dev/fd/63 (/dev/fd/63)

root@e6e0c212dd44:/#
```