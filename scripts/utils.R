# Utils for loading or installing packages

# If a package is already installed, it is loaded
# If a package is not installed, it is installed and then loaded
load_packages <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE, quietly = TRUE)
    }
  }
}

required_packages <- c(
  "ggplot2",
  "dplyr",
  "readr",
  "tidyr",
  "patchwork",
  "scales",
  "gtools",
  "tools",
  "stringr",
  "forcats"
)
load_packages(required_packages)

# Utils for reading data

load_qualtrics_data <- function(subfolder, filename, fileEncoding = NULL) {
  # A function to read in Qualtrics data. Call like so:
  # df <- load_qualtrics_data("survey_data", "responses.csv")
  # OR
  # df <- load_qualtrics_data("survey_data", "responses.csv", fileEncoding = "UTF-8")

  # In my ~/.Renviron file, I have DATA_PATH = "/Path/to/data/folder"
  # To reuse this code, edit your .Renviron file or just write the path here
  data_path <- file.path(Sys.getenv("DATA_PATH"), subfolder, filename)

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
  "#353535"
)

# Save a plot
# Path is in my ~/.Renviron file
figure_path <- Sys.getenv("FIGURE_PATH")
save_plot <- function(fname, w, h) {
  ggsave(
    filename = fname,
    path = figure_path,
    width = w,
    height = h,
    device = "tiff",
    dpi = 700
  )
}




# Utils to clean data

# For all entries in the data frame, strip text after the colon
strip_descriptions <- function(df) {
  apply(df, MARGIN = c(1, 2), FUN = function(x) strsplit(x, ":")[[1]][1])
}


# Run the substition function in a for loop.
# Input: a list where keys are the beginning of
# the long response and values are the short response.
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
# THIS IS OLD; USE shorten_long_responses INSTEAD?
# recode_dataframe <- function(df, codes) {
#   return(
#     as.data.frame(lapply(df, recode_column, codes))
#   )
# }

# recode_column <- function(column, codes) {
#   return(
#     names(codes)[match(column, codes)]
#   )
# }

recode_dataframe_likert <- function(df, codes) {
  return(
    df %>%
      mutate(across(everything(), ~ codes[.x]))
  )
}







make_df_binary <- function(df) {
  return(
    df %>% # Convert "Non-applicable" to NA
      mutate(across(everything(), ~ ifelse(.x == "Non-applicable", NA, .x)))
      %>% # Turn empty strings into NAs, and turn non-empty strings into 1s
      mutate(across(everything(), ~ ifelse(.x == "", NA, 1)))
      %>% # Convert all NAs to 0s
      mutate(across(everything(), ~ ifelse(is.na(.x), 0, .x)))
  )
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

exclude_empty_rows <- function(df) {
  df[rowSums(df != 0 & df != "" & !is.na(df)) > 0, , drop = FALSE]
} # Exclude rows that are entirely 0, NA, or empty strings.







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
