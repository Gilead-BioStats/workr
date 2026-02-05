# Run a SQL query on a data frame or DuckDB table

Executes a SQL query on a data frame or DuckDB lazy table, creating an
in-memory DuckDB table when needed. The query must include a `FROM df`
placeholder.

## Usage

``` r
RunQuery(strQuery, df, bUseSchema = FALSE, lColumnMapping = NULL)
```

## Arguments

- strQuery:

  `character` SQL query to run, containing `"FROM df"`.

- df:

  `data.frame` or `tbl_dbi` for the SQL query.

- bUseSchema:

  `boolean` enforce data types with a schema.

- lColumnMapping:

  `list` column specifications when `bUseSchema = TRUE`.

## Value

`data.frame` with query results.

## Examples

``` r
if (requireNamespace("DBI", quietly = TRUE) &&
    requireNamespace("dbplyr", quietly = TRUE) &&
    requireNamespace("duckdb", quietly = TRUE)) {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, 70000)
  )

  query <- "SELECT Name, Salary FROM df WHERE Age >= 30"
  RunQuery(query, df)
}
#> [INFO] Creating a new temporary DuckDB connection.
#> [INFO] SQL Query complete: 2 rows returned.
#> [INFO] Disconnected from temporary DuckDB connection.
#>   Name Salary
#> 1 Jane  60000
#> 2  Bob  70000
```
