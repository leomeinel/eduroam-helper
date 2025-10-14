# eduroam-helper

This is a collection of scripts to configure eduroam with a pkcs12 certificate bundle.

The certificate bundle should have been provided by your university.

## Basic usage

### I GUI

:information_source: | Please note that this might be outdated. For (sadly somewhat overcomplicated) up-to-date instructions, check [this](https://doku.tid.dfn.de/de:eduroam:easyroam#installation_der_easyroam_profile_auf_linux_geraeten) page.

1. Log in to https://www.easyroam.de
2. Click on `Manual installation > Linux` and give a profile name to download `example.p12`. The file name might be different.

### II CLI

After you have downloaded `example.p12` ([I](#i-gui)), open your terminal.

```sh
# Navigate to the directory where 'example.p12' is stored
cd ~/Downloads

# Clone this repository and make eduroam-nmcli.sh executable
git clone https://codeberg.org/ce-it-knowledge-exchange/eduroam-helper.git
chmod +x ~/Downloads/eduroam-helper/eduroam-nmcli.sh

# Execute eduroam-nmcli.sh
# If you are using doas, execute only the next line:
#     > doas ~/Downloads/eduroam-helper/eduroam-nmcli.sh ~/Downloads/example.p12
sudo ~/Downloads/eduroam-helper/eduroam-nmcli.sh ~/Downloads/example.p12
```

## Help

### eduroam-nmcli.sh

```
Usage: eduroam-nmcli.sh [pkcs12 certificate bundle]

Configure eduroam with nmcli and a pkcs12 certificate bundle

Parameters:
    [pkcs12 certificate bundle]  Path to certificate bundle, fex. '~/Downloads/example.p12'
```

## Credit

- `eduroam-nmcli.sh` is heavily inspired by https://git.uni-greifswald.de/URZ-Public/easyroam/src/commit/dceaa0b73c4e0c007844fc1f68fef103d02c99d4/configure-eduroam-with-easyroam (Commited by Daniel von Obernitz)
