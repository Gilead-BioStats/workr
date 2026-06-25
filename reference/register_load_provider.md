# Register a load provider

**\[stable\]**

Register a named `LoadData` provider for use by
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.md),
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/reference/RunWorkflows.md),
and
[`DemoApp_Server()`](https://gilead-biostats.github.io/workr/reference/DemoApp_Server.md).
Registered providers can be referenced from `lConfig$LoadData` with a
single character string.

Registered load providers must accept `lWorkflow`, `lConfig`, and
`lData` as named formals.

## Usage

``` r
register_load_provider(name, provider)
```

## Arguments

- name:

  `string` Non-empty provider name.

- provider:

  `function` Load hook implementation.

## Value

Invisibly returns `name`.

## Examples

``` r
if (FALSE) { # \dontrun{
register_load_provider(
  "example.load",
  function(lWorkflow, lConfig, lData) lData
)
} # }
```
