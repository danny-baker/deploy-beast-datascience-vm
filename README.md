# Deploy a BEAST data-science virtual machine on Azure, using Bicep
This guide will help you customise and deploy (almost) any virtual machine from Microsoft Azure, preconfigured for data science applications, with a running Jupyter Hub server out-of-the-box accessible via HTTPS.

This is an example of deploying cloud infrastructure-as-code using a new domain specific language called [Bicep](https://github.com/Azure/bicep). The [OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro) is Linux Ubuntu 18.04 and is specially setup for data science with 150GB of goodies including native support for Python, R, Julia, SQL, C#, Java, Node.js, F#. If you don't know linux, don't worry: it autoruns a Jupyter Hub server giving you instant (secure HTTPS) access to Jhub from the browser of your local machine. Deploying in seconds, you will have access to beast VMs with up to 416 cores, 11000+ GB RAM, 32TB SSD disks, Nvidia Tesla T4/M60/V100 and AMD MI25 GPU, and 1800+ MBit/s internet speeds. Pricing for VMs ranges from 1 cent to 120 $USD/hr and a free trial gets you $200 USD of credit for 30 days, with some important caveats.

This is designed for one-off time-constrained tasks where you need a dedicated beefy VM to run for several hours or days to get the job done. You can then export any data, and tear the whole resource down when you're finished. 

**Use case: when you need better specs than your local machine or the notebook-as-a-service platforms like Google Colab can provide; When you want to say "Just call me bad ass..."**

# Quickstart

If you know what you are doing with deploying Azure resources using ARM templates (and Bicep), simply open the appropriate Bicep template file, set your VM specs, create a resource group, and deploy in the Azure CLI with a single command:

### Deploy with a single command

Use default template VM specs optimised for Free Account (E-series, 4 cores, 32GB RAM, 64GB temp SSD, 1TB SSD OS disk):

`az deployment group create -f vmtemplate.bicep --resource-group <RESOURCE GROUP NAME> --parameters adminUsername="USERNAME" adminPassword="PASSWORD"`

Or specify vm specs with up to six parameters:

`az deployment group create -f vmtemplate.bicep --resource-group <RESOURCE GROUP NAME> --parameters adminUsername="USERNAME" adminPassword="PASSWORD" vmModel="Standard_E4s_v3" osDiskSize=1000 osDiskType="Premium_LRS" projectName="myproject"`

### Access vm via JHub

Once deployed, grab the public IP address of the new vm (from Portal or CLI) access the Jupyter Hub server in the browser via `https://xxx.xxx.xxx.xxx:8000` 

### Access vm via Secure Shell (SSH)

Access directly over terminal: `ssh USERNAME@xxx.xxx.xxx.xxx`

**Notes:**
- Bicep templates deploy just like ARM .json templates (you just need to install Bicep first)
- username and password should be wrapped in quotations '' or special characters don't detect properly
- password needs to be decent (1 capital, 1 number, 1 special char) 
- For JHub and other services exposed to the internet, the vm creates a self-signed certificates for HTTPS (TLS/SSL). When you try to connect, modern browsers will still throw a tanty. Just click through the security warnings and you can connect ok, and be confident that you are accessing the services over an encrypted protocol.
- If you don't _need_ JHUB and want dedicated SSH access to your VM using keys, I have a template specifically for that `vmtemplate_ssh.bicep`. See detailed instructions later in document.


# Guide for Beginners

If you are new to cloud infrastructure and scared at this point, worry not. Follow the crash course and step-by-step instructions below and you will be up and running in no time with a a fully dedicated VM. I've also published an [article in Towards Datascience](https://towardsdatascience.com/deploy-a-beast-virtual-machine-420b8756190e) that provides a full explanatory overview with much more detail and jokes. 

Here's what you're going to do: in a single command you will compile a Bicep file (high level language describing the cloud infrastructure) into an Azure Resource Manager (ARM) template (a lower level abstraction in JSON format) and then build the resources needed in Azure. It takes about 2 mins to deploy and you can be running JHub notebooks over the internet on your remote vm. If you are new to Microsoft cloud, I'd recommend getting a [free Microsoft Azure account](https://azure.microsoft.com/en-gb/free/), so you can play around within the limitations of the trial at no cost.

What is really important to stress is that the OS image used for this deployment is fully setup (by Microsoft) for data science. This means literally zero setup (or linux skills) are needed. It ships with support for all the common languages, and tons of packges preloaded, and it natively runs an Jupyter Hub server and R Studio lab server as containerised services out of the box! This means you can connect instantly to the VM as soon as it is up, securely over HTTPS.

For the Python JHub users, you might be used to running JHub from your local machine (and being constrained by crappy laptop hardware) or from Google Colab (with limited ram and storage and annoying timeouts). THIS VM IS YOUR OWN PRIVATE JHUB SERVER, with all the horsepower you are willing to pay for. Need 500GB Ram and 64 cores for 3 hours? Just deploy the VM in seconds and get the job done like a pro.

### Use this template when
- You need raw horsepower to get the job done (e.g. 128GB+ RAM, 16+ cores)
- You want total and exclusive control of your hardware (no managed services etc)
- Your local machine or any of the cloud notebook environments are simply not up to the task
- You have just watched Hackers and you want to experiment with your own dedicated linux virtual machine :)

### Hardware comparison: Colab vs Kaggle vs Cloud

I've provided a quick snapshot comparison of the well known notebook tools vs dedicated cloud hardware. It's difficult to know exacts from Kaggle and Colab as many limitations are not exactly specified or published, so I've gone from accounts from others.

| Platform             | Cost           | Persistent Storage | Temporary Storage | Ram            | CPU           | GPU                            | Runtime      | Download speed     |
|:--------------------:|:--------------:|:------------------:|:-----------------:|:--------------:|:-------------:|:------------------------------:|:------------:|:------------------:|
| Kaggle (Kernals)     | free           | 5GB                | 17GB              | ~16GB          | ~2 - 4 cores  | Tesla P100                     | 6-9 hrs      | no data            |
| Google Colab         | free           | 15GB (Drive)       | 30-64GB           | ~12GB          | 2 cores       | Tesla K80                      | 12 hrs       | up to 130Mb/s      |
| Google Colab Premium | ~10USD/month   | 15GB (Drive) ?     | 30-64GB           | ~24GB          | 2 cores       | Tesla P100                     | up to 24 hrs | up to 130Mb/s      |
| Azure Virtual Machine               | 0.1-120 USD/hr | 1 - 32000GB / disk | variable          | Up to 11,000GB | 1 - 416 cores | Tesla T4/M60/V100, Radeon MI25 | Unlimited    | 500 - 1800+ Mbit/s |

### Why virtual machines?
- Scalability and choice: access hundreds of cores, thousands of GBs of RAM and massive storage.
- Pay for just what you use (billed per second)
- Insane internet speeds (I've clocked 1,800 MBit/second download speed with a typical 4 core VM)

### Alternatives to a dedicated virtual machine for data science
- Your local hardware
- [Google Colab](https://colab.research.google.com/notebooks/intro.ipynb#recent=true)
- [Kaggle Kernels](https://www.kaggle.com/kernels)
- [Azure Notebooks](https://notebooks.azure.com/) (although I think this is now defunct)
- [Deepnote](https://deepnote.com/)
- [Curvenote](https://curvenote.com/)
- Etc.

### Can I access Jupyter Hub securely on my virtual machine?

YES...well reasonably. In fact this is probably the most important thing about this particular setup. Microsoft has done all the work building a special data science linux OS image, that runs a Jupyter Hub server automatically. No setup required. They have also handled self-signed TLS certificates which means you can connect to your VM's JHub server using HTTPS. You will need to click through a security warning in most browsers but this is just because you are using self-signed certificates between the vm and your pc. What this means is you can instantly have JHub up and running on serious horsepower, and collaborate in real-time with others on your new hardware if you wish.

### What is infrastructure-as-code?

This example demonstrates how to build cloud infrastucture-as-code, which is a way of describing the components you need in 'code'. That's it really. Many (or all) of the big players have some kind of API that they use to interpret the infrastructure to deploy. Whether you are building a machine from the browser or direct from 'code', it's all being turned into a  domain specific format for the vendor to ingest, like a blueprint, in order to build the components and wire them up. Microsoft Azure use things called ARM Templates, which are .json representation of all the infrastructure you want to build. AWS use a .json and .yaml like interface. I'm not sure about Google and the others. Hot off the press, Microsoft has released a new open-source language called [Bicep](https://github.com/Azure/bicep) (August 2020) which drastically simplifies the way you describe their infrastructure. It is really awesome and we're going to be using it!

### What is actually built when I deploy a virtual machine??

It's important to understand that when you provision a virtual machine there are other cloud resources that are also needed; it's not just the VM that gets provisioned in isolation. To deploy a VM with some ports exposed to the internet, for example, what you are doing in reality within Azure is building a virtual network, subnet within the network, virtual network interface card, network security group (controls things like which ports to open/close), storage account with persistent disk (preloaded with an operating system), the virtual machine itself (which is really the compute cpu-ram component) and a public facing IP address to bind to the network interface card so you can access the VM over the internet. Yes it's slightly terrifying at first but I promise it's not too bad once you get the basics. All this magic happens in one elegant step so you don't need to worry about the complexity and can focus on what you do best: the _science_ of data :)

Here is the network topography just to give you a picture of the end product that is built from this template.

![topography](https://user-images.githubusercontent.com/12868840/112561657-8c80de80-8dcd-11eb-90f2-d8451d541144.PNG)


### Making sense of VM Machine Types in Azure
I think most heavy-weight data science applications require high in-memory processing, and parallel core processing either with CPU or GPU. As a result I think the VM types of most interest are D/E/M/N Series from Azure.

For non-GPU applications in data engineering and M/L, I think the D/E series get you a solid all-rounder setup with up to 96 cores and 672GiB RAM in a single instance, plus many options to suit a specific project. For example, an 'E16as_v4' will get you 16 x 2.35Ghz cores, 128GiB RAM and 256GB of temporary SSD storage for about $1USD/hr.

If you are doing something crazy, the M series are straight out beasts and single instances can clock out to 416 cores and 11,400Gb RAM. I mean I don't know what you would use these for in datascience. These are, to be fair, more suited to hardcore enterprise applications. But they are there.

And for the rapidly evolving deep-learning hardware, the new [N-series](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-gpu?context=/azure/virtual-machines/context/context) are for you. There are a number of variants and classess within but in essence you can customise the VM to get fractional access to GPU/TPU (e.g. 0.25GPU core to 4 dedicated GPU cores per node). You have direct access to Nvidia Tesla T4 and M60, Volta V100, AMD Radion Mi25 bolted to vms with latest generation CPU core banks from 4-64 cpu cores. I should note these are not available in the Free Trial, you must go to a paid plan. These are serious and I imagine what many of you might want to try. 

It's also worth mentioning here that Microsoft isn't known as the big player in GPU cloud offerings. It's fair to say this is Google and others. Bottom line is most of them offer GPU options and if this is critical to your work, then it's worth researching options. If GPU is not crazy essential, I think Azure is a great option for trying out dedicated cloud hardware because of the ease of deployment now with the new Bicep language.

The quick and dirty profile of machine types and what to care about for data science applications. There are many subvariants so this is just a flavour to give you an idea of specs and cost ranges.

| Series | Profile                                            | CPU Cores   | GPU Cores    | RAM (GiB)        | Cost ($US/hr) | Verdict                                                                      |
|:------:|:--------------------------------------------------:|:-----------:|:------------:|:----------------:|:-------------:|:----------------------------------------------------------------------------:|
| [A](https://docs.microsoft.com/en-us/azure/virtual-machines/av2-series)      | Testing/Dev                                        | 1 - 8       | -            | 2 - 64           | 0.05 - 0.8    | Not suitable                                                                 |
| [B](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable)      | Burstable (CPU credits)                            | 1 - 20      | -            | 4 - 80           | 0.05 - 1      | Not suitable                                                                 |
| [D](https://docs.microsoft.com/en-us/azure/virtual-machines/dv3-dsv3-series)      | All rounder                                        | 2 - 96      | -            | 4 - 384          | 0.1 - 5       | Suitable                                                                     |
| **[E](https://docs.microsoft.com/en-us/azure/virtual-machines/ev3-esv3-series)**  | **Memory optimised (high mem:cpu ratio)**          | **2 - 96**  | -            | **16 - 672**     | **0.1 - 7**   | **Highly suitable for data eng. & non-GPU M/L**                              |
| [F](https://docs.microsoft.com/en-us/azure/virtual-machines/fsv2-series)      | Compute optimised (high cpu:mem ratio)             | 2 - 72      | -            | 4 - 144          | 0.1 - 3       | Not suitable                                                                 |
| G      | Hardcore Compute optimised (Big data)              | hidden      | -            | -                | -             | Not suitable                                                                 |
| H      | High Performance Compute (supercomputing)          | -           | -            | -                | -             | Not suitable                                                                 |
| [L](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv2-series)      | High Thoughput (I/O optimised)                     | 8 - 80      | -            | 6 - 640          | 0.7 - 7       | Suitable                                                                     |
| **[M](https://docs.microsoft.com/en-us/azure/virtual-machines/m-series)**  | **Absolute Beast**                                 | **8 - 416** | -            | **220 - 11,400** | **2 - 120**   | **Suitable for the brave**                                                   |
| **[N](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-gpu?context=/azure/virtual-machines/context/context)**  | **GPU Optimised (fractional to multi GPU/TPU access)** | **4 - 64**  | **0.25 - 4** | **28 - 400**     | **1 - 20**    | **Highly suitable for deep learning and other M/L (Nvidia Tesla T4/V100/M60, AMD Radeon MI25)** |

More info [here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/). Useful website [azurepricenet](https://azureprice.net/) allows you to quickly find  the VM family and specific model you need, with pricing. 

It's worth noting that on a standard PAYG account you won't be able to provision a beast out of the box. All Azure accounts have soft and hard vcpu (core) quotas, so if you want anything beyond about 32 cores you will need to lodge a service desk request for a quota increase, which can take 48hrs to process. You can check your current limit based on a given region for all VM types in the Az CLI `az vm list-usage --location "East US" -o table`, more info [here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quotas).

### Where does my VM live?
Microsoft has datacenters across the world which you can visualise on a [map](https://azure.microsoft.com/en-gb/global-infrastructure/geographies/). Your VM will live in a datacenter of your choosing based on the location of the 'resource group' that you will set. An Azure resource group is simply a convenient bucket to put all your resources in, much like a folder on a your desktop computer. You can control access at the 'folder' level and remove all it's contents by deleting it in one go. There are marginal price differences between regions, but for this use case, the most important factor is to choose the closest zone to your present location, to minimise latency between you and the machine. For example "Central US" or "UK South".

### Can I just build a datascience VM using the Azure portal in browser?
YES. 
In fact, I'd recommend you build your first VM using the [Azure portal](http://portal.azure.com), selecting the [data science OS image](https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro ). This is exactly the same OS image as I'm using in this build template. There are a few limitations to using the portal so you can't specify as many options but you can definitely get it up and access your vm on JHub etc. I hope this guide shows you how easy it can be to deploy infrastructure as code which is what is actually happening behind the scenes when you deploy from the Azure Portal anyway.

### How am I billed for my VM?
You pay by the second. And yes, leaving the VM on will rack up your credit card in a way you will not like (you are protected on the Free Account, don't worry).

Most of the other infrastructure is essentially free (the virtual network, subnet, public IP, etc). The key costs are the COMPUTE (the virtual machine) and STORAGE (the persistent disk attached to it).

Note the hourly rate is PAYG and if you have an ongoing demand for a vm, you can usually reduce the on-demand price by 60-70% on a 3yr reservation (which you can cancel at any time). Many VMs are also available on spot pricing which is alarmingly attractive. Don't fall for this. I don't think this is a good idea for data science applications because you typically require long uninterrupted processing. On the spot market, your VM can be pulled without warning. PAYG is the only way to get guaranteed exclusivity while using the resource.

**Golden rule is: always remember to turn you vm off (deprovision) or tear down all resources (delete everything)** You can temporarily deprovision it, preserving the OS disk which is just like switching off your PC or you can delete the whole resource group when you are finished. More on this later.

### What is the best VM available on the free trial?
The 30 day free trial gets you 200 USD of credit which is great, but note some important limitations below:
- Max cores = 4 per region (meaning no big bad wolf VMs on free account)
- No access to GPU VM series (upgrade to PAYG account to access N-Series GPU optimised vms, starting at about 1USD/hr)

Most beastly setup on free account: E-series 'Standard E4s_v3' (the default in my template)
- 4 cores (Intel Xeon Platinum 8272CL base core clock 2.5GHz which can increase to 3.4Ghz all cores)
- 32GB ram
- 1TiB Premium SSD disk (Fastest OS disk type)
- Insane internet speeds (Typically 1000+ MBit/second)

This package will burn ~$10USD credit/day and you can run it full throttle 24-7, uninterrupted with no cpu constraints for 20 days until free credit depletes. You can set the OS disk size to anything up to 4,095GB (4TiB) but 1TiB maximises storage vs credit for the 30 day trial.

### How does storage work with vms?
All VMs need a managed persistent disk for the OS image. You can attach additional disks (several usually) and mount them on the filesystem but note this is fidly if you are not comfortable with linux. By far, the quickest and easiest option is to just beef up the OS disk size (up to 4TiB SSD) to what you need for the task at hand.

It's also worth nothing that many VM classes offer temporary high speed storage. This is usually located super local to your compute hardware and is basically the fastest storage you can get. Note it's ephemeral and only lasts a few days so is really useful for data processing stages. The temporary storage is automatically mounted on your VM at location `/mnt`.

### How do I transfer data to and from my VM?
This is a proper remote linux machine so it's not as straight forward as copy-pasting documents to your windows filesytem running JHub on your laptop etc. But, the beauty is that you can do most of your uploading/downloading directly through the Jupyter Hub server by way of the browser, which should cover most people's needs. Don't forget you can rip down data from the internet at lightening speeds from your VM. Because your VM is sitting in a datacenter, it typically had D/L speeds ten times faster (1800+ Mbit/s) than on your home internet or Colab which is constrained to 130Mb/s, for example.

**Getting data into your VM:**
- From your pc: use the JHub upload feature in browser or tools like `rsync` from a linux terminal (requires you to have WSL in windows)
- From the internet: wget/curl/github (just like you would in cloud notebook tools)

**Getting data out of your VM:**

This is a little trickier than you think because the machine is running linux and you probably are running Windows, but I have few standard recommendations. And it also depends where you plan to store the data and how much data you have.

- small (<30GB): use the JHub file download feature in browser (the simplest)
- medium: (<1TB): use a linux data transfer application like `rsync` (requires linux on your local machine, native for MacOS but Windows you will need WSL)
- large: (+1TB): transfer direct to a cloud data storage service like Azure Blob, or Network File System (NFS). This will allow you to rapdidly get data out of the VM and shut it down (to save $$), then you can connect directly to the cloud storage service to either download or store the data more long term.

# Instructions

Now that the crash course is complete, we can start with the step by step guide to deploy your vm infrastructure as code.

### Prerequisites
- Microsoft Azure account (e.g. [Free Trial](https://azure.microsoft.com/en-gb/free/) or pay-as-you-go)

### 1. Install VS Code and Bicep/ARM extensions (OPTIONAL)
This is preparing us for opening and editing the project files, primarily the `vmtemplate.bicep` file. Microsoft Visual Studio code is great for this project as it is open source and has downloadable extensions for bicep and ARM templates, meaning it colours the code really nicely to make it more readable. Download and install [VS Code](https://code.visualstudio.com/) with [ARM Tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools) and [Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) extensions. Note the extensions can be easily installed from within VS Code once it's running. Of course this is optional. You could use any editor (e.g. Notepad++, VIM, etc.)

### 2. Install Azure CLI
What is the Azure CLI? It's a dedicated program that provides a command line interface (i.e. CLI) for interacting directly with Azure resources. This means you can build and tear down infrastructure at command line like a boss, rather than doing it from the web browser portal. The most straight forward way is to [install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) which can run on Windows, MacOS, and Linux. 

**Do I absolutely need to use the Azure CLI?**
For this complete example, Yes. Because there are some limitations with the portal interface. In general: No. If you just want to build a VM using a username/password with the datascience OS image, you can do it all from the portal as a one-off if you need to.

### 3. Install Bicep
Bicep is a cool new domain-specific-language for deploying Azure resources in a much more simplified way than using ARM templates, which are in JSON format and can be painful to read when you start adding multiple pieces of infrastructure. Bicep files compile into Azure Resource Manager (ARM) templates, which can then be directly ingested by Azure to build infrastructure. Bicep scripts, therefore are a high-level abstraction ontop of ARM templates, that simplify the description of the infrastructure you want to build. It only takes a few mins to install Bicep. Follow the installation guide [here](https://github.com/Azure/bicep). 

From within the Azure CLI latest version it is basically:

`az bicep install`

`az bicep upgrade`

### 4. Clone this repo
Copy this project repo to your local machine either from Github over browser as a straight download, or via `git clone` etc. If you are not familiar with github and git, really, you just need to get the `vmtemplate.bicep` file to your local machine where you can access it from within the Azure CLI.

### 5. Configure VM specs (the fun part)

Open the `vmtemplate.bicep` file in visual studio code. 

At the beginning of the file I've summarised all the knobs and dials you might want to turn to tweak your VM settings. By default, I've chosen the toughest setup I could find within the limits of a Free Account (This is an E4s_v3 with 128GB RAM, and a 1TB Premium SSD OS Drive). But of course you can mix and match practically any VM up to 4 cores on the free account, and experiment with different HDD sizes and types. In brief, if you are on a free account, the default settings are optimised for the best 4 cores, most ram and best disk I could find. If you are on a PAYG account, you can go crazy.

You can either modify the default vm spec values in the .bicep file itself, or overide the default values by passing the desired values in as parameters in the build command. Totally up to you.

**Key decision points:**
- VM Model - This is critical as it determines the number of cores, RAM, temporary storage, and other limitations in relation to I/O. There are literally hundreds of options. Lookup what you want either on [Azure docs](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/) or on [azurenet](https://azureprice.net/). Modify the variable field as you need
- OS disk size - Default to 1TiB premium SSD, but you can choose anything up to 4TiB (4095GB) as a single disk.
- OS disk type Take special note there are 3 distinct classes of storage 'Premium_LRS' which is SSD, 'StandardSSD_LRS' which is constrained SSD media, then the good old fashioned hard disk drive 'Standard_LRS'. Standard SSD is half the price of premium ssd, and standard HDD is 1/4 the price of premium ssd. Refer to docs [here](https://azure.microsoft.com/en-gb/pricing/details/managed-disks/). In all datascience applications, I'd use nothing other than "Premium_LRS" for maximum performance. 

### 6. Login to Azure

From the azure CLI:

`az login --use-device-code`

This should open the browser and get you to punch in a code displayed in the CLI

Check account selection

`az account list --output table`

Set subscription (if default is not correct)

`az account set --subscription <name>`

List resource groups (to view any existing resource groups in your subscription)

`az group list --output table`

OPTIONAL: Permanently set Azure CLI output format to table which is way more human readable than JSON, which is the default. I highly recommend doing this.

`az configure` (and follow prompts. Ensure you select output as table format)

### 7. Create Azure resource group

Create a new resource group in a region that is geographically close to your current location.

To view available regions:

`az account list-locations`

In this example I'm creating a resource group called "beast" in the "Central US" region. It usually takes a few seconds.

`az group create --name beast --location "Central US"`

Check resource group is created

`az group list --output table` (if you have changed your Az CLI configuration, you don't need to append the --output table every time)

After a few seconds, it should appear. You can check in portal.azure.com directly by searching for 'resource groups'

### 8. Setup access

We are almost ready to construct the resource. The final thing we need to do is setup how you will access the machine. There are two main ways you can do this: username/password credentials OR SSH public/private key encryption. I have a separate bicep file for each option. I'd recommend user/pass default for now, as this is the option that supports JHub.

**Choose a username and password**
- Note passwords must contain at least 1 uppercase, 1 number and 1 special character.
- I'd suggest you generate a strong password with something like [keepass](https://keepass.info/)
- For the default template we will be using, you must create a username and password. This is because Jupyter Hub requires a user/pass and does not support SSH keys. And because I assume most people will want to run notebooks on their VM, I've setup the template to allow a username/password, which is not really the most secure way to connect to a Linux host. 

**OPTIONAL: Create SSH key-pair**

Only applicable if you do not plan to use JHub and want the most secure way to access your VM. If you are running linux, WSL in Windows or MacOS and you have basically a linux terminal,  you can create public/private key encryption files for secure shell access (SSH) to the VM. This is the safest way to access it, although note that Jupyter Hub does not support it. So no matter what, if you are planning to use JHub mainly, you will need to use the recommended `vmtemplate.bicep` template. From JHUB you can access a full root terminal to do whatever you need. So this is really only for more hardcore ppl that want to be able to directly SSH into the VM with encrypted keys. If you definitely want this option, create SSH keypair have have public key ready to be copied.

### 9. THE GREAT BUILD

This is the moment you have been waiting for: we are ready to build the infrastructure. From the Azure CLI ensure you navigate to the current working directory where the `vmdeploy.bicep` file(s) reside. You must also be logged into your Azure account via the Az CLI (step 6). Build the VM by running the appropriate command below, passing in the paramters for username/password or public key. Let's assume you decide on username: jamesbond / password: G0|den3y3 and have created a resource group called 'beast'.

**Deploy with username/password**

Build using default VM specs in the .bicep file:

`az deployment group create -f vmtemplate.bicep --resource-group beast --parameters adminUsername="jamesbond" adminPassword="G0|den3y3"`

Build passing custom VM specs as parameters:

`az deployment group create -f vmtemplate.bicep --resource-group beast --parameters adminUsername="jamesbond" adminPassword="G0|den3y3" vmModel="Standard_D2s_v3" osDiskSize=180 osDiskType="Premium_LRS" projectName="myproject"`

**Deploy with SSH public key**

`az deployment group create -f vmtemplate_ssh.bicep --resource-group beast --parameters adminUsername="jamesbond" adminPublicKey="INSERT FULL ASCII PUBLIC KEY HERE"`

Notes
- For SSH, you are calling a different bicep template file called `vmtemplate_ssh.bicep`.
- Always encase the username and password (and public key) in inverted commas to ensure special characters parse properly. Sometimes you will get an error without them.

If it worked you should see something that looks like this

![successful deploy](https://user-images.githubusercontent.com/12868840/112634272-4f9b0300-8e32-11eb-81b6-9ebd42d17dd6.PNG)

Above: If you see something like this in thte Azure CLI after patiently waiting for 2 minutes you are looking good. 

Login to Azure Portal and take a look at your new infrastructure!

![portal deploy](https://user-images.githubusercontent.com/12868840/112638836-90494b00-8e37-11eb-8ee2-d7c073cb0f9f.PNG)

Above: Navigate to the resource group in portal, and you can see all the new components created

![public ip](https://user-images.githubusercontent.com/12868840/112638843-917a7800-8e37-11eb-9fb9-bb32f686e732.PNG)

Above: Click on the VM itself, to view it's Public and Private IP address


### 10. Connect to the machine over the browser via Jupyter Hub!

Your new VM has a bunch of services preconfigured, so after deployment, it immediately runs a range of containerised services (via Docker) including a Jupyter Hub service, exposed on port 8000. Jupyter Hub is (in part) a webserver and so you can directly connect to it from any browser over the internet. 

First get the IP address of your new vm:
- From Azure Portal: search for resource group, navigate to the correct group, click on the VM (and you can see the public IP top right)
- From Azure CLI: `az vm show -d -g <RESOURCE GROUP NAME> -n <VM NAME> --query publicIps -o tsv`

Open a browser and access Jupyter Hub webserver (which is running on your vm exposed via port 8000), where the IP address is substituted for the x's.:

`https://xxx.xxx.xxx.xxx:8000`


Navigate past the browser security warning.  Your vm has generated it's own self signed SSL certificate to allow encrypted browser traffic (HTTPS). However, as this is not a public certificate, the browser will often kick up a warning when you first connect. Don't worry and you can usually click accept the risk, and 'go to site'. 

![browsersecurity](https://user-images.githubusercontent.com/12868840/112639170-def6e500-8e37-11eb-9a39-790622d5f7a7.PNG)


Above: You are still transferring securely data via HTTPS it's just you are using a self-signed certificate from the Linux VM which is not publicly recognised by the browser.

Once through this, you should then see a Jupyter hub login screen:

![jhub login screen](https://user-images.githubusercontent.com/12868840/112557759-18dad380-8dc5-11eb-998c-73490dcd92c5.PNG)

Above: If you get to this screen. Start celebrating.

Login to Jupyter Hub with the username and password you supplied for the VM at deployment

If it has worked, you will see the Jhub session that looks like this.

![jhub](https://user-images.githubusercontent.com/12868840/112557789-2b550d00-8dc5-11eb-8646-41bb4569142d.PNG)

#### And you are IN. At this point you can start playing with notebooks or collaborate with buddies to datascience it up!

<br>

# NERD SECTION

For some more advanced security options and cool stuff, read on.

### Test your new VM (internet speed, cores, ram utilisation)

Now are you are connected to your VM, it's time to test a few things. 

Open a terminal from the Jupyter Hub main screen (new -> terminal)

![jhub term](https://user-images.githubusercontent.com/12868840/112557821-46c01800-8dc5-11eb-9f3d-c9b0b938c742.PNG)

![jhub terminal screen](https://user-images.githubusercontent.com/12868840/112557836-50498000-8dc5-11eb-93f8-a38580665b2e.PNG)

Above: It's important to note that connecting to your VM via JHub gives you full superuser access; you can open a linux terminal from within Jhub and do literally anything you want. (You can also directly SSH to your machine via a terminal, see following sections)

**Check no. processors, ram, and uptime with `htop`**

![htop](https://user-images.githubusercontent.com/12868840/112565126-6c085280-8dd4-11eb-8b92-4258cf0b3e25.PNG)

Above: In this example we're running a E4s_v3 with 4 cores (cores visible top left) and 32GB RAM. This is a handy way to real-time monitor your VM core and RAM used and available capacity. You can also look at the running process tree and, most importantly, uptime which is what you are being charged for by the second when you are on PAYG.

**Check available disk space with `df -h`**

![4tib df](https://user-images.githubusercontent.com/12868840/112557855-58a1bb00-8dc5-11eb-9baa-e3c219e9bc4b.PNG)

Above: In this example we can see 3.9TB available on the main OS disk mounted on root `/`. Note also 60GB temporary storage avilable on this Vm class, which is mounted on `/mnt` which you can use to for processing and storage. Many Azure VM's offer temp SSD storage so be sure to check out this option.

**Check internet speed**

`sudo apt install speedtest-cli`

`speedtest`

![speedtest_fast](https://user-images.githubusercontent.com/12868840/112633155-e8308380-8e30-11eb-8c2f-a02d6669b3b0.PNG)

Above: Here I clocked 1,800+ Mbit/second download speed from a standard 4 core VM on the free trial. Call me crazy but that is decent.


### Access VM via SSH 

You can also access the vm via a terminal directly from an application like Putty in Windows, or a linux terminal in MacOS or WSL on Windows. You just need the public IP address, user/pass or private key location.

**SSH using simple username/password:**

`ssh jamesbond@51.143.137.130`

In this case I've used the public IP I got for my machine. You will be prompted for the password, and you will be prompted to accept the thumbprint from the remote machine after this, and then you are in.

**SSH using key**

`ssh -i ~/.ssh/private-key jamesbond@51.143.137.130`

Access the vm using keys is far more secure and preferred but JHub does not support it. So you would only use this option if you want preferred secure way to connect to your VM and you don't plan to use Jhub. 

![ssh access](https://user-images.githubusercontent.com/12868840/112702891-eac0c680-8e8c-11eb-8fda-947ca65dce20.PNG)

Above: The friendly SSH welcome screen.


### Extra Security Considerations (VPN etc.)

**Use very strong password**

By default, this VM uses the suboptimal username/password creditials with a public facing IP address for ease of access and collaboration, and a Jupyter Hub requirement. This is of course not ideal but probably OK for short term runs and one-offs. I'd suggest you generate a strong password with something like [keepass](https://keepass.info/)

**Putting your VM behind a VPN**

If security is of paramount importance for your experimentation and you want enterprise level protection, really the only option in my mind is putting your machine on a private network only (no public IPs or publicly exposed ports) and allowing access to the private network ONLY via a premium VPN gateway service. A proper VPN allows you to use an encrypted tunnel from your client machine to your virtual private network in Azure where your VM lives. Once inside you can directly connect to your machine via SSH, user/pass, or possibly the browser for Jhub (but this is outside my ability). There are some manual steps you will need to first (i.e. generate root and client certificates) but if you are determined, you can get it done in a few hours of pain and suffering.

Fortunately, Azure has 3 options for VPN gateways and in fact the Azure Free Trial account gives you access to a bunch of services for 12 months free of charge, including a premium VPN which usually costs $140USD/month.

I've created a bicep file `vmtemplate_vpn.bicep` for advanced users that does the following:
- removes public IP for VM itself (ok to leave ports open)
- dynamically creates private network ip address for the vm (usually 10.1.0.4)
- creates the VM and all associated infrastructure with an additional subnet and premium VPN gateway (default tunnel encryption is IkeV2 and OpenVPN but you can change these)

First you need to generate a root certificate for the VPN, and export it's public key in a particular way (ref links below) so you can copy the ASCII chars and use pass them in as parameters at deployment. At deployment you pass 4 parameters: username / password / SSH public key / VPN root certificate public key. The VPN gateway takes about 45 minutes to create so you will have to be patient. Once it's up you should be able to navigate to it in Portal and see it has a public IP address. Assuming you already have the root and client certs installed on your local machine, you need to download the VPN client from Azure Portal (or via CLI) (ref links below), install, then connect. Once successfully connected to the VPN, you can directly ssh to your VM.

I've tested this Bicep template is working and can ssh to the private data science machine once connected to the VPN. JHub does not work out of the box in your browser on the private ip but I do believe with some routing magic and editing of `/etc/hosts` files it can be done. This is beyond my skill level though.

https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings

https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site for generating root and client certificates


### Further reading

Follow the microsoft documentation to show you more options to connect and use the data science vm and what you can do with it.

https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/dsvm-ubuntu-intro

https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/linux-dsvm-walkthrough


Enjoy.


















