#!/usr/bin/env Rscript

# Set platform specific name of RcppTskit library and add appropriate flags
setRcppTskitLibAndFlags <- function() {
  if (.Platform$OS.type == "unix") {
    # Unix/Linux & macOS
    libname <- "RcppTskit.so"
  } else if (.Platform$OS.type == "windows") {
    libname <- "RcppTskit.dll.a" # MinGW/Rtools (default)
    # "RcppTskit.lib" # MSVC (backup to MinGW/Rtools)
    # "RcppTskit.dll" # DLL (backup to MinGW/Rtools)
  } else {
    stop("Unknown .Platform$OS.type!")
  }
  # TODO: Make configure.R::setRcppTskitLibAndFlags() portable across Unix/Linux/macOS/Windows platforms #19
  #       https://github.com/HighlanderLab/RcppTskit/issues/19
  ret <- paste0("-Wl,-install_name,@rpath/", libname)
  return(ret)
}

# Render a Makevars file from a template by replacing placeholders.
# @param template character path to the template Makevars file
# @param output character path to the output Makevars file
renderMakevars <- function(template, output) {
  if (!file.exists(template)) {
    stop("Template file does not exist: ", template, "!")
  }
  RcppTskitLibAndFlags <- setRcppTskitLibAndFlags()
  lines <- readLines(con = template)
  lines <- gsub(
    x = lines,
    pattern = "@RCPPTSKIT_LIB@",
    replacement = RcppTskitLibAndFlags,
    fixed = TRUE
  )
  writeLines(text = lines, con = output)
  invisible(TRUE)
}

# renderMakevars(template = "this_should_fail", output = "before_getting_to_output")

if (.Platform$OS.type == "unix") {
  # readLines(con = "src/Makevars.in")
  success <- renderMakevars(
    template = "src/Makevars.in",
    output = "src/Makevars"
  )
} else {
  # readLines(con = "src/Makevars.win.in")
  success <- renderMakevars(
    # Currently, both Unix and Windows use the same template
    # template = "src/Makevars.win.in",
    template = "src/Makevars.in",
    output = "src/Makevars.win"
  )
}
if (!success) {
  stop("renderMakevars() failed!")
}
