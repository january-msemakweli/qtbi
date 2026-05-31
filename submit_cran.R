cran_url <- "https://xmpalantir.wu.ac.at/cransubmit/index2.php"
tarball <- normalizePath("dist/qtbi_0.1.2.tar.gz", winslash = "/")
comments <- paste(readLines("cran-comments.md", warn = FALSE), collapse = "\n")

if (!requireNamespace("httr2", quietly = TRUE)) {
  install.packages("httr2", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("curl", quietly = TRUE)) {
  install.packages("curl", repos = "https://cloud.r-project.org")
}

library(httr2)

cat("Step 1: upload...\n")
req1 <- request(cran_url) |>
  req_body_multipart(
    pkg_id = "",
    name = "January G. Msemakweli",
    email = "jmsemak1@jh.edu",
    uploaded_file = curl::form_file(tarball, "application/x-gzip"),
    comment = comments,
    upload = "Upload package"
  )
resp1 <- req_perform(req1)
url1 <- url_parse(resp_url(resp1))
pkg_id <- url1$query$pkg_id
cat("pkg_id:", pkg_id, "\n")

if (is.null(pkg_id) || !nzchar(pkg_id)) {
  stop("Upload step did not return pkg_id.")
}

cat("Step 2: confirm...\n")
req2 <- request(cran_url) |>
  req_body_multipart(
    pkg_id = pkg_id,
    name = "January G. Msemakweli",
    email = "jmsemak1@jh.edu",
    policy_check = "1/",
    submit = "Submit package"
  )
resp2 <- req_perform(req2)
url2 <- url_parse(resp_url(resp2))
submit_flag <- url2$query$submit
cat("submit flag:", submit_flag, "\n")

if (identical(submit_flag, "1")) {
  cat("SUCCESS: Check jmsemak1@jh.edu for CRAN confirmation email.\n")
  quit(status = 0)
}

cat("FAILED: submission not confirmed.\n")
quit(status = 1)
