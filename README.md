# Deploy ANY virtual machine on Azure using Bicep
This guide will help you customise and deploy (almost) any virtual machine from Microsoft Azure, preconfigured for data science applications.

This is an example of deploying cloud infrastructure-as-code using a new domain specific language called Bicep. The [OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro) is Linux Ubuntu 18.04 and is specially setup with 150GB of goodies including native support for Python, R, Julia, SQL, C#, Java, Node.js, F#. If you don't know linux, don't worry: out of the box it autoruns a Jupyter Hub server giving you instant (secure) access to Jhub notebooks from the browser of your local machine, running remotely on your VM. Deploying in seconds, you will have access to beast VMs with up to 416 cores, 11000+ GB RAM and 1500+ MBit/s internet speeds. Pricing for VMs ranges from 1 cent to 120 $USD/hr and a free trial gets you $200 USD of credit for 30 days, with some important caveats.

This is designed for one-off time-constrained tasks where you need a dedicated beefy VM to run for a few hours or days to get the job done. You can then export any data, and tear the whole resource down when you're finished. In particular: this is for when you need more hardware than your local machine or the free/premium note-book-as-a-service platforms like Google Colab can provide.

## Quickstart

If you know what you are doing with deploying Azure resources using ARM templates (and Bicep), simply open the `vmtemplate.bicep` file , configure your VM specs, create a resource group and deploy in the Az CLI with a single command:

`az deployment group create -f vmtemplate.bicep -g <RESOURCE GROUP NAME> --parameters adminUsername='USERNAME' adminPassword='PASSWORD' adminPublicKey='INSERT FULL ASCII PUB KEY HERE'` 

Notes:
- username and password should be wrapped in quotations '' or special characters don't detect properly
- password needs to be decent (1 capital, 1 number, 1 special) 
- passing a public (ssh) key is OPTIONAL. You do not need to create an SSH key-pair if you only want to access your machine via JHub (as JHub requires the user/pass).
- For JHub and other services exposed to the internet, the vm creates a self-signed certificates for HTTPS (TLS/SSL). When you try to connect, modern browsers will still throw a tanty. Just click through the security warnings and you can connect ok, and be confident that you are accessing the services over an encrypted protocol.

Once deployed, grab the public IP address of the new vm (from Portal or CLI) and either SSH into the VM directly or access the Jupyter Hub server in the browser via `https://xxx.xxx.xxx.xxx:8000`. 


## Guide for Beginners

If you are new to cloud infrastructure and scared at this point, worry not. Follow this crash course below and you will be up and running in no time with a a fully dedicated VM. I've also published an article **INSERT LINK** that provides a full explanatory overview with much more detail. Here's what you're going to do: in a single command you will compile a Bicep file (high level language describing the infrastructure) into an Azure Resource Manager (ARM) template (a lower level abstraction in JSON) and then build the resources needed in Azure. It takes about 2 mins to deploy and you can be running JHub notebooks over the internet on your remote vm. If you are new to Microsoft cloud, I'd recommend getting a [free Microsoft Azure account](https://azure.microsoft.com/en-gb/free/), so you can play around within the limitations of the trial at zero cost.

For the Python JHub users, you might be used to running JHub from your local machine (and being constrained by crappy laptop hardware) or from Google Colab (with limited ram and storage and annoying timeouts). THIS VM IS YOUR OWN PRIVATE JHUB SERVER, with all the horsepower you are willing to pay for. Need 500GB Ram and 64 cores for 3 hours? Just deploy the VM in seconds and get the job done like a pro.

This example demonstrates how to build cloud infrastucture-as-code. It's important to understand that when you provision a virtual machine there are other cloud resources that are also needed in the ecosystem; it's not just the VM that gets provisioned in isolation. To deploy a VM with some ports exposed to the internet, for example, what you are doing in reality within Azure is building a virtual network, subnet within the network, virtual network interface card, network security group (controls things like which ports to open/close), storage account with persistent disk (preloaded with an operating system), the virtual machine itself (which is really the compute cpu-ram component) and a public facing IP to bind to the network interface card so you can access the VM over the internet. Yes it's slightly terrifying at first but I promise it's not too bad once you get the basics. All this magic happens in one elegant step so you don't need to worry about the complexity and can focus on what you do best: the _science_ of data :)

Here is the network topography just to give you a picture of the end product that is built from this template.

### Use this template when
- You need raw horsepower to get the job done (e.g. 256GB+ RAM, 16+ cores)
- You want total and exclusive control of your hardware (no managed services etc)
- Your local machine or any of the Colab cloud notebook environments are simply not up to the task
- You want to say: "just call me bad ass..." 

### Alternatives
- Google Colab
- Azure Notebooks (quite similar to this and have a free/paid tier for VMs. You don't have FULL access to your vm though)
<<MORE>>

### Why virtual machines?
1. Scalability and choice: access hundreds of cores and thousands of GBs of RAM.
2. Pay for just what you use (billed per second)
3. Insane internet speed (I've clocked 1,540 MBit/second download speed with a typical 4 core VM)

### Making sense of VM Machine Types in Azure
I think most heavy-weight data science applications require high in-memory processing, and parallel core processing either with CPU or GPU. As a result I think the VM types of most interest are D/E/M/N Series. 

For non-GPU applications in data engineering and M/L, I think the D/E series get you a solid all-rounder setup with up to 96 cores and 672GiB RAM in a single instance, plus many options to suite a specific project. For example, an 'E16as_v4' will get you 16 x 2.35Ghz cores, 128GiB RAM and 256GB of temporary SSD storage for about $1USD/hr.

If you are doing something crazy, the M series are straight out beasts and single instances can clock out to 416 cores and 11,400Gb RAM. I mean I don't know what you would use these for in datascience and they are, to be fair, more suited to hardcore enterprise applications. But they are there.

And for the rapidly evolving deep-learning folk, the new [N-series](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-gpu?context=/azure/virtual-machines/context/context) are for you. There are a number of variants and classess within but in essence you can customise the VM to get fractional access to GPU (e.g. 0.25GPU core) to 4 dedicated GPU cores per node. And you have access to Nvidia Tesla T4 and M60, Volta V100, AMD Radion Mi25 bolted to vms with latest generation CPU core banks from 4-64 cpu cores. I should note these are not available in the Free Trial, you must go to a paid plan. These are serious and I imagine what many of you might want to try. It's also worth mentioning here that Microsoft isn't known as the big player in GPU cloud offerings. It's fair to say this is Google and another of others. Bottom line is most of them offer GPU options and if this is critical to your work, then it's worth researching. I just happen to know Azure best.

The quick and dirty profile of machine types and what to care about for data science applications. There are many subvariants so this is just a flavour.

| Series | Profile                                            | CPU Cores   | GPU Cores    | RAM (GiB)        | Cost ($US/hr) | Verdict                                                                      |
|:------:|:--------------------------------------------------:|:-----------:|:------------:|:----------------:|:-------------:|:----------------------------------------------------------------------------:|
| A      | Testing/Dev                                        | 1 - 8       | -            | 2 - 64           | 0.05 - 0.8    | Not suitable                                                                 |
| B      | Burstable (CPU credits)                            | 1 - 20      | -            | 4 - 80           | 0.05 - 1      | Not suitable                                                                 |
| D      | All rounder                                        | 2 - 96      | -            | 4 - 384          | 0.1 - 5       | Suitable                                                                     |
| **E**  | **Memory optimised (high mem:cpu ratio)**          | **2 - 96**  | -            | **16 - 672**     | **0.1 - 7**   | **Highly suitable for data eng. & non-GPU M/L**                              |
| F      | Compute optimised (high cpu:mem ratio)             | 2 - 72      | -            | 4 - 144          | 0.1 - 3       | Not suitable                                                                 |
| G      | Hardcore Compute optimised (Big data)              | hidden      | -            | -                | -             | Not suitable                                                                 |
| H      | High Performance Compute (supercomputing)          | -           | -            | -                | -             | Not suitable                                                                 |
| L      | High Thoughput (I/O optimised)                     | 8 - 80      | -            | 6 - 640          | 0.7 - 7       | Suitable                                                                     |
| **M**  | **Absolute Beast**                                 | **8 - 416** | -            | **220 - 11,400** | **2 - 120**   | **Suitable for the brave**                                                   |
| **N**  | **GPU Optimised (fractional to multi GPU access)** | **4 - 64**  | **0.25 - 4** | **28 - 400**     | **1 - 20**    | **Highly suitable for deep learning and other M/L (Nvidia Tesla T4 or M60)** |

More info [here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/). Useful website [azurepricenet](https://azureprice.net/) allows you to zero in on the VM family and model you need, with pricing. 

It's worth noting that on a standard PAYG account you won't be able to provision a beast out of the box. All Azure accounts have soft and hard vcpu (core) quotas, so if you want anything beyond about 32 cores you will need to lodge a service desk request for a quota increase, which can take 48hrs to process.

### Where does my VM live?
Microsoft has datacenters across the world which you can visualise on a [map](https://azure.microsoft.com/en-gb/global-infrastructure/geographies/). Your VM will live in a datacenter of your choosing based on the location of the 'resource group' that you will set. There are marginal price differences between regions, but for this use case, the most important factor is to choose the closest zone to your present location, to minimise latency between you and the machine. For example "Central US" or "UK South".

### Can I just build a datascience VM using the Azure portal?
YES. 
In fact, I'd recommend you build your first VM using the [Azure portal](http://portal.azure.com), selecting the [data science OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro ). This is exactly the same OS image as I'm using in this build template. There are a few limitations to using the portal so you can't specify as many options but you can definitely get it up and access your vm on JHub etc. I hope this guide shows you how easy it can be to deploy infrastructure as code which is what is actually happening behind the scenes when you deploy from the Azure Portal anyway.

### How you are billed for VMs?
You pay by the second. And yes, leaving the VM on will rack up your credit card in a way you will not like (you are protected on the Free Account, don't worry).

Most of the other infrastructure is essentially free (the virtual network, subnet, public IP, etc). The key costs are the COMPUTE (the virtual machine) and STORAGE (the persistent disk attached to it).

Note the hourly rate is PAYG and if you have an ongoing demand for a vm, you can usually reduce the on-demand price by 60-70% on a 3yr reservation (which you can cancel at any time). Many VMs are also available on spot pricing which is alarmingly attractive. Don't fall for this. I don't think this is a good idea for data science applications because you typically require long uninterrupted processing. On the spot market, your VM can be pulled without warning. PAYG is the only way to get guaranteed exclusivity while using the resource.

**Golden rule is: always remember to turn you vm off or tear down all resources** You can temporarily deprovision it, preserving the OS disk but saving on the run-time instance of your VM,  or you can delete the whole resource group when you are finished. More on this later.

### What is the best VM available on the free trial?
The 30 day free trial gets you 200 USD of credit which is great, but note some important limitations below:
- Max cores: 4 per region (meaning no big bad wolf VMs on free account)
- No access: GPU VM series (upgrade to PAYG account to access N-Series GPU optimised vms, starting at about 1USD/hr)

Most beastly setup on free account: 'Standard E4s_v4' (the default in my template)
- 4 cores (Intel Xeon Platinum 8272CL base core clock 2.5GHz which can increase to 3.4Ghz all cores)
- 32GB ram
- 1TiB Premium SSD disk (Fastest OS disk type)
- Insane internet speeds (Typically 1000+ MBit/second)

This package will burn ~$10USD credit/day and you can run it full throttle 24-7, uninterrupted with no cpu constraints for 20 days until free credit depletes.

### How does storage work with vms?
All VMs need a managed persistent disk for the OS image. You can attach additional disk (several usually) and mount them on the filesystem but note this is fidly if you are not comfortable with linux. By far, the quickest and easiest option is to just beef up the OS disk size (up to 32TiB SSD) to what you need for the task. 

### How do I transfer data to and from my VM?
This is a full blown remote linux machine so it's not as straight forward as copy-pasting documents to your windows filesytem when you are running a localhost JHub server. But, the beauty is that you can do most of your uploading/downloading directly through the Jupyter Hub server by way of the browser, which should cover most people's needs. Don't forget you can rip down data from the internet at lightening speeds from your VM 10 times faster than on your home internet or Colab which is constrained to 130Mb/s, for example.

Getting data in:
- From your pc: use the JHub upload feature in browser or tools like `rsync` from a linux terminal (requires you to have WSL in windows)
- From the internet: wget/curl/github (just like you would in Colab)

Getting data out:
This is a little trickier than you think, but I have few standard recommendations.

- small (<30GB): use the JHub download feature in browser (the simplest)
- medium: (<1TB): use a linux data transfer application like `rsync` (requires linux on your local machine, native for MacOS but Windows you will need WSL)
- large: (+1TB): transfer to a cloud data storage service like Azure Blob, NFS. This will allow you to rapdidly get data out of the VM and shut it down, then you can connect direclty to the cloud storage service (much cheaper) to either download or store the data more long term.


## Instructions

Now that the crash course is complete, we can start with the step by step guide to deploy your vm infrastructure as code.

### Prerequisites
- Microsoft Azure account (e.g. [Free Trial](https://azure.microsoft.com/en-gb/free/) or pay-as-you-go)
- Strong cup of coffee

### 1. Install VS Code and Bicep/ARM extensions
Microsoft Visual Studio code is great for this project as it is open source and has downloadable extensions for bicep and ARM templates, meaning it colours the code really nicely to make it more readable. Download and install [VS Code](https://code.visualstudio.com/) with [ARM Tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools) and [Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) extensions. Note the extensions can be easily installed from within VS Code once it's running.

### 2. Install Azure CLI
What the hell is the Azure CLI? It's a dedicated program that provides a command line interface (i.e. CLI) for interacting directly with Azure resources. This means you can build and tear down infrastructure at command line like a boss, rather than doing it from the web browser portal. The most straight forward way is to [install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) which can run on Windows, MacOS, and Linux. 

**Do I absolutely need to us the Azure CLI?**
For this complete example, Yes. Because there are some limitations with the portal interface. In general: No. If you just want to build a VM using a username/password with the datascience OS image, you can in fact do it all from the portal as a one-off if you need to.

### 3. Install Bicep
Bicep is a cool new domain-specific-language for deploying Azure resources in a much more simplified way than using ARM templates, which are in JSON format and can be painful to read when you start adding multiple pieces of infrastructure. Bicep files compile into Azure Resource Manager (ARM) templates, which can then be directly ingested by Azure to build infrastructure. Bicep scripts, therefore are a high-level abstraction that simplify the description of the infrastructure you want to build. It only takes a few mins to install Bicep. Follow the installation guide [here](https://github.com/Azure/bicep). 

### 4. Clone this repo
Copy this project repo to your local machine either from Github over browser as a straight download, or via git clone etc. If you are not familiar with github and git, really, you just need to get the `vmtemplate.bicep` file to your local machine.

### 5. Configure VM specs and access (the fun part)

Open the `vmtemplate.bicep` file in visual studio code. 

At the beginning of the file I've summarised all the knobs and dials you might want to turn to select and tweak your VM settings. By default, I've chosen the toughest setup I could find within the limits of a Free Account (This is an E4s_v4 with 128GB RAM, and a 1TB Premium SSD OS Drive). But of course you can mix and match practically any VM up to 4 cores on free account, and experiment with different HDD sizes and types. In brief, if you are on a free account, the default settings are optimised for the best 4 cores, most ram and best disk I could find. If you are on a PAYG account, you can go crazy.

Key decision points:
- VM Type - This is critical as it determines the number of cores, RAM, temporary storage, and other limitations in relation to I/O. Lookup what you want either on [Azure docs](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/) or on [azurenet](https://azureprice.net/). Modify the variable field as you need
- OS disk size - Default to 1TiB premium SSD, but you can choose anything up to 32TiB as a single disk.
- OS disk type Take special note there are 3 distinct classes of storage 'Premium_LRS' which is SSD, 'StandardSSD_LRS' which is constrained SSD media, then the good old fashioned hard disk drive 'Standard_LRS'. Standard SSD is half the price of premium ssd, and standard HDD is 1/4 the price of premium ssd. Refer to docs [here](https://azure.microsoft.com/en-gb/pricing/details/managed-disks/). In all datascience applications, I'd use nothing other than "Premium_LRS" for maximum performance. 

You will also need to decide on a username/password which you will use in the next step at deployment. This data will be passed a paramters at deployment-time and stored as secure strings by Azure.

Security settings:
- admin username: blah
- admin password: blah

### 6. Login to Azure

From the azure CLI:

`az login --use-device-code`

This should open the browser and get you to punch in a code displayed in the CLI

Check account selection

`az account list --output table`

Set subscription (if default is not correct)

`az account set --subscription <name>`

### 7. Create Azure resource group

In this example I'm creating a resource group called "beast" in the "Central US" region

`az group create --name beast --location "Central US"`

Check by typing

`az group list --output table`

After a few seconds, it should appear. You can check in portal.azure.com directly by searching for 'resource groups'

### 7a (OPTIONAL) Create SSH keypair

If you are running linux (WSL in Windows or MacOSX) you can create public/private key encryption files for secure shell access (SSH) to the VM. This is the safest way to do it, although note that Jupyter Hub does not support it. So no matter what, if you are planning to use JHub mainly, you will still need to use the user/pass. And from JHUB you can access a full root terminal to do whatever you need. So this is really only for more hardcore ppl that want to be able to directly SSH into the VM.

Create SSH keypair have have public key ready to pass in as paramater.

### 8. The great build

This is the moment you have been waiting for. Assuming you decided on username: jamesbond / password: G0|den3y3

From the Azure CLI ensure you navigate to the current working directory where the vmdeploy.bicep file resides. Compile and deploy the VM, passing in the paramaters for username and password

`az deployment group create -f vmtemplate.bicep -g beast --parameters adminUsername="jamesbond" adminPassword="G0|den3y3"`

Or the same deploy, with the optional public ssh key

`az deployment group create -f vmtemplate.bicep -g beast --parameters adminUsername=jamesbond adminPassword=G0|den3y3 adminPublicKey=<INSERT FULL ASCII PUB KEY HERE>` 

If it worked you should see something that looks like this

### 9. Connect to the machine over the browser via Jupyter Hub!

Your new VM has a bunch of services preconfigured, so after deployment, it immediately runs a range of containerised services (via Docker) including a Jupyter Hub service, exposed on port 8000. Jupyter Hub is (in part) a webserver and so you can directly connect to it from any browser over the internet. 

First get the IP address of your new vm:
- From Azure Portal: search for resource group, navigate to the correct group, click on the VM (and you can see the public IP top right)
- From Azure CLI: `az vm show -d -g <RESOURCE GROUP NAME> -n <VM NAME> --query publicIps -o tsv`

Open a browser and access Jupyter Hub webserver (which is running as a container service on your vm exposed via port 8000):

`https://xxx.xxx.xxx.xxx:8000`

Where the IP address is substituted for the x's. Your vm has generated it's own self signed SSL certificate to allow encrypted browser traffic (HTTPS). However, as this is not a public certificate, the browser will often kick up a warning when you first connect. Don't worry and you can usually click accept the risk, and 'go to site'. You should then see a Jupyter hub login screen:

<IMAGE>

Login to Jupyter Hub with the username and password you supplied for the VM at deployment

If it has worked, you will see the Jhub session that looks like this :D


## 10. Test the beast

Now are you are connected to your VM securely, it's time to test a few things. It's super important to note that connecting to your VM via JHub gives you full superuser access; you can open a linux terminal from within Jhub and do literally anything you as if you had connected via SSH.

new-> terminal

Check no. processors and ram
`htop`

Check available disk space
`df -h`

Check internet speed

Install a well loved program to check speed on linux

`sudo apt install speedtest-cli`

Run `speedtest`

Open a notebook

Download data


You now have a beast. Well if you are on the free account it's probably only 4 cores. But the same applies whether you have 4 cores or 400. It's all running the same OS so i you get familiar with this now, you will be ready to upgrade when the free trial is over.


Enjoy.

## 11. Importing and exporting data? Rsync? Can you download from jhub?
















