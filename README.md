# Download the setup files

1. Download `cento-demo` files from GitHub

	`# curl -L https://github.com/tourko/cento-demo/archive/refs/heads/main.zip -o cento-demo.zip`

2. Convert `zip` to `tar.gz`

	`# unzip cento-demo.zip -d demo && mv demo/cento-demo-* demo/cento && tar -czf cento-demo.tar.gz -C demo cento && rm -rf demo`

3. Unpack `cento_demo.tar.gz` to `/opt/cento`

	`# tar -xzvf cento_demo.tar.gz -C /opt`

# Install and start Napatech driver

1. Install Napatech driver following Napatech's Linux Installation Guide

2. Add `ntservice` to the `systemd`

	Follow the instructions in the `/opt/napatech3/share/napatech/systemd/ntservice.service` file.

3. Link `ntservice.ini` to a the `.ini` file matching your SmartNIC/DPU:

	The following `.ini` files are provided:

	* `/opt/cento/ntservice/NT400D11.ini`
	* `/opt/cento/ntservice/F2070X.ini`

	Example:

	`# ln -s /opt/cento/ntservice/NT400D11.ini /opt/napatech3/config/ntservice.ini`

4. Start the `ntservice`

	`# systemctl start ntservice`

5. Verify that the `ntsevice` is running

	`# systemctl status ntservice`

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

	Oct 24 12:46:43 sm-xeond ntservice[99040]: ********************************************************************
	Oct 24 12:46:43 sm-xeond ntservice[99040]: *                NTService is now operational.                     *
	Oct 24 12:46:43 sm-xeond ntservice[99040]: ********************************************************************
	```

# Running nTop `cento` in a `podman` container

## Build the container

1. Change the folder to `/opt/cento`

	`# cd /opt/cento`

2. **[Optional]** Obtain `pf_ring` and `cento` licenses from nTop.

	Without the licenses the setup runs for 5 minutes and then stops.

	Put the licenses in the files in the `/opt/cento/licenses` folder:

	`# echo "<pfring license key>" > /opt/cento/licenses/pf_ring.license`

	`# echo "<cento license key>" > /opt/cento/licenses/cento.license`

3. Build the containder

	* If you don't have `pfring` license:

		`# podman build --tag cento:1.0`

	* If you have `pfring` license, specify the `PFRING_SN=<SN>` as a build argument:

		`# podman build --tag cento:1.0 --build-arg PFRING_SN=000-0000-00-00-0000-000000 .`

## Run the container

1. Get `ntop.repo` file

	`# curl https://packages.ntop.org/centos/ntop.repo > /etc/yum.repos.d/ntop.repo`

2. Install `pfring-dkms`

	On Fedora:

	`# dnf install pfring-dkms --releasever=9`

	On RHEL, Centos, Rocky:

	`# dnf install pfring-dkms`

3. **[Optional]** Edit `cento-bridge` configuration

	The configuration file is located in `/opt/cento/config/rules.conf`.

4. Start the container

	* With **4 worker threads** and the **HW flow offload**:

		`# scripts/start_container.sh --threads 4 --flow-offload`

	* With **16 worker threads** and without **HW flow offload**:

		`# scripts/start_container.sh --threads 16`
