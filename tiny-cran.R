library(magrittr)

wd_bak <- getwd()

if (!requireNamespace("pkgKitten")) {
  install.packages("pkgKitten")
}

# Setup ------------------------------------------------------------------------
pkg_name <- "xyzr"

tiny_cran <- path.expand("~/Code/tiny-cran")
repo_name <- "private"

# Create directories -----------------------------------------------------------
# Create a directory for CRAN
if (!dir.exists(tiny_cran)) {
  dir.create(tiny_cran)
}

# Create the src/contrib directory
contrib_dir <- file.path(tiny_cran, "src", "contrib")
if (!dir.exists(contrib_dir)) {
  dir.create(contrib_dir, recursive = TRUE)
}

# Binary paths -----------------------------------------------------------------
# Create bin directory
r_version <- paste(unlist(getRversion())[1:2], collapse = ".")

bin_paths <- list(
  # Windows
  # win_binary = file.path("bin/windows/contrib", r_version),
  # macOS (X86)
  mac_binary = file.path("bin/macosx/contrib", r_version),
  # macOS (ARM)
  # See: https://cran.r-project.org/bin/macosx/
  mac_binary_big_sur = file.path("bin/macosx/big-sur-arm64/contrib", r_version),
  mac_binary_el_capitan = file.path("bin/macosx/el-capitan/contrib", r_version)
)

bin_paths <- lapply(bin_paths, function(x) file.path(tiny_cran, x))
lapply(bin_paths, function(path) {
  dir.create(path, recursive = TRUE)
})

# Create a package -------------------------------------------------------------
temp_dir <- tempdir()
pkgKitten::kitten(pkg_name, path = temp_dir)
pkg_dir <- file.path(temp_dir, pkg_name)

# Repository name
repo_desc_path <- file.path(temp_dir, pkg_name, "DESCRIPTION")
desc_line <- paste0("Repository: ", pkg_name)
cat(desc_line, file = repo_desc_path, append = TRUE, sep = "\n")

# Copy -------------------------------------------------------------------------
setwd(temp_dir)
system2(command = "R", args = c("CMD", "build", pkg_name))
setwd(wd_bak)

tar_path <- list.files(temp_dir, pattern = "tar.gz")

if (length(tar_path) != 1) {
  stop("Multiple tar.gz files found")
}

# Copy it to the src/contrib sub-directory
file.copy(
  file.path(temp_dir, tar_path),
  file.path(contrib_dir, tar_path)
)

lapply(bin_paths, function(path) {
  file.copy(from = file.path(temp_dir, tar_path), to = file.path(path, tar_path))
})

# Write packages for each sub-directory ----------------------------------------
tools::write_PACKAGES(contrib_dir, type = "source")

lapply(bin_paths, function(path) {
  tools::write_PACKAGES(path)
})
