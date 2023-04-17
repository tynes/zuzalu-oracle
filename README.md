# semaphore oracle

WIP Semaphore Oracle, meant to be used at zuzalu.

## Usage

Uses [direnv](https://direnv.net). Create a `.envrc` file with the following fields, be sure
to add the env variables themselves.
- `export ETH_RPC_URL=`

```
direnv allow .
```

## Testing

```
forge t --fork-url $ETH_RPC_URL
```

Foundry `ffi` is used to call out to the typescript semaphore packages.
