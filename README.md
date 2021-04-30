# Ansible Tower - Multiple Jump Host Configuration

Ansible must be configured to connect to your target devices. However, there are 3 major scenarios.

## Direct Connection

Ansible typically is configured to communicate to target devices/servers (managed nodes) directly from the Ansible Control Node or Ansible Tower Node. This requires no special settings except the basic user, password, ssh key, etc to access the target.

## Single Jump Host

In some cases Ansible Control Node or Tower Node requires going through 1 jump host (or bastion host). This is typically handled via the `ProxyCommand` ssh parameter and using the Ansible `ansible_ssh_common_args` inventory variable to pass these ssh parameters into the connection request. Again, this is fairly straightforward and works well.

## Multiple Jump Host

More advanced and real-world scenarios involve two completely separate infrastuctures from two different organizations who may be partnering and require integration between their infrastructure. This often means Ansible Tower is sitting in one of the networks/infrastructure and must manage resources in the other infrastructure. Due to security and various other possible reasons, this connection often has multiple jump hosts involved.

This can again be easily configured using the `ansible_ssh_common_args` inventory variable to set the `ProxyCommand` parameter.

For server automation, Ansible uses the `ssh` connection plugin that supports OpenSSH.

For network automation, Ansible can use various connection plugins but the recommended plugin is the `network_cli`. This plugin allows you to use either `paramiko` or `libssh` for the transport method. The `libssh` transport is preferred as it will be the standard going forward for future releases of Ansible.

## Connection Types

`libssh` was first introduced with Ansible collection `netcommon`.

## Example

Below is an example `inventory` file that configures a multiple jump host setup.

```ini

```

## Prepare Network Device

```
vagrant ssh jh3
fake-switches --listen-host localhost --listen-port 3080 --hostname switch.example.com
```

Start a new terminal window, connect to `jh3` machine and test you can ssh to the network device service.
```
vagrant ssh jh3
ssh root@switch.example.com -p 3080 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null
```

## Troubleshooting

If you get the following error message, then you do not have the correct formatting for the `ansible_ssh_common_args` variable:

`Error reading SSH protocol banner`
https://github.com/ansible/ansible/issues/69267

One cause of this error is incorrect or malformed SSH private key in the Credential. It is essential to 

ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh1.pub vagrant@jh1.example.com
ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh2.pub vagrant@jh2.example.com
ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh3.pub vagrant@jh3.example.com

export JH3_SSH_PRIVATE_KEY=/Users/jwadleig/Projects/customer-ibm-dow/tower-multiple-jumphost/key-jh3

export JH1_SSH_PRIVATE_KEY=~/.ssh/vagrant_rsa
export JH2_SSH_PRIVATE_KEY=~/.ssh/vagrant_rsa
export JH3_SSH_PRIVATE_KEY=~/.ssh/vagrant_rsa


# Add this to Tower
/etc/tower/conf.d/postgres.py
AWX_CLEANUP_PATHS = False
ansible-tower-service restart
- Run Job Template in Tower
- The Job Template output window will state the /tmp folder created for this job
- Login to Tower server
- Sudo to `awx` user: `sudo su - awx`
- Navigate to the /tmp folder: `cd /tmp/awx_250_0z8b10uf/`
- List files: `ls -l`
- Examine the environment variables: `cat env/envvars`
- Determine the tmp files used for the private keys, for example: `"JH1_SSH_PRIVATE_KEY": "/tmp/awx_250_0z8b10uf/tmpm7dahf7w"`
- Test connectivity using this private key to first jumphost: `ssh -i /tmp/awx_250_0z8b10uf/tmpm7dahf7w -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@jh1.example.com`

```
Warning: Permanently added 'jh1.example.com,192.168.34.10' (RSA) to the list of known hosts.
Load key "/tmp/awx_250_0z8b10uf/tmpm7dahf7w": invalid format
vagrant@jh1.example.com: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```
- Edit the private key and retest until it works
