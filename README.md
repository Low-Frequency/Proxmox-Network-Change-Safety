# Proxmox-Network-Change-Safety

While troubleshooting I found the need to change network settings on my PVE node which could cause me to lock myself out. Therefore I wrote a simple script that lets you make changes to the interfaces config and performs a rollback if something went wrong.

## Usage

```
change-network.sh [OPTIONS]
```

## Options

|Option|Description|Default|
|------|-----------|-------|
|-t|Timeout for the rollback||
|-c|Name of the config file|interfaces.new|
|-h|Display help message|-|
