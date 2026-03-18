# Secrets

Manages secret provider scripts that expose API keys and tokens as environment variables. Each key provider is a wrapper script that executes a user-supplied executable and sets the result as a session environment variable.

## Usage

```nix
secrets = {
  enable = true;
  keyProviders = [
    {
      name = "openai-key";
      path = "$HOME/.config/openai/key_provider.sh";
      envVarName = "OPENAI_API_KEY";
    }
  ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable secrets provider |
| keyProviders | list of submodule | [] | List of environment secrets to expose |
| keyProviders.*.name | str | (required) | Name of the provider (used as the wrapper script name) |
| keyProviders.*.path | str | (required) | Path to executable that outputs the secret token to stdout |
| keyProviders.*.envVarName | str | (required) | Name of the environment variable to set |

## Notes

- Each key provider generates a shell wrapper script added to `home.packages`.
- The provider `path` executable must print the secret to stdout when executed.
- Environment variables are set as session variables using `$(command)` substitution, so they are evaluated at shell startup.
