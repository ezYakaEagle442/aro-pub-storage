# aro-pub-storage
ARO Public cluster &amp; storage 101

# Introduction
This is an introduction to play with Storage integration in ARO : OCS (Ceph) vs Azure Disk + File + Blob, Storage types (GRS, etc)


## **Disclaimer**

**The features described in this workshop might be not yet production-ready, we enable preview-features for the purpose of learning.**

See also :

- [Azure ARO docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster)
- [ARO 4.x storage docs](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html)
- [http://aroworkshop.io](http://aroworkshop.io)
- [https://github.com/akamenev/aro-private](https://github.com/akamenev/aro-private)
- [https://github.com/stuartatmicrosoft/azure-aro/blob/master/aro4-replace-pull-secret.sh](https://github.com/stuartatmicrosoft/azure-aro/blob/master/aro4-replace-pull-secret.sh)


1. Setup [Tools](tools.md)
1. Check [subscription](subscription.md)
1. Setup [environment variables](set-var.md)
1. Setup [pre-requisites](setup-prereq.md)
   1. Create RG
   1. Create Storage
   1. Get a Red Hat pull secret
   1. Setup [Network](setup-network.md)
   1. Create [SSH Keys](setup-prereq.md#generates-your-ssh-keys)
1. Setup [ARO cluster](setup-aro.md)
1. Setup [HELM](setup-helm.md)
1. Setup [CSI drivers](setup-store-CSI-driver.md)