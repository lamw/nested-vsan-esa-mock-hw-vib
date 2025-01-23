# Nested vSAN ESA Hardware Mock VIB

vSAN ESA Hardware Mock VIB for Nested ESXi containing [stress.json](stress.json), which is designed for a Nested ESXi VM configured w/an NVMe Storage Controller and allowing the vSAN ESA HCL pre-check that is performed by vCenter Server or VMware Cloud Foundation (VCF) to successfully pass.

## Requirements
* Ubuntu 22.03 or later
* Docker installed

## Pre-Built VIB/Offline Bundle for ESXi 7.x/8.x

Please see `Releases` tab for download

* **[nested-vsan-esa-mock-hw.vib](https://github.com/lamw/nested-vsan-esa-mock-hw-vib/releases)** (SHA256: f04d09b7b5392d53b9828f3c0b753722ad2e6d7fee29ca4610f449b2c0c4a10e)
* **[nested-vsan-esa-mock-hw-offline-bundle.zip](https://github.com/lamw/nested-vsan-esa-mock-hw-vib/releases)** (SHA256: 04ec43a7307fd22edf89356c69140cc7bc0ef569b152a1ed2fba923b5e68b11b)

## Usage

```console
sudo ./build.sh
```

## Build Example

```
# sudo ./build.sh
Creating Nested vSAN ESA Mock HW VIB build container ...
Error response from daemon: No such image: vsanesamockvib:latest
[+] Building 0.4s (11/11) FINISHED                                                                                                                                                                 docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                                         0.0s
 => => transferring dockerfile: 326B                                                                                                                                                                         0.0s
 => [internal] load metadata for docker.io/lamw/vibauthor:latest                                                                                                                                             0.3s
 => [internal] load .dockerignore                                                                                                                                                                            0.0s
 => => transferring context: 2B                                                                                                                                                                              0.0s
 => [1/6] FROM docker.io/lamw/vibauthor:latest@sha256:4d5001c3847d6dd0afac734e5512f02afccd555474729555e069622eb004b11a                                                                                       0.0s
 => [internal] load build context                                                                                                                                                                            0.0s
 => => transferring context: 90B                                                                                                                                                                             0.0s
 => CACHED [2/6] RUN yum install -y unzip zip                                                                                                                                                                0.0s
 => CACHED [3/6] COPY create_nested_vsan_esa_mock_hw_vib.sh create_nested_vsan_esa_mock_hw_vib.sh                                                                                                            0.0s
 => CACHED [4/6] COPY stress.json stress.json                                                                                                                                                                0.0s
 => CACHED [5/6] RUN chmod +x create_nested_vsan_esa_mock_hw_vib.sh                                                                                                                                          0.0s
 => CACHED [6/6] RUN /root/create_nested_vsan_esa_mock_hw_vib.sh                                                                                                                                             0.0s
 => exporting to image                                                                                                                                                                                       0.0s
 => => exporting layers                                                                                                                                                                                      0.0s
 => => writing image sha256:1a3892517c4086ba338f2e2d58ca695cab497a054ef6fdae3b63f31248a2f09c                                                                                                                 0.0s
 => => naming to docker.io/library/vsanesamockvib
```

## Build Output

Both ESXi VIB (`dummy-esxi-reboot.vib`) and Offline Bundle (`dummy-esxi-reboot-offline-bundle.zip`) will be stored in `artifacts/` directory

```console
# tree artifacts/
artifacts/
├── nested-vsan-esa-mock-hw-offline-bundle.zip
└── nested-vsan-esa-mock-hw.vib

0 directories, 2 files
```

## Install VIB using ESXCLI

```console
# Change ESXi acceptance level to CommunitySupported

[root@esxi:~] esxcli software acceptance set --level CommunitySupported

# Install VIB

[root@esxi:~] esxcli software vib install -v /nested-vsan-esa-mock-hw.vib --no-sig-check
Installation Result
   Message: Operation finished successfully.
   VIBs Installed: williamlam.com_bootbank_nested-vsan-esa-mock-hw_1.0.0-1.0
   VIBs Removed:
   VIBs Skipped:
   Reboot Required: false
   DPU Results:

# Restart vSAN Management Service

[root@esxi:~] /etc/init.d/vsanmgmtd restart
```

## Uninstall VIB using ESXCLI

```console
[root@esxi:~] esxcli software vib remove -n nested-vsan-esa-mock-hw
Installation Result
   Message: Operation finished successfully.
   Components Installed:
   Components Removed: nested-vsan-esa-mock-hw
   Components Skipped:
   Reboot Required: false
   DPU Results:
```

## Install Offline Bundle using ESXCLI

```console
# Change ESXi acceptance level to CommunitySupported

[root@esxi:~] esxcli software acceptance set --level CommunitySupported

# Install Offline Bundle

[root@esxi:~] esxcli software component apply -d /nested-vsan-esa-mock-hw-offline-bundle.zip --no-sig-check
Installation Result
   Message: Operation finished successfully.
   Components Installed: dummy-esxi-reboot
   Components Removed:
   Components Skipped:
   Reboot Required: false
   DPU Results:

# Restart vSAN Management Service

[root@esxi:~] /etc/init.d/vsanmgmtd restart
```

## Uninstall Offline Bundle using ESXCLI

```console
[root@esxi:~] esxcli software component remove -n nested-vsan-esa-mock-hw
Installation Result
   Message: Operation finished successfully.
   Components Installed:
   Components Removed: nested-vsan-esa-mock-hw
   Components Skipped:
   Reboot Required: false
   DPU Results:
```

## Install Offline Bundle using vSphere Lifecycle Manager (vLCM)

Step 1 - Upload offline bundle to vLCM using vSphere UI by going to `Lifecycle Manager->Actions->Import Updates`

Step 2 - Add component to vSphere Cluster using vSphere UI by going to `vSphere Cluster->Update->Image->Edit` and click on "Add Components" and select `Nested vSAN ESA Mock HW` component and click save

Step 3 - Remediate vSphere Cluster

Step 4 - Restart the vSAN Management Service

```
[root@esxi:~] /etc/init.d/vsanmgmtd restart
```