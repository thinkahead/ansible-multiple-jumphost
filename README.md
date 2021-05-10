# Ansible Tower - Multiple Jump Host Configuration

In order to run Ansible Playbooks and Ansible Tower Job Templates against your target devices, you must configure Ansible properly to connect to the target devices. Ansible typically is configured to communicate to target devices/servers (managed nodes) directly from the Ansible Control Node or Ansible Tower Node. This requires no special settings except the basic user, password, ssh key, etc to access the target. However the situation gets a little complex when you are required to go through 1 or more bastion or jump hosts.

More advanced and real-world scenarios involve two completely separate infrastuctures from two different organizations who may be partnering and require integration between their infrastructure. This often means Ansible Tower is sitting in one of the networks/infrastructure and must manage resources in the other infrastructure. Due to security and various other possible reasons, this connection often has multiple jump hosts involved.

## Options

Jumps over SSH are handled by using one of the following two methods:

- Defining the jumps within the ssh-config file
- Defining the jumps using one or more calls to the `ProxyCommand` ssh parameter

Both cases require setting the Ansible `ansible_ssh_common_args` inventory variable to pass these ssh parameters into the connection request.

The simplest solution is to use an ssh-config file. This would require to add the `ansible_ssh_common_args: '-F ssh-config'` to your inventory. However in some cases you may not be able to use an ssh-config file as this presents a possible security risk if other users can access the same ssh-config file.

## Connection Type

For server automation, Ansible uses the `ssh` connection plugin that supports OpenSSH.

For network automation, Ansible has various connection plugins but `network_cli` is recommended. This plugin allows you to use either `paramiko` or `libssh` for the transport method. The `libssh` transport is preferred as it will be the standard going forward for future releases of Ansible. The `libssh` was first introduced with the Ansible collection `netcommon`. For more information see [new libssh connection plugin for ansible network](https://www.ansible.com/blog/new-libssh-connection-plugin-for-ansible-network).

```bash
# Download required collections
ansible-galaxy collection install -r collections/requirements.yml -f
# Install python library dependency with libssh
pip install ansible-pylibssh
```

## Solution

Inputs:

[SolarWinds Credential Type - Inputs](solarwinds_credential_type_inputs.yml)

Injectors:

[SolarWinds Credential Type - Injectors](solarwinds_credential_type_injectors.yml)

## Demo Environment

In order to test and demo this functionality we have used `vagrant` to spin up 3 jumphosts and run a network device emulator `fake-switches` on the 3rd jumphost.

```shell
# Start machines
vagrant up

# Start network device emulator
vagrant ssh jh3
fake-switches --listen-host localhost --listen-port 3080 --hostname switch.example.com
```

Start a new terminal window, connect to `jh3` machine and test you can ssh to the network device service.

```shell
vagrant ssh jh3
ssh root@switch.example.com -p 3080 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null
```


## Accessing API from Jumphost

With the above multi-jump situation we might also require Ansible Tower to pull dynamic inventory from a remote source that can only be reached from a specific jumphost (a direct connection cannot be established due to security reasons). We can handle this in a similar manner as we did above with server/network automation endpoints. However, slightly different approach. Instead of focusing on formulating the `ansible_ssh_common_args` variable to perform the jumps, we need to modify an existing dynamic inventory script and adapt it to support multiple jumps.

In the case with an existing customer, we needed to pull dynamic inventory from SolarWinds, which was not directly available. We had an existing python-based dynamic inventory script that worked well with a direct connection. The following major changes were added to the original working script. These changes can be adapted to any inventory script by understanding the techniques and applying them to your own situation.

- The `jumpssh` python module provides the ability to perform the 3 jumps and prepare a `requests` connection from a specific jumphost
- Inventory script needed to pull environment variables that provided connectivity information for all jumphosts

Run the SolarWinds dynamic inventory script.


## Troubleshooting

- The `jumpssh` python module uses `paramiko` for ssh connections and I hit [this error](https://github.com/paramiko/paramiko/issues/340) initially which happens when your ssh private key file is not in `pem` format. The solution was to convert my private key file to `pem` format using this command: `ssh-keygen -f my-rsa-key -m pem -p`

- It helps a lot to use [this online YAML validator](https://codebeautify.org/yaml-validator) to ensure the complex jump host string is valid before using it in Ansible Tower.

- https://stackoverflow.com/questions/49701471/ansible-cisco-ios-command-module-unable-to-set-terminal-parameters
  Ansible network modules require the ability to run some `terminal` commands. Ensure your network device with your credential actually supports these commands by using a direct PuTTy session to login and manually run them. It could be that your credential does not have permission to run these commands.

- The formatting for the `ansible_ssh_common_args` variable is different when used in Ansible Tower versus on the command line! Be careful when formulating your own string.

- `Error reading SSH protocol banner`
  https://github.com/ansible/ansible/issues/69267

One cause of this error is incorrect or malformed SSH private key in the Credential. It is essential to 

ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh1.pub vagrant@jh1.example.com
ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh2.pub vagrant@jh2.example.com
ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh3.pub vagrant@jh3.example.com

export JH1_SSH_IP=jh1.example.com
export JH1_SSH_PORT=22
export JH1_SSH_USER=vagrant
export JH1_SSH_PRIVATE_KEY=/Users/jwadleig/Projects/customer-ibm-dow/tower-multiple-jumphost/key-jh1
export JH2_SSH_IP=jh2.example.com
export JH2_SSH_PORT=22
export JH2_SSH_USER=vagrant
export JH2_SSH_PRIVATE_KEY=/Users/jwadleig/Projects/customer-ibm-dow/tower-multiple-jumphost/key-jh2
export JH3_SSH_IP=jh3.example.com
export JH3_SSH_PORT=22
export JH3_SSH_USER=vagrant
export JH3_SSH_PRIVATE_KEY=/Users/jwadleig/Projects/customer-ibm-dow/tower-multiple-jumphost/key-jh3


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

## Resources

- IBM Multiple Jumphost in Ansible Tower
  https://developer.ibm.com/recipes/tutorials/multiple-jumphosts-in-ansible-tower-part-1/
  https://github.com/thinkahead/DeveloperRecipes/tree/master/Jumphosts
- Deep dive with network connection plugins - AnsibleFest 2019
  https://www.ansible.com/hubfs//AnsibleFest%20ATL%20Slide%20Decks/Deep%20dive%20with%20network%20connection%20plugins%20-%20AnsibleFest%202019.pdf
- Fake Switches Python Tool
  https://github.com/internap/fake-switches
- New LibSSH Connection Plugin for Ansible Network
  https://www.ansible.com/blog/new-libssh-connection-plugin-for-ansible-network
- Ansible Connection Plugins from Netcommon Collection
  https://github.com/ansible-collections/ansible.netcommon/tree/main/plugins/connection
- Ansible 2.9 Network Platform Options
  https://docs.ansible.com/ansible/2.9/network/user_guide/platform_index.html#settings-by-platform

