# Simple example function

This function is used in the demo workflows to demonstrate how to run a
workflow step that performs a simple operation.

## Usage

``` r
sum_step(lData, y)
```

## Arguments

- lData:

  `list` A named list of data objects. The function expects
  `lData$value` to be a numeric value.

- y:

  `numeric` A numeric value to add to `lData$value`.

## Value

`numeric` The result of adding `y` to `lData$value`.

## Examples

``` r
sum_step(list(value = 5), 3)
#> [1] 8
```
