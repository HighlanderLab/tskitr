#!/usr/bin/env Rscript

# Set platform-specific linker flags for RcppTskit
setRcppTskitLibAndFlags <- function() {
  sysname <- Sys.info()[["sysname"]]
  os_type <- .Platform$OS.type
  if (os_type == "unix") {
    libname <- "RcppTskit.so"
    if (sysname == "Darwin") {
      # macOS: Use -install_name with @rpath for better portability
      return(paste0("-Wl,-install_name,@rpath/", libname))
    } else {
      # Linux/Solaris/FreeBSD: Use -soname for shared library versioning
      return(paste0("-Wl,-soname,", libname))
    }
  } else if (os_type == "windows") {
    # Windows: Rtools 4.x/5.x uses --out-implib for import libraries
    # libname should typically be the import library .dll.a
    libname <- "RcppTskit.dll.a"
    return(paste0("-Wl,--out-implib,", libname))
  } else {
    stop(sprintf("Unsupported platform: %s (%s)", sysname, os_type))
  }
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
} else if (.Platform$OS.type == "windows") {
  # readLines(con = "src/Makevars.win.in")
  success <- renderMakevars(
    # Currently, both Unix and Windows use the same template
    # template = "src/Makevars.win.in",
    template = "src/Makevars.in",
    output = "src/Makevars.win"
  )
} else {
  stop("Unknown .Platform$OS.type!")
}
if (!success) {
  stop("renderMakevars() failed!")
}
