# Register a save provider

**\[stable\]**

Register a named `SaveData` provider for use by
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.md)
and
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/reference/RunWorkflows.md).
Registered providers can be referenced from `lConfig$SaveData` with a
single character string.

Registered save providers must accept `lWorkflow` and `lConfig` as named
formals.

## Usage

``` r
register_save_provider(name, provider)
```

## Arguments

- name:

  `string` Non-empty provider name.

- provider:

  `function` Save hook implementation.

## Value

Invisibly returns `name`.

## Examples

``` r
if (FALSE) { # \dontrun{
register_save_provider(
  "example.save",
  function(lWorkflow, lConfig) invisible(NULL)
)
} # }
```
