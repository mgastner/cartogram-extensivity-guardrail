# diagnostics.R — visual diagnostics for classifier input data
#
# Both functions require GGally, ggplot2, spdep, and scales (all Suggests).
# They are intended for interactive development only, not the runtime pipeline.

#' Scatter plot matrix of area, population, density, and benchmark variable
#'
#' Variables are displayed on log10 scales with original values as tick labels.
#' Points that are >= 3 IQR from the median on the log10 scale in either
#' panel variable are labelled with region names when `name_col` is supplied.
#'
#' @param data An `sf` object with columns `pop_col` and `value_col`.
#' @param value_col Character. Name of the benchmark variable column.
#' @param pop_col Character. Name of the population column. Default `"pop_gpw"`.
#' @param name_col Character or `NULL`. Name of the column containing region
#'   labels used to annotate outliers. No labels are added when `NULL`.
#' @return A `ggmatrix` object.
#' @keywords internal
plot_scatter_matrix <- function(data, value_col, pop_col = "pop_gpw", name_col = NULL) {
  rlang::check_installed("GGally",  reason = "required for plot_scatter_matrix()")
  rlang::check_installed("ggplot2", reason = "required for plot_scatter_matrix()")
  rlang::check_installed("scales",  reason = "required for plot_scatter_matrix()")

  area_km2 <- as.numeric(sf::st_area(
    sf::st_transform(data, crs = "ESRI:54009")
  )) / 1e6

  df <- tibble::tibble(
    v1 = area_km2,
    v2 = data[[pop_col]],
    v3 = data[[pop_col]] / area_km2,
    v4 = data[[value_col]]
  )
  names(df) <- c("Area (km2)", "Population", "Density (pop/km2)", value_col)

  region_names <- if (!is.null(name_col)) {
    data[[name_col]]
  } else {
    rep(NA_character_, nrow(df))
  }

  is_outlier <- function(x) {
    lx  <- log10(x)
    med <- median(lx, na.rm = TRUE)
    iq  <- IQR(lx, na.rm = TRUE)
    abs(lx - med) >= 3 * iq
  }

  int_breaks_log10 <- function(limits) {
    lo <- floor(log10(max(limits[1], 1e-300)))
    hi <- ceiling(log10(max(limits[2], 1e-300)))
    10^seq(lo, hi, by = 1)
  }
  log10_scale_x <- ggplot2::scale_x_log10(
    breaks = int_breaks_log10,
    labels = scales::label_log(base = 10)
  )
  log10_scale_y <- ggplot2::scale_y_log10(
    breaks = int_breaks_log10,
    labels = scales::label_log(base = 10)
  )

  point_log <- function(data, mapping, ...) {
    xvar <- rlang::as_name(mapping$x)
    yvar <- rlang::as_name(mapping$y)

    out_x <- is_outlier(data[[xvar]])
    out_y <- is_outlier(data[[yvar]])
    label_mask <- (out_x | out_y) & !is.na(region_names)
    label_mask[is.na(label_mask)] <- FALSE

    p <- ggplot2::ggplot(data = data, mapping = mapping) +
      ggplot2::geom_point(alpha = 0.6, size = 1.5) +
      log10_scale_x +
      log10_scale_y

    if (!is.null(name_col) && any(label_mask)) {
      rlang::check_installed("ggrepel", reason = "required for outlier labels in plot_scatter_matrix()")
      label_df <- data[label_mask, ]
      label_df$.label <- region_names[label_mask]
      p <- p + ggrepel::geom_text_repel(
        data    = label_df,
        mapping = ggplot2::aes(label = .label),
        size    = 2.8,
        color   = "grey30",
        max.overlaps = 20
      )
    }
    p
  }

  density_log <- function(data, mapping, ...) {
    ggplot2::ggplot(data = data, mapping = mapping) +
      ggplot2::geom_density() +
      log10_scale_x
  }

  cor_log <- function(data, mapping, ...) {
    xvar <- rlang::as_name(mapping$x)
    yvar <- rlang::as_name(mapping$y)
    r <- cor(log10(data[[xvar]]), log10(data[[yvar]]), use = "complete.obs")
    p <- cor.test(log10(data[[xvar]]), log10(data[[yvar]]))$p.value
    stars <- dplyr::case_when(
      p < 0.001 ~ "***",
      p < 0.01  ~ "**",
      p < 0.05  ~ "*",
      .default  = ""
    )
    label <- paste0(round(r, 3), stars)
    ggplot2::ggplot(data = data, mapping = mapping) +
      ggplot2::annotate("text", x = 0.5, y = 0.5, label = label,
                        size = 3.5, color = "grey20") +
      ggplot2::theme_void()
  }

  GGally::ggpairs(
    df,
    lower = list(continuous = point_log),
    diag  = list(continuous = density_log),
    upper = list(continuous = cor_log)
  ) +
    ggplot2::theme_bw(base_size = 10)
}

#' Proportional-symbol map with topological fill colours
#'
#' Regions are filled with topologically distinct colours (graph colouring
#' via `spdep`) and overlaid with circles whose areas are proportional to
#' `log10(value_col)`. The map is shown in the Mollweide equal-area projection.
#'
#' @param data An `sf` object. Must contain `value_col`.
#' @param value_col Character. Name of the benchmark variable column.
#' @return A `ggplot` object.
#' @keywords internal
plot_symbol_map <- function(data, value_col) {
  rlang::check_installed("ggplot2", reason = "required for plot_symbol_map()")
  rlang::check_installed("spdep",   reason = "required for plot_symbol_map()")
  rlang::check_installed("scales",  reason = "required for plot_symbol_map()")

  # Centre Lambert Azimuthal Equal Area on the data's bounding box centroid
  bb   <- sf::st_bbox(data)
  lon0 <- (bb[["xmin"]] + bb[["xmax"]]) / 2
  lat0 <- (bb[["ymin"]] + bb[["ymax"]]) / 2
  crs_laea <- sprintf(
    "+proj=laea +lon_0=%f +lat_0=%f +datum=WGS84 +units=m +no_defs",
    lon0, lat0
  )

  data_ea            <- sf::st_transform(data, crs = crs_laea)
  nb                 <- spdep::poly2nb(data_ea, queen = TRUE)
  color_id           <- greedy_color(nb, nrow(data_ea))
  data_ea$topo_color <- factor(color_id)

  centroids <- sf::st_centroid(sf::st_geometry(data_ea))
  coords    <- sf::st_coordinates(centroids)
  raw_vals  <- data_ea[[value_col]]
  keep      <- is.finite(raw_vals)
  sym_df    <- tibble::tibble(
    x     = coords[keep, 1],
    y     = coords[keep, 2],
    value = raw_vals[keep]
  )
  sym_df$rank <- rank(sym_df$value, ties.method = "average")

  n        <- nrow(sym_df)
  probs    <- c(0.25, 0.5, 0.75, 1.0)
  q_ranks  <- round(probs * n)                          # rank positions
  q_values <- quantile(sym_df$value, probs = probs, na.rm = TRUE)     # original values at those quantiles

  # Format legend labels: use scientific notation for large numbers
  q_labels <- scales::label_comma(accuracy = NULL)(q_values)

  n_colors <- nlevels(data_ea$topo_color)
  palette  <- c("#4477AA", "#EE6677", "#228833", "#CCBB44",
                "#66CCEE", "#AA3377", "#BBBBBB")[seq_len(n_colors)]

  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data    = data_ea,
      mapping = ggplot2::aes(fill = topo_color),
      color   = "white", linewidth = 0.3
    ) +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::geom_point(
      data    = sym_df,
      mapping = ggplot2::aes(x = x, y = y, size = rank),
      shape = 21, fill = "black", color = "white", alpha = 0.75
    ) +
    ggplot2::scale_size_area(
      name     = value_col,
      max_size = 15,
      breaks   = q_ranks,
      labels   = q_labels
    ) +
    ggplot2::coord_sf(expand = FALSE) +
    ggplot2::theme_void(base_size = 11) +
    ggplot2::labs(
      title    = paste("Proportional-symbol map:", value_col),
      subtitle = "Lambert Azimuthal Equal Area projection \u2022 symbol area \u221d rank"
    ) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold")
    )
}

#' Greedy graph colouring from an spdep neighbour list
#'
#' @param nb An `nb` object from `spdep::poly2nb()`.
#' @param n  Number of nodes.
#' @return Integer vector of colour indices (1-based).
#' @keywords internal
greedy_color <- function(nb, n) {
  colors <- integer(n)
  for (i in seq_len(n)) {
    neighbor_colors <- colors[nb[[i]][nb[[i]] > 0]]
    k <- 1L
    while (k %in% neighbor_colors) k <- k + 1L
    colors[i] <- k
  }
  colors
}


#' Interactive scatter plot matrix with linked highlighting
#'
#' Hover over a point in one panel to highlight the same admin division in all
#' panels. Tooltips show division name and axis values.
#'
#' @param data An `sf` object with columns `pop_col` and `value_col`.
#' @param value_col Character. Name of the benchmark variable column.
#' @param pop_col Character. Name of the population column. Default `"pop_gpw"`.
#' @param name_col Character. Name of the column containing region labels.
#' @return A `plotly` htmlwidget.
#' @keywords internal
plot_interactive_scatter_matrix <- function(data, value_col,
                                           pop_col = "pop_gpw",
                                           name_col = "NAM_1") {
  rlang::check_installed("plotly",    reason = "required for plot_interactive_scatter_matrix()")
  rlang::check_installed("crosstalk", reason = "required for plot_interactive_scatter_matrix()")

  area_km2 <- as.numeric(sf::st_area(
    sf::st_transform(data, crs = "ESRI:54009")
  )) / 1e6

  df <- data.frame(
    area     = area_km2,
    pop      = data[[pop_col]],
    density  = data[[pop_col]] / area_km2,
    value    = data[[value_col]],
    name     = data[[name_col]],
    stringsAsFactors = FALSE
  )
  vars <- c("area", "pop", "density", "value")
  labels <- c("Area (km2)", "Population", "Density (pop/km2)", value_col)

  sd <- crosstalk::SharedData$new(df, key = ~name)

  panels <- list()
  for (i in seq_along(vars)) {
    for (j in seq_along(vars)) {
      p <- plotly::plot_ly(
        sd,
        x         = as.formula(paste0("~", vars[j])),
        y         = as.formula(paste0("~", vars[i])),
        text      = ~name,
        hoverinfo = "text+x+y",
        type      = "scatter",
        mode      = "markers",
        marker    = list(size = 6, opacity = 0.7)
      ) |>
        plotly::layout(
          xaxis = list(title = labels[j], type = "log"),
          yaxis = list(title = labels[i], type = "log")
        )
      panels <- c(panels, list(p))
    }
  }

  plotly::subplot(
    panels,
    nrows  = length(vars),
    shareX = TRUE,
    shareY = TRUE,
    titleX = TRUE,
    titleY = TRUE
  ) |>
    plotly::highlight(on = "plotly_hover", off = "plotly_doubleclick",
                      color = "red") |>
    plotly::layout(title = paste("Interactive Scatter Matrix:", value_col),
                   showlegend = FALSE)
}

