context("test_get_tskit")

test_that("get_tskit() works", {
  # Next two lines ensrue that testthat environment testing works
  assign("rubbish", "something_else_than_py_module", envir = .GlobalEnv)
  on.exit(rm("rubbish", envir = .GlobalEnv), add = TRUE)
  expect_error(
    get_tskit(obj_name = "rubbish"),
    regexp = "Object 'rubbish' exists in the global environment but is not a reticulate Python module"
  )

  # Install and import on the first call
  if (exists("tskit", envir = .GlobalEnv)) {
    rm("tskit", envir = .GlobalEnv)
  }
  tskit <- get_tskit()
  # lobstr::obj_addr(tskit)
  # "0x143d3b920"
  expect_true(is_py_object(tskit))
  expect_true(is(tskit) == "python.builtin.module")
  expect_equal(tskit$`__name__`, "tskit")

  # Next two lines ensrue that testthat environment testing works
  assign("tskit", tskit, envir = .GlobalEnv)
  on.exit(rm("tskit", envir = .GlobalEnv), add = TRUE)
  tskit2 <- get_tskit()
  # lobstr::obj_addr(tskit2)
  # "0x143d3b920"
  # should be the same address as for tskit because we are obtaining the same object
  expect_equal(tskit$`__name__`, tskit2$`__name__`)

  tskit3 <- get_tskit(obj_name = NULL)
  # lobstr::obj_addr(tskit3)
  # "0x133c33f88"
  # should be different address as for tskit because we are obtaining a new object
  # but it is still the same module
  expect_equal(tskit$`__name__`, tskit3$`__name__`)
})
