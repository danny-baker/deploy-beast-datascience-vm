# Deploy ANY virtual machine on Azure 
This guide will help you customise and deploy any virtual machine from Microsoft Azure, preconfigured for data science applications.

The [OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro) is Linux Ubuntu 18.04 and is specially setup with 150GB of goodies including native support for Python, R, Julia, SQL, C#, Java, Node.js, F#. If you don't know linux, don't worry: out of the box it autoruns a Jupyter Hub server giving you instant (secure) access to Jhub notebooks from the browser of your local machine. Deploying in seconds, you will have access to beast VMs with up to 416 cores, 11000+ GB RAM and 1500+ MBit/s internet speeds. Pricing for VMs ranges from 1 cent to 120 $USD/hr and a free trial gets you $200 USD of credit for 30 days, with some important caveats.

This is designed for one-off time-constrained tasks where you need a monster of a VM to run for a few hours or days to get the job done. You can then export any data, and tear the whole resource down. 

## Quickstart

If you know what you are doing with deploying Azure resources, simply open the vmtemplate.bicep, configure your VM specs, create a resource group and deploy in the Az CLI with:

`az deployment group create -f vmtemplate.bicep -g <RESOURCE GROUP> --parameters adminUsername=<USERNAME> adminPassword=<PASSWORD> adminPublicKey=<INSERT FULL ASCII PUB KEY HERE>` 

**[have option without public key]**

Note:
- password needs to be decent (1 capital, 1 number, 1 special etc) 
- you must also pass a valid public ssh key as a parameter aswell. **[TO FIX]**
- Once deployed, either SSH into the VM directly or access JHUB in the browser via `https://xxx.xxx.xxx.xxx:8000` once you have the public IP address of the VM (from Portal or Az CLI)

## Guide for Beginners

If you are new to cloud infrastructure and scared at this point, worry not. Follow the guide below and you will be up and running in no time with a a fully dedicated VM. I've also published an article **INSERT LINK** that provides a full explanatory overview with much more detail. In a single command you will compiling a Bicep file (high level language describing the infrastructure) into an Azure Resource Manager (ARM) template (a lower level abstraction in JSON) and then building the resources in Azure. It takes about 1-2 mins to deploy and you can be running JHub notebooks on your new vm. For newbies I'd recommend getting a free Microsoft Azure account, so you can play around within the limitations of the trial at zero cost.

This example demonstrates how to build cloud infrastucture-as-code like a boss. It's important to understand when you provision a virtual machine there are other cloud resources that are also needed in the ecosystem; it's not just the VM that gets provisioned in isolation. To deploy a VM with some ports exposed to the internet, for example, what you are doing in reality is building a virtual network, subnet within the network, virtual network interface card, network security group (controls things like which ports to open/close), storage account with persistent disk (preloaded with an operating system), the virtual machine itself (which is really the compute cpu-ram component) and a public facing IP to bind to the network interface card so you can access the VM over the internet. Yes it's slightly terrifying at first but I promise it's not too bad once you get the basics. All this magic happens in one step so you don't need to worry about the complexity and can focus on what you do best: the science of data :)

Here is the network topography just to give you a picture of the end product

### Why virtual machines?
1. Scalability and choice: access hundreds of cores and thousands of GBs of RAM.
2. Pay for just what you use (billed per second)
3. Insane internet speed (I've clocked 1,540 MBit/second download speed with a typical 4 core VM)

### Use this project when
- You need raw horsepower to get the job done (e.g. 256GB+ RAM, 16+ cores)
- You want total control of your hardware (no managed services etc)
- Your local machine or any of the Colab cloud notebook environments are simply not up to the task
- You want to say: "just call me bad ass..." 

### Alternatives
- Google Colab
- Azure Notebooks (quite similar to this and have a free/paid tier for VMs. You don't have FULL access to your vm though)
<<MORE>>

### Making sense of VM Machine Types in Azure
I think most heavy weight data science applications require high in-memory processing, and parallel core processing either with CPU or GPU. As a result I think the VM types of most interest are D/E/N Series. The D/E series get you a solid non-GPU setup for example, an 'E16as_v4' will get you 16 x 2.35Ghz cores, 128GiB RAM and 256GB of temporary SSD storage for about $1USD/hr. Not bad if you just need to run it for 6 hours to finish an experiment.

The quick and dirty profile of machine types and what to care about for data science applications. There are many subvariants so this is just a flavour.
- A Series: Testing. 1-8 core, 2-64 GiB RAM, 0.05-0.786USD/hr. Not suitable.
- B Series: Burstable with CPU compute credits. 1-20 core, 4-80 GiB RAM, 0.0059-0.944USD/hr. Not suitable.
- **D Series: All rounder. 2-96 core, 4-384GiB RAM, 0.1-5.3USD/hr. Suitable. **
- **E Series: Memory optimised (higher memory:cpu ratio) 2-96 core, 16-672GiB RAM, 0.1-$7USD/hr. Highly Suitable for data engineering (No GPU).**
- F Series: Compute optimised (higher cpu:memory ratio). Not suitable.
- G Series: Compute optimised (Big data type databases). Not suitable.
- H Series: High Performance Compute (Only accessible via cyclecloud and more suited for weather prediction models etc). Not suitable.
- L Series: High Throughput (I/O Optimised). 8 - 80 cores, 6-640GiB RAM, 0.7-7 USD/hr. Suitable.
- **M Series: Beasty. 8 - 416 cores, 220 - 11,400GiB RAM, 2-120 USD/hr. Suitable only for the bravest.**
- **N Series: [GPU optimised family](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-gpu). 4-64 cores, 0-4 GPU cores (Nvidia Tesla T4 or M60), 28-440 GiB RAM, 1 - 20 USD/hr. Highly Suitable for deep learning and other M/L.**

More info [here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/). Useful website [azurepricenet](https://azureprice.net/) allows you to zero in on the VM family and model you need, with pricing. 

It's worth noting that on a standard PAYG account you won't be able to provision a beast out of the box. All Azure accounts have soft and hard vcpu (core) quotas, so if you want anything beyond about 32 cores you will need to lodge a service desk request for a quota increase, which can take 48hrs to process.

### Can I just build a datascience VM in the Azure portal?
YES. 
In fact, I'd recommend you first build a VM use the portal, selecting the [data science OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro ). This is exactly the same OS image as I'm using in this build template. There are a few limitations to using the portal so you can't specify as many options but you can definitely get it up and access it on JHub etc. I hope this guide shows you how easy it can be to deploy infrastructure as code which is what is actually happening behind the scenes when you deploy from the Portal anyway.

### How you are billed for VMs?
You pay by the second. And yes, leaving the VM on will rack up your credit card in a way you will not like (you are protected on the Free Account, don't worry).

Most of the other infrastructure is essentially free (the virtual network, subnet, public IP, etc). The key costs are the COMPUTE (the virtual machine) and STORAGE (the persistent disk attached to it).

Note the hourly rate is PAYG and if you have an ongoing demand for a vm, you can usually reduce the on-demand price by 60-70% on a 3yr reservation (which you can cancel at any time). Many VMs are also available on spot pricing which is alarmingly attractive. Don't fall for this. I don't think this is a good idea for data science applications because you typically require long uninterrupted processing. On the spot market, your VM can be pulled without warning. PAYG is the only way to get guaranteed exclusivity while using the resource.

### What is the best VM available on the free trial?
The 30 day free trial gets you 200 USD of credit, but note some important limitations below:
- Max cores: 4 per region (meaning no big VMs on free account)
- No access: GPU VM series (upgrade to PAYG account to access, starting at about 0.5USD/hr)

Most beastly setup on free account: 'Standard E4s_v4' (setup as default in template)
- 4 cores (Intel Xeon Platinum 8272CL base core clock 2.5GHz which can increase to 3.4Ghz)
- 32GB ram
- 1TiB Premium SSD disk (Fastest OS disk type)
- Insane internet speeds (Typically 1000 MBit/second)

This package will burn ~$10USD credit/day and you can run it full throttle 24-7, uninterrupted with no cpu constraints for 20 days until credit depletes.


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

Open the vmtemplate.bicep file in visual studio code. Here you can set the VM type (defining no. cores, and ram), you can choose the persistent OS disk size and type (SSD or HDD). 

You will also need to decide on a username/password which you will use in the next step at deployment.

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

### 8. The build

This is the moment you have been waiting for. Assuming you decided on username: jamesbond / password: G0|den3y3

From the Azure CLI ensure you navigate to the current working directory where the vmdeploy.bicep file resides. Compile and deploy the VM, passing in the paramaters for username and password

`az deployment group create -f vmtemplate.bicep -g beast --parameters adminUsername="jamesbond" adminPassword="G0|den3y3"`

Or the same deploy, with the optional public ssh key

`az deployment group create -f vmtemplate.bicep -g beast --parameters adminUsername=jamesbond adminPassword=G0|den3y3 adminPublicKey=<INSERT FULL ASCII PUB KEY HERE>` 

If it worked you should see something that looks like this

### 9. Connect to the machine on JHub

First get the IP address of the machine. 

From azure portal:, click resource groups, navigate to the group. Then click on the VM (or public IP)

Or from Az CLI like a pro


`az vm show -d -g beast -n <name> --query publicIps -o tsv` (Needs tweaking.... no name)

Open a browser and type in:

https://xxx.xxx.xxx.xxx:8000

Where the IP address is substituted for the x's. Now as the server has generated it's own self signed SSL certificates, the browser will often kick up a concern. Don't worry and you can usually click accept the risk, and 'go to site'. You should then see a Jupyter hub login screen:

<IMAGE>

user your username and password  to login!

## 10. Test the beast

new-> terminal

Check no. processors and ram
`htop`

Check available disk space
`df -h`

Check internet speed

Install speedtest 

`sudo apt install speedtest-cli`

Run `speedtest`


You now have a beast. Well if you are on the free account it's probably only 4 cores. But the same applies whether you have 4 cores or 400. It's all running the same OS so i you get familiar with this now, you will be ready to upgrade when the free trial is over.


Enjoy.




## 11. Importing and exporting data? Rsync? Can you download from jhub?
















