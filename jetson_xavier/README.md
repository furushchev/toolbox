# Use unionfs for Xavier

1. Install NVMe SSD Drive

2. Format SSD Drive as ext4

    Ensure `/dev/nvme0n1p1` is visible on your tegra device.

3. Install scripts

    ```bash
    wget https://raw.githubusercontent.com/furushchev/toolbox/master/jetson_xavier/install.sh -O - | bash -
    ```
