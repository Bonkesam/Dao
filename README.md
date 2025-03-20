# DAO Governance

- [DAO Governance](#dao-governance)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Test](#test)
  - [Deploy](#deploy)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`


## Quickstart

```
git clone https://github.com/Bonkesam/Dao
cd Dao
forge install
forge build
```


# Usage

## Test

```
forge test
```
## Deploy

I did not write deploy scripts for this project

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see and output file called `.gas-snapshot`


# Formatting


To run code formatting:
```
forge fmt
```

