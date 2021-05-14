# Ansible - Multiple Jump Host Configuration

In order to run Ansible Playbooks and Ansible Tower Job Templates against your target devices, you must configure Ansible properly to connect to the target devices. Ansible typically is configured to communicate to target devices/servers (managed nodes) directly from the Ansible Control Node or Ansible Tower Node. This requires no special settings except the basic user, password, ssh key, etc to access the target. However the situation gets a little complex when you are required to go through one or more bastion or jump hosts.

A more advanced and real-world scenarios involves two completely separate infrastuctures from two different organizations who may be partnering and require integration between their infrastructure. This often means Ansible and/or Ansible Tower is sitting in one of the networks/infrastructure and must manage resources in the other infrastructure. Due to security and various other possible reasons, this connection can have multiple jump hosts involved.

This gets more complex when you additionally have to consider the fact that Ansible uses a different connection type when running network automation as compared with typical platform automation over standard SSH.

Lastly, we have to consider that these jump hosts will be required not only for network or platform automation but we will need to jump even if we wish to access an API service. This is the case when we want to pull dynamic inventory from a system that can only be accessed from the final jumphost. How do handle this? As typically Ansible requires/assumes a direct connection with respect to their dynamic inventory plugins.

We also have to handle the likelihood of each jumphost requiring different SSH port, different SSH key, and so on.

So let's look at how to solve this.

## Options

Jumps over SSH can be configured by using one of the two methods, both of which require setting the Ansible `ansible_ssh_common_args` inventory variable to pass some ssh parameters into the connection request.

### Option 1 - Using SSH Config

The simplest solution is to use an ssh `config` file. For Ansible this requires setting the `ansible_ssh_common_args` variable in your Inventory as such. This will tell SSH to load a specific config file for all the ssh settings.

```yaml
ansible_ssh_common_args: '-F ssh-config'
```

And [here is an example of the ssh config file](ssh.cfg) that defines multiple jumps. Notice the use of the `ProxyJump` option to reference a different host.

However in some cases you may not be able to use an ssh `config` file as this presents a possible security risk if other users can access the same ssh `config` file.

### Option 2 - Using ProxyCommand

Instead of using an ssh config file, the jumps can alternatively be defined by using the `ProxyCommand` SSH option. For a single jump, it's fairly straightforward and we set the `ansible_ssh_common_args` variable within our inventory to point to the single jumphost. Notice that it's critical to add the extra options `-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null` to ignore host key checking for both the jumphost and the target host/device. If you do not add this, you may get a strange "banner" error message from SSH that is very difficult to analyze.

```ini
ansible_ssh_common_args= -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -o ProxyCommand="ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i {{ lookup('env', 'JH1_SSH_PRIVATE_KEY') }} -W %h:%p -q {{ jh1_ssh_user }}@{{ jh1_ip }}"
```

This uses an environment variable and extra variables to allow for a flexible solution. These can be set on the commandline or optimally using Ansible Tower's custom Credential Type, which will be explained later in this document. Additionally, a more advanced ProxyCommand will be required for handling 2 or 3 jumphosts. This is shown in the [inventory file](inventory).

## Connection Type

For platform automation, Ansible uses the `ssh` connection plugin that supports OpenSSH.

For network automation, Ansible has various connection plugins but `network_cli` is recommended. This plugin allows you to use either `paramiko` or `libssh` for the transport method. The `libssh` transport is preferred as it will be the standard going forward for future releases of Ansible. The `libssh` was first introduced with the Ansible collection `netcommon`. For more information see [new libssh connection plugin for ansible network](https://www.ansible.com/blog/new-libssh-connection-plugin-for-ansible-network).

We have therefore defined the collection within our [collections/requirements.yml](collections/requirements.yml). Additionally we need to tell Ansible where to download the collections by adding options in the [setup.cfg](setup.cfg).

Now we can download the collections and install the required python library to prepare for using libssh.

```bash
# Download required collections
ansible-galaxy collection install -r collections/requirements.yml -f
# Install python library dependency with libssh
pip install ansible-pylibssh
```

## Accessing API

As previously stated, having one or more jumphosts often impacts accessing any API services on that destination infrastructure. For example, if we want to pull dynamic inventory from SolarWinds, Service Now, or others.

We can handle this in a similar manner as we did above with server/network automation endpoints. However, slightly different approach. Instead of focusing on formulating the `ansible_ssh_common_args` variable to perform the jumps, we need to modify an existing dynamic inventory script and adapt it to support multiple jumps.

In a recent case with a customer, we needed to pull dynamic inventory from SolarWinds, which was not directly available. We had an existing python-based dynamic inventory script that worked well but required a direct connection.

The following changes were applied to the original python script. These changes can be easily adapted to any inventory script by understanding the techniques and applying them to your own situation.

- The [jumpssh](https://jumpssh.readthedocs.io/en/latest/api.html) python module provides the ability to perform one or more jumps and prepare a [requests](https://docs.python-requests.org/en/master/) connection from a specific jumphost
- Code was added to allow import of `jumpssh` and create a `requests` session
- To allow flexibility in the inventory script, code was added to pull jumphost connectivity information using environment variables
- Code is flexible and only prepares as many jumps as defined by the environment variables; if you only define 1 jump, then only 1 jump is configured.
- Environment variables are injected either from commandline or using Ansible Tower custom Credential Type
- Add the `jumpssh` python module to your Ansible virtual environment or existing Ansible Tower virtual environment

    ```shell
    pip install jumpssh
    ```

It is important to understand that the python code establishes a direct session with the target system over one or more jumps. However Ansible still is executing the python locally - it is not performed on a jumphost.

## Solution

The following information covers the overarching solution.



Inputs:

[SolarWinds Credential Type - Inputs](tower_objects/solarwinds_credential_type_inputs.yml)

Injectors:

[SolarWinds Credential Type - Injectors](tower_objects/solarwinds_credential_type_injectors.yml)

## Demo Environment

The following was used to develop and test functionality for multiple jump hosts.

### Vagrant

In order to test and demo this functionality `vagrant` was used to spin up the jumphosts.

To test network automation using Ansible `network_cli` connection type, run the network device emulator `fake-switches` on one of your jump hosts. Depending on your situation, this may be the third jumphost or second, etc.

```shell
# Start machines
vagrant up
```

### Network Emulator

In order to fully develop and test functionality against a network device, the emulator [fake-switches](https://github.com/internap/fake-switches) was used as a dummy network device that could accept basic network switch commands.

To run `fake-switches` from one of the jumphosts you will need to provision the server using the [custom shell script](scripts/python3.sh).

```shell
# Start machines
vagrant up

# Login to final jumphost server
vagrant ssh jh3
# Provision server to install fake-switches
chmod +x python3.sh
./python3.sh

# Start network device emulator
fake-switches --listen-host localhost --listen-port 3080 --hostname switch.example.com
```

Start a new terminal window, connect to the machine and test you can ssh to the network device service.

```shell
vagrant ssh jh3
ssh root@switch.example.com -p 3080 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null
```

### Inventory Emulator

Additionally, SolarWinds was not available at the time so a [REST API emulator](scripts/restapi.py) was created that handles logins, and returns inventory structure similar to what would be expected from SolarWinds. It uses `flask` to rapidly develop a web service that accepts requests.

It can easily be adapted for other systems or services.

To run the emulator, login to the final jump host server and run the python script.

```shell
# Login to final jumphost server
vagrant ssh jh3
# Provision server to install python if not done already
chmod +x python3.sh
./python3.sh

# Start REST API emulator
python restapi.py
```

## Troubleshooting

- The `jumpssh` python module uses `paramiko` for ssh connections and I hit [this error](https://github.com/paramiko/paramiko/issues/340) initially which happens when your ssh private key file is not in `pem` format. The solution was to convert my private key file to `pem` format using this command: `ssh-keygen -f my-rsa-key -m pem -p`

- It helps a lot to use [this online YAML validator](https://codebeautify.org/yaml-validator) to ensure the complex jump host string is valid before using it in Ansible Tower.

- https://stackoverflow.com/questions/49701471/ansible-cisco-ios-command-module-unable-to-set-terminal-parameters
  Ansible network modules require the ability to run some `terminal` commands. Ensure your network device with your credential actually supports these commands by using a direct PuTTy session to login and manually run them. It could be that your credential does not have permission to run these commands.

- The formatting for the `ansible_ssh_common_args` variable is different when used in Ansible Tower versus on the command line! Be careful when formulating your own string.

- This error shows up sometimes and it's difficult to determine the root cause: [Error reading SSH protocol banner](https://github.com/ansible/ansible/issues/69267). One possible cause of this error is an incorrect or malformed SSH private key file. Convert your key files to the right format using the following example command: `ssh-copy-id -f -o 'IdentityFile ~/.ssh/vagrant_rsa' -i ./key-jh1.pub vagrant@jh1.example.com`

- Debug Ansible Tower issues by disabling cleanup of temporary execution environments. This will allow you to see what Ansible Tower is generating locally. Follow the steps below.

```shell
# Add this line to Ansible Tower configuration to disable cleanup
vi /etc/tower/conf.d/postgres.py
AWX_CLEANUP_PATHS = False

# Restart Ansible Tower to load new configuration
ansible-tower-service restart

# Debug existing Job Template
- Run Job Template in Tower
- The Job Template output window will state the /tmp folder created for this job
- Login to Tower server
- Sudo to `awx` user: `sudo su - awx`
- Navigate to the /tmp folder: `cd /tmp/awx_250_0z8b10uf/`
- List files: `ls -l`
- Examine the environment variables: `cat env/envvars`
- Determine the tmp files used for the private keys, for example: `"JH1_SSH_PRIVATE_KEY": "/tmp/awx_250_0z8b10uf/tmpm7dahf7w"`
- Test connectivity using this private key to first jumphost: `ssh -i /tmp/awx_250_0z8b10uf/tmpm7dahf7w -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@jh1.example.com`. In my case I got:
    ```
    Warning: Permanently added 'jh1.example.com,192.168.34.10' (RSA) to the list of known hosts.
    Load key "/tmp/awx_250_0z8b10uf/tmpm7dahf7w": invalid format
    vagrant@jh1.example.com: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
    ```
- Edit the private key and retest until it works
```

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
