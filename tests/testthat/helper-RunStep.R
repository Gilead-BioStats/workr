dummy_function <- function(x, y) {
  return(list(x = x, y = y))
}
another_dummy_function <- function(a, b, c) {
  return(list(a = a, b = b, c = c))
}

assign("dummy_function", dummy_function, envir = .GlobalEnv)
assign("another_dummy_function", another_dummy_function, envir = .GlobalEnv)
