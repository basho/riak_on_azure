##Install Riak on Windows Azure

Steps to install Riak on Centos VMs using the Windows Azure platform:

1. Create CentOS VMs using the Preview Management Portal
2. Connect to the Centos VMs using PuTTY or SSH
3. Configure Centos and Riak using a shell script
4. Cluster Riak & load test data

#### Creating CentOS VMs

###### Sign up for Virtual Machine Preview feature

You will need to sign up for the Windows Azure Virtual Machines preview feature in order to create a virtual machine. You can also sign up for a free trial account if you do not have a Windows Azure account.

1. Navigate to https://account.windowsazure.com/ and sign in with your Windows Azure account.

2. Click preview features to view the available previews.

	[ screenshot ]

3. Scroll down to Virtual Machines & Virtual Networks and click try it now.

	[ screenshot ]

4. Select your subscription and click the check.

	[ screenshot ]

##### Create a virtual machine running CentOS Linux

1. Login to the Windows Azure (Preview) Management Portal using your Windows Azure account.

2. In the Management Portal, at the bottom left of the web page, click +New, click Virtual Machine, and then click From Gallery. 

	[ screenshot ]

3. Select a CentOS virtual machine image from Platform Images, and then click the next arrow at the bottom right of the page. 

	[ screenshot ]

4. On the VM Configuration page, provide the following information:
	- **If this is the first node**, select the "STANDALONE VIRTUAL MACHINE" radio button. **Otherwise**, select the "CONNECT TO EXISTING VIRTUAL MACHINE" radio button, and select the first node in the drop down list.*
	
	- Provide a Virtual Machine Name, such as "testlinuxvm".
	- Specify a New User Name, such as "newuser", which will be added to the Sudoers 	  list file.
	- In the New Password box, type a strong password.
	- In the Confirm Password box, retype the password.
	- Select the appropriate Size from the drop down list.
	- Click the next arrow to continue.

	[ screenshot ]

5. On the VM Mode page, provide the following information:

	- Select Standalone Virtual Machine.
	- In the DNS Name box, type a valid DNS address. For example, "testlinuxvm"
	- In the Storage Account box, select Use Automatically Generated Storage Account.
	- In the Region/Affinity Group/Virtual Network box, select a region where this virtual image will be hosted.
	- Click the next arrow to continue.

	[ screenshot ]

6. On the VM Options page, select (none) in the Availability Set box. Click the check mark to continue. 

	[ screenshot ]

7. Wait while Windows Azure prepares your virtual machine.

##### Configure Endpoints

Once the virtual machine is created you must configure endpoints in order to remotely connect.

1. In the Management Portal, click Virtual Machines, then click the name of your new VM, then click Endpoints.

2. Click Edit Endpoint at the bottom of the page, and edit the SSH endpoint so that its Public Port is 22.

3. **If this is the first node**, click Add Endpoint, leave 'Add Endpoint' check and hit the right arrow, and fill out the next form as follows:
	- Name: riak_web
	- Protocol: leave set to 'TCP'
	- Public Port: 8098
	- private Port: 8098

#### Connect to CentOS VMs using PuTTY or SSH

When the virtual machine has been provisioned and the endpoints configured you can connect to it using SSH or PuTTY.

##### Connecting Using SSH

**For Linux & Mac Users:**

	$ ssh newuser@testlinuxvm.cloudapp.net -o ServerAliveInterval=180
Enter the user's password.

**For Windows Users, use PuTTY:**

If you are using a Windows computer, connect to the VM using PuTTY. PuTTY can be downloaded from the PuTTY Download Page.

1. Download and save putty.exe to a directory on your computer. Open a command prompt, navigate to that folder, and execute putty.exe.

2. Enter the SSH DETAILS as found on the Node's Dashboard, i.e., "testlinuxvm.cloudapp.net" for the Host Name and "22" for the Port. 

	[ screenshot ]

#### Configure Centos and Riak using a shell script

1. On each node, once you've connected using the steps above, type:

	sudo su -

	curl -s http://<location>/azure_install_riak.sh | sh


** FOR THE FIRST NODE **, note the "INTERNAL IP ADDRESS" listed in the nodes dashboard.
	
	[ screenshot ]

** FOR ALL OTHER NODES **, use the "INTERNAL IP ADDRESS"" of the first node and execute:

	riak cluster join riak@<ip.of.first.node>

#### Cluster Riak & load test data

After all the nodes are installed, and joined using the steps above, connect to one of the nodes using SSH or PuTTY and execute the following:

	riak cluster plan
	
[ screenshot ]

If this looks good:

	riak cluster commit

To check the status of clustering use:

	riak member_status:

[ screenshot ]

##### Load test data

Execute on any one of the nodes:

	curl -s http://rekon.basho.com | sh
	
Visit DNS address listed in the Portal

	[ screenshot ]

Further Reading:

- http://wiki.basho.com/Basic-Riak-API-Operations.html
- ...