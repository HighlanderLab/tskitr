context("test_get_tskit")

test_that("get_tskit() works", {
  # Testing that get_tskit() fails with a non-module object
  # Next two lines ensure that testthat is looking into the global environment
  # as is get_tskit()
  assign("rubbish", "something_else_than_a_py_module", envir = .GlobalEnv)
  on.exit(rm("rubbish", envir = .GlobalEnv), add = TRUE)
  expect_error(
    get_tskit(obj_name = "rubbish"),
    regexp = "Object 'rubbish' exists in the global environment but is not a reticulate Python module"
  )

  # The tests below take quite a bit of time since they pull in installation of
  # Python modules, hence skipping on CRAN due to time limits on CRAN.
  skip_on_cran()

  # Install (if not already) & import tskit on the first call
  if (exists("tskit", envir = .GlobalEnv)) {
    rm("tskit", envir = .GlobalEnv)
  }
  tskit <- get_tskit()
  # lobstr::obj_addr(tskit)
  # "0x12218b910"
  expect_true(is_py_object(tskit))
  expect_true(is(tskit) == "python.builtin.module")
  expect_equal(tskit$`__name__`, "tskit")

  # Testing that get_tskit() returns the same tskit object if it already exists
  # Next two lines ensure that testthat is looking into the global environment
  # as is get_tskit()
  assign("tskit", tskit, envir = .GlobalEnv)
  on.exit(rm("tskit", envir = .GlobalEnv), add = TRUE)
  tskit2 <- get_tskit()
  # lobstr::obj_addr(tskit2)
  # "0x12218b910" --> the same address as above (as we are gettinh the same object)
  expect_equal(tskit$`__name__`, tskit2$`__name__`)

  # Re-importing
  tskit3 <- get_tskit(obj_name = NULL)
  # lobstr::obj_addr(tskit3)
  # "0x161ec00f0" --> different address because we are obtaining a new object
  # but it is still the same module
  expect_equal(tskit$`__name__`, tskit3$`__name__`)
})
