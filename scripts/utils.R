# Utils for reading data

load_qualtrics_data <- function(filename, fileEncoding = NULL) {
  # In my ~/.Renviron file, I have DATA_PATH = "/Path/to/data/folder"
  data_path <- file.path(Sys.getenv("DATA_PATH"), filename)

  # Base arguments to pass to read.csv
  args <- list(
    file = data_path,
    header = TRUE,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  # Conditionally add fileEncoding if provided
  if (!is.null(fileEncoding)) {
    args$fileEncoding <- fileEncoding
  }
  # Call read.csv with constructed argument list.
  # This way, read.csv will automatically choose
  # a fileEncoding if it is not specified.
  do.call(read.csv, args)
}


# Utils for plotting

colors <- c(
  # modified from https://sronpersonalpages.nl/~pault/
  "#332288",
  "#88CCEE",
  "#44AA99",
  "#117733",
  "#999933",
  "#DDCC77",
  "#CC6677",
  "#882255",
  "#AA4499",
  "#BBBBBB"
)


# Re-order factor levels in one column by values in another.
# Returns the original data frame with factor_col re-ordered based on value_col.
# Leave column names unquoted.
reorder_factor_by_column <- function(
  df,
  factor_col,
  value_col,
  descending = TRUE
) {
  df <- df %>%
    mutate(
      {{ factor_col }} := fct_reorder(
        # double-curlys and := assign a col by name using tidy evaluation
        .f = {{ factor_col }},
        .x = {{ value_col }},
        .fun = if (descending) `-` else identity # If descending = TRUE, add a negative sign (-) to reverse the sort
      )
    )
  return(df)
}


basic_bar_chart <- function(
  df,
  x_var,
  y_var,
  title,
  ylabel = "Number of Respondents",
  show_axis_title_x = FALSE,
  show_axis_title_y = TRUE,
  axis_title_size_x = 24,
  axis_title_size_y = 24,
  axis_text_size_x = 22,
  axis_text_size_y = 22,
  axis_text_angle_x = 60,
  title_size = 24,
  color_index = 1,
  horizontal = FALSE,
  show_ticks_x = FALSE,
  show_ticks_y = TRUE,
  show_bar_labels = FALSE,
  label_position = c("inside", "above"),
  label_color = "white",
  show_grid = TRUE,
  percent = FALSE
) {
  label_position <- match.arg(label_position)

  # Axis title settings
  axis_title_x <- if (show_axis_title_x) {
    element_text(size = axis_title_size_x)
  } else {
    element_blank()
  }
  axis_title_y <- if (show_axis_title_y) {
    element_text(size = axis_title_size_y)
  } else {
    element_blank()
  }

  # Axis tick settings
  axis_ticks_x <- if (show_ticks_x) element_line() else element_blank()
  axis_ticks_y <- if (show_ticks_y) element_line() else element_blank()

  # Build the plot
  p <- ggplot(df, aes(x = .data[[x_var]], y = .data[[y_var]])) +
    geom_bar(stat = "identity", fill = colors[[color_index]]) +
    ggtitle(title) +
    labs(y = ifelse(is.null(ylabel), "Number of Respondents", ylabel)) +
    theme(
      axis.title.x = axis_title_x,
      axis.title.y = axis_title_y,
      axis.text.x = element_text(
        angle = axis_text_angle_x,
        vjust = 0.6,
        size = axis_text_size_x
      ),
      axis.text.y = element_text(size = axis_text_size_y),
      axis.ticks.x = axis_ticks_x,
      axis.ticks.y = axis_ticks_y,
      legend.position = "none",
      panel.background = element_blank(),
      panel.grid = if (show_grid) {
        element_line(linetype = "solid", color = "gray90")
      } else {
        element_blank()
      },
      plot.title = element_text(hjust = 0.5, size = title_size),
      plot.margin = unit(c(0.3, 0.3, 0.3, 0.3), "cm")
    )

  # Convert y-axis values from proportion to percent (optional)
  if (percent) {
    p <- p +
      scale_y_continuous(labels = scales::percent)
  }

  # Add text labels (optional)
  if (show_bar_labels) {
    if (horizontal) {
      p <- p +
        geom_text(
          aes(label = .data[[y_var]]),
          color = label_color,
          size = 8,
          hjust = if (label_position == "inside") 1.2 else -0.1, # shift left of bar end
          vjust = 0.5
        )
    } else {
      # vertical bars
      p <- p +
        geom_text(
          aes(label = .data[[y_var]]),
          color = label_color,
          size = 8,
          vjust = if (label_position == "inside") 1.2 else -0.3, # above bar = negative vjust
          hjust = 0.5
        )
    }
  }

  # Flip coordinates if horizontal
  if (horizontal) {
    p <- p + coord_flip()
  }

  return(p)
}


stacked_bar_chart <- function(
  df,
  x_var,
  y_var,
  fill,
  title,
  ylabel = NULL,
  show_grid = TRUE,
  proportional = FALSE
) {
  # Set position for geom_bar
  position_type <- if (proportional) "fill" else "stack"

  # Determine y-axis label if not provided
  ylabel_final <- if (!is.null(ylabel)) {
    ylabel
  } else if (proportional) {
    "Proportion of Responses"
  } else {
    "Number of Responses"
  }

  # Build the plot
  p <- ggplot(
    df,
    aes(x = .data[[x_var]], y = .data[[y_var]], fill = .data[[fill]])
  ) +
    geom_bar(stat = "identity", position = position_type) +
    ggtitle(title) +
    labs(y = ylabel_final) +
    scale_fill_manual(values = colors) +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 24),
      axis.text.x = element_text(
        angle = 60,
        vjust = 0.9,
        hjust = 0.98,
        size = 24
      ),
      axis.text.y = element_text(size = 24),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      panel.background = element_blank(),
      panel.grid = if (show_grid) {
        element_line(linetype = "solid", color = "gray90")
      } else {
        element_blank()
      },
      legend.title = element_blank(),
      legend.text = element_text(size = 24),
      plot.title = element_text(hjust = 0.5, size = 24),
      plot.margin = unit(c(0.4, 0.4, 0.4, 0.4), "cm")
    )
  return(p)
}


grouped_bar_chart <- function(
  df,
  x_var,
  fill_var,
  title,
  ylabel = NULL,
  show_grid = TRUE
) {
  ylabel <- ifelse(is.null(ylabel), "Number of Respondents", ylabel)
  ggplot(df, aes(x = .data[[x_var]], fill = .data[[fill_var]])) +
    geom_bar(position = "dodge") +
    ggtitle(title) +
    labs(y = ylabel) +
    scale_fill_manual(values = colors) +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 24),
      axis.text.x = element_text(angle = 60, vjust = 0.6, size = 18),
      axis.text.y = element_text(size = 18),
      axis.ticks.x = element_blank(),
      legend.title = element_blank(),
      legend.text = element_text(size = 18),
      panel.background = element_blank(),
      panel.grid = if (show_grid) {
        element_line(linetype = "solid", color = "gray90")
      } else {
        element_blank()
      },
      plot.title = element_text(hjust = 0.5, size = 24),
      plot.margin = unit(c(0.3, 0.3, 0.3, 0.3), "cm")
    )
}


# Save a plot
# Path is in my ~/.Renviron file
figure_path <- Sys.getenv("FIGURE_PATH")
save_plot <- function(fname, w, h, p = NULL, ftype = "tiff", res = 700) {
  ggsave(
    filename = fname,
    width = w,
    height = h,
    plot = p, # if NULL, ggsave() will use the last‐drawn plot
    device = ftype,
    dpi = res,
    path = figure_path
  )
}


# Utils to clean data

# For all entries in the data frame, strip text after the colon
strip_descriptions <- function(df) {
  apply(df, MARGIN = c(1, 2), FUN = function(x) strsplit(x, ":")[[1]][1])
}


# Replace long responses with shorter strings.
# Input: a list where keys are the beginning of
# the long response and values are the short response.
# The column you're trying to edit must be a character column, not a factor.
shorten_long_responses <- function(df, codes) {
  new_df <- df
  for (keyword in names(codes)) {
    new_df <- shorten_long_response(new_df, keyword, codes[[keyword]])
  }
  return(new_df)
}
shorten_long_response <- function(df, keyword, replacement) {
  pattern <- paste0("^", stringr::fixed(keyword))
  df <- df %>%
    mutate(across(
      where(is.character),
      ~ ifelse(str_starts(.x, keyword), replacement, .x)
    ))
  return(df)
}

## Functions for renaming columns

# Return a data frame with new column names, based on the entries in each column
rename_cols_based_on_entries <- function(df) {
  colnames(df) <- sapply(seq_len(ncol(df)), function(x) {
    get_unique_vals(df, x)
  })
  as.data.frame(df)
}
# Propose a column name based on the entries in that column.
# Only works if all entries in a column are the same.
# Ignores NA and empty strings.
get_unique_vals <- function(df, col_num) {
  unique_vals <- unique(df[, col_num])
  unique_vals <- unique_vals[!(is.na(unique_vals) | unique_vals == "")]
  stopifnot(length(unique_vals) == 1)
  unique_vals
}

# Example usage:
# r$> df <- data.frame(
#     col1 = c("A", "A", "", NA, "A"),
#     col2 = c("B", "", "B", NA, NA)
# )
# r$> get_unique_vals(df, 2)
# [1] "B"

rename_cols_based_on_codenames <- function(df, codes) {
  return(
    df %>%
      rename(any_of(codes))
  )
}


# Replace values in a data frame with new values based on a list of codes.

recode_dataframe_likert <- function(df, codes, likert_cols) {
  df %>%
    mutate(
      across(
        all_of(likert_cols),
        ~ codes[as.character(.x)] # convert factor to character first
      )
    )
}


make_df_binary <- function(df, cols = NULL) {
  # Determine columns to modify
  if (is.null(cols)) {
    cols_to_modify <- names(df)
  } else if (is.numeric(cols)) {
    cols_to_modify <- names(df)[cols]
  } else if (is.character(cols)) {
    cols_to_modify <- cols
  } else {
    stop(
      "`cols` must be NULL, a character vector of column names, or numeric indices."
    )
  }

  df <- df %>%
    # Convert "Non-applicable" to NA
    mutate(across(
      all_of(cols_to_modify),
      ~ ifelse(.x == "Non-applicable", NA, .x)
    )) %>%
    # Turn empty strings into NAs, and turn non-empty strings into 1s
    mutate(across(all_of(cols_to_modify), ~ ifelse(.x == "", NA, 1))) %>%
    # Convert all NAs to 0s
    mutate(across(all_of(cols_to_modify), ~ ifelse(is.na(.x), 0, .x)))

  return(df)
}
# ^EXAMPLE:
# r$> motivations
#    Job Improve Tools Customize Network Give back Skills Fun Other
# 1
# 2
# 3      Improve Tools Customize         Give back Skills Fun Other
# 4
# 5
# 6  Job Improve Tools Customize Network Give back Skills Fun Other
# 7  Job Improve Tools                   Give back Skills
# 8                                      Give back Skills Fun Other
# 9
# 10 Job Improve Tools                   Give back Skills

# Becomes:
# r$> motivations
#    Job Improve Tools Customize Network Give back Skills Fun Other
# 1    0             0         0       0         0      0   0     0
# 2    0             0         0       0         0      0   0     0
# 3    0             1         1       0         1      1   1     1
# 4    0             0         0       0         0      0   0     0
# 5    0             0         0       0         0      0   0     0
# 6    1             1         1       1         1      1   1     1
# 7    1             1         0       0         1      1   0     0
# 8    0             0         0       0         1      1   1     1
# 9    0             0         0       0         0      0   0     0
# 10   1             1         0       0         1      1   0     0

# Function to drop rows that are entirely NA or empty strings.
# Rows of all zeros will be retained.
# strict mode: drop rows containing even one NA or empty string.
exclude_empty_rows <- function(df, strict = FALSE) {
  # Create a logical matrix indicating where values are NA or ""
  missing_mat <- is.na(df) | df == ""

  # Count per-row how many “missing” entries there are
  missing_per_row <- rowSums(missing_mat)
  n_cols <- ncol(df)

  if (strict) {
    # Keep only rows with zero missing entries
    keep <- missing_per_row == 0
  } else {
    # Keep rows that are not entirely missing
    keep <- missing_per_row < n_cols
  }

  # Subset, preserving data.frame structure even if one column
  df[keep, , drop = FALSE]
}


exclude_empty_columns <- function(df) {
  df[, colSums(is.na(df) | df == "") < nrow(df)]
} # Drop columns that are entirely NA or empty strings.
# Columns of all zeros will be retained.

# Functions to calculate summary statistics

# Create a summary dataframe (an alternative to summary(importance))
custom_summary <- function(df) {
  mean_row <- round(colMeans(df, na.rm = TRUE), 2)
  median_row <- apply(df, 2, function(x) round(median(x, na.rm = TRUE), 2))
  mode_row <- sapply(df, function(x) round(calculate_mode(x), 2))
  total_value <- apply(df, 2, function(x) round(sum(x, na.rm = TRUE), 2))
  summary_df <- rbind(mean_row, median_row, mode_row, total_value)
  rownames(summary_df) <- c("Mean", "Median", "Mode", "Sum")
  return(summary_df)
}

calculate_mode <- function(x) {
  x <- na.omit(x) # Remove NAs
  if (length(x) == 0) {
    return(NA)
  } # Return NA if no values
  uniq_vals <- unique(x)
  freq <- tabulate(match(x, uniq_vals))
  mode_val <- uniq_vals[which.max(freq)]
  return(mode_val)
}
