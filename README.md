# Bullpen CLI

## Quickstart

```sh
# 1. Install the CLI
brew install bullpenfi/tap/bullpen

# 2. Install AI skills
bullpen skill install

# 3. Log in
bullpen login
```

## Install

### Homebrew (macOS / Linux)

```sh
brew install bullpenfi/tap/bullpen
```

### npm

```sh
npm install -g @bullpenfi/cli
```

### curl

```sh
curl -fsSL https://cli.bullpen.fi/install.sh | sh
```

## Skills

`bullpen skill install` fetches the skills defined in `skill.yaml` and
makes them available as subcommands:

| Command | Description |
|---------|-------------|
| `bullpen poll <topic>` | Create a market poll or prediction question |
| `bullpen predict <question>` | Generate a probability-weighted prediction |
| `bullpen sentiment <ticker>` | Summarise market sentiment |
| `bullpen portfolio balances` | Fetch token balances across all linked wallets and chains |
| `bullpen polymarket discover` | List trending prediction markets on Polymarket |
| `bullpen polymarket buy <market> <outcome> <amount>` | Buy shares on a market outcome |

## Login

`bullpen login` uses the OAuth 2.0 device-code flow:

1. A one-time code is displayed in the terminal
2. Your browser opens `https://auth.bullpen.fi` automatically
3. After you approve, credentials are saved to `~/.config/bullpen/credentials`

To use a self-hosted auth server, set `BULLPEN_AUTH_HOST` before logging in:

```sh
BULLPEN_AUTH_HOST=https://auth.example.com bullpen login
```

## Supported platforms

| OS    | Architecture |
|-------|-------------|
| macOS | arm64, x86_64 |
| Linux | arm64, x86_64 |
