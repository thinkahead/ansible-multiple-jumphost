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

## Example

Below is an example `inventory` file that configures a multiple jump host setup.

```ini

```