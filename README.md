# Download `cento-demo` setup files

1. Clone `cento-demo` project from GitHub into `/opt/ntop`

	```
	git clone https://github.com/tourko/cento-demo /opt/ntop
	```

# Install and start Napatech driver

1. Install the latest [Link-Capture™ Software package](https://www.napatech.com/download-center/#Capture-Linux) following Napatech's [Software Installation for Linux Guide](https://docs.napatech.com/r/Software-Installation-for-Linux)

2. Upgrade the FPGA firmware on the SmartNIC/DPU to the following versions or newer:

	| SmartNIC/DPU | Link speed | Min FW vesion     |
	|--------------|------------|-------------------|
	| F2070X       | 2x100 Gbps | 200-9586-68-04-00 |
	| NT400D11     | 2x100 Gbps | 200-9583-67-08-00 |
	
3. Add `ntservice` to the `systemd`

	Follow the instructions in the `/opt/napatech3/share/napatech/systemd/ntservice.service` file.

4. Remove the deafult `ntservice.ini` file if it exists

	```
	rm -f /opt/napatech3/config/ntservice.ini
	```

5. Link `ntservice.ini` to the `.ini` file matching your SmartNIC/DPU:

	The following `.ini` files are provided:

	* `/opt/ntop/cento/ntservice/F2070X.ini`
	* `/opt/ntop/cento/ntservice/NT400D11.ini`

	Example:

	```
	ln -s /opt/ntop/cento/ntservice/NT400D11.ini /opt/napatech3/config/ntservice.ini
	```

6. Start the `ntservice`

	```
	systemctl start ntservice
	```

7. Verify that the `ntsevice` is running

	```
	systemctl status ntservice
	```

	Expected output:

	```
	● ntservice.service - Napatech 3GD Service
		Loaded: loaded (/etc/systemd/system/ntservice.service; enabled; preset: disabled)
		Active: active (running) since Fri 2025-10-24 12:46:43 CEST; 2h 4min ago
	Process: 98913 ExecStart=/opt/napatech3/bin/ntstart.sh --managed (code=exited, status=0/SUCCESS)
	Main PID: 99040 (ntservice)
		Tasks: 42 (limit: 406924)
		Memory: 213.7M
		CPU: 27.375s
		CGroup: /system.slice/ntservice.service
				└─99040 /opt/napatech3/bin/ntservice -d -f /opt/napatech3/config/ntservice.ini

	Oct 24 12:46:43 sm-xeond ntservice[99040]: ***************************************
	Oct 24 12:46:43 sm-xeond ntservice[99040]: *    NTService is now operational.    *
	Oct 24 12:46:43 sm-xeond ntservice[99040]: ***************************************
	```

# Running `cento-demo` in a `podman` pod

## Install `pf_ring` on the host / SoC

1. Get `ntop.repo` file

	```
	curl https://packages.ntop.org/centos/ntop.repo > /etc/yum.repos.d/ntop.repo
	```

2. Install `pfring-dkms`

- On F2070X and F3070X running Fedora 37:

	```
	dnf install hiredis numactl dkms
	dnf --releasever=9 --disablerepo="*" --enablerepo=ntop --enablerepo=ntop-noarch install pfring-dkms
	```

- On other platforms running RHEL, Centos, Rocky, etc.:

	```
	dnf install pfring-dkms
	```

## Build the containers

1. Change the folder to `/opt/ntop`

	```
	cd /opt/ntop
	```
2. Build `ntopng` containder

	```
	podman build --tag ntopng:latest ntopng
	```

3. Build `cento` containder

	```
	podman build --tag cento:latest cento
	```
## Attach the nTop licenses to the containers

The following steps are **optional**. Without the licenses the setup will run for 5 minutes and then stops.

1. Obtain `pf_ring`, `ntopng` and `cento` licenses from nTop

2. Put the licenses in the files in the `/opt/ntop/licenses` folder

- `ntopng` license:

	```
	echo "<ntopng license key>" > /opt/ntop/licenses/ntopng.license
	```

- `pfring` license:
	```
	echo "<pfring license key>" > /opt/cento/licenses/pf_ring.license
	```

- `cento` license:
	```
	echo "<cento license key>" > /opt/cento/licenses/cento.license
	```

3. Update `cento-demo-pod.yaml` with `pf_ring` license S/N

	3.1. Get the S/N
	```
	pfcount -L -v 2 | grep napatech | head -1 | awk '{print $4}'
	```
	Example output: `870-0001-01-10-0000-279553`

	3.2. In the `cento-demo-pod.yaml`, replace 0's in the line `/etc/pf_ring/000-0000-00-00-0000-000000` with the S/N.

## Start the `cento-demo-pod`

1. Start the pod

	```
	podman kube play --replace --publish 8080:3000 cento-demo-pod.yaml
	```

2. In a browser, go to `http://<host>:8080` to access the `ntopng` UI