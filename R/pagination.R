# Internal helpers used by `as_gglist()` to expand ggforce paginated facets.

is_paginated <- function(plot) {
  inherits(plot, "gg") &&
    inherits(plot$facet, c("FacetWrapPaginate", "FacetGridPaginate"))
}

n_pages_for_plot <- function(plot) {
  if (!is_paginated(plot)) {
    return(1L)
  }
  rlang::check_installed("ggforce", reason = "to render paginated facets")
  np <- ggforce::n_pages(plot)
  if (is.null(np)) 1L else as.integer(np)
}

gg_to_pages <- function(plot) {
  if (!is_paginated(plot)) {
    return(list(plot))
  }
  np <- n_pages_for_plot(plot)
  # `plot$facet` is a ggproto object (reference semantics); modifying its
  # `params$page` field mutates the shared facet for every reference to it.
  # Deep-clone the plot per page so the returned list elements render
  # independently.
  lapply(seq_len(np), function(i) {
    p <- unserialize(serialize(plot, NULL))
    p$facet$params$page <- i
    p
  })
}
