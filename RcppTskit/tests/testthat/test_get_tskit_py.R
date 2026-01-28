test_that("get_tskit_py() works", {
  # Testing that get_tskit_py() fails with a non-module object
  # Next two lines ensure that testthat is looking into the global environment
  # as is get_tskit_py()
  assign("rubbish", "something_else_than_a_py_module", envir = .GlobalEnv)
  on.exit(rm("rubbish", envir = .GlobalEnv), add = TRUE)
  expect_error(
    get_tskit_py(object_name = "rubbish"),
    regexp = "Object 'rubbish' exists in the global environment but is not a reticulate Python module"
  )

  if (!covr::in_covr()) {
    # To get_tskit_py() we need internet connection
    skip_if_offline()

    # The tests below take quite a bit of time since they pull in installation of
    # Python modules, hence skipping on CRAN due to time limits on CRAN
    skip_on_cran()
  }

  # Uncomment the below to explore test behaviour, but note that the removal
  # doesn't work when you try to run the tests multiple times in the same session!
  # Hence we are commenting this next line out.
  # try(reticulate::py_require("tskit", action = "remove"))
  if (!reticulate::py_available(initialize = TRUE)) {
    skip("Python not available for get_tskit_py tests.")
  }
  # Install (if not already installed) & import tskit on the first call
  if (exists("tskit", envir = .GlobalEnv)) {
    rm("tskit", envir = .GlobalEnv)
  }
  tskit <- get_tskit_py()
  # lobstr::obj_addr(tskit)
  # "0x12218b910"
  expect_true(is_py_object(tskit))
  expect_true(is(tskit, "python.builtin.module"))
  expect_equal(tskit$`__name__`, "tskit")

  # Testing that get_tskit_py() returns the same tskit object if it already exists
  # Next two lines ensure that testthat is looking into the global environment
  # as is get_tskit_py()
  assign("tskit", tskit, envir = .GlobalEnv)
  on.exit(rm("tskit", envir = .GlobalEnv), add = TRUE)
  tskit2 <- get_tskit_py()
  # lobstr::obj_addr(tskit2)
  # "0x12218b910" --> the same address as above (as we are gettinh the same object)
  expect_equal(tskit$`__name__`, tskit2$`__name__`)

  # Re-importing
  tskit3 <- get_tskit_py(force = TRUE)
  # lobstr::obj_addr(tskit3)
  # "0x161ec00f0" --> different address because we are obtaining a new object
  # but it is still the same module
  expect_equal(tskit$`__name__`, tskit3$`__name__`)

  # Installing a non-existent module
  out <- get_tskit_py(object_name = "havent_seen_such_a_python_module")
  expect_false(is(out, "python.builtin.module"))
})

test_that("check_tskit_py() validates reticulate Python module objects", {
  expect_message(
    expect_false(check_tskit_py(1)),
    "object must be a reticulate Python module object!"
  )
  expect_error(
    check_tskit_py(1, stop = TRUE),
    "object must be a reticulate Python module object!"
  )

  if (!reticulate::py_available(initialize = TRUE)) {
    skip("Python not available for check_tskit_py tests.")
  }

  obj <- reticulate::py_eval("1")
  expect_message(
    expect_false(check_tskit_py(obj)),
    "object must be a reticulate Python module object"
  )

  sys <- reticulate::import("sys")
  expect_silent(expect_true(check_tskit_py(sys)))

  if (reticulate::py_module_available("tskit")) {
    tskit <- get_tskit_py()
    expect_true(check_tskit_py(tskit))
  } else {
    skip("tskit module not available for check_tskit_py tests.")
  }
})
