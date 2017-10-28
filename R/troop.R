# custom chunking iterator
iblkrow <- function(data, chunks) {
  
  n <- nrow(data)
  i <- 1
  
  nextElem <- function() {
    
    if (chunks <= 0 || n <= 0) 
      stop("StopIteration")
    m <- ceiling(n/chunks)
    r <- seq(i, length.out = m)
    i <<- i + m
    n <<- n - m
    chunks <<- chunks - 1
    
    data[r, , drop = FALSE]
    
  }
  
  obj <- list(nextElem = nextElem)
  class(obj) <- c('iblkrow','abstractiter','iter')
  obj
}

# over-riding default iterator
nextElem.iblkrow <- function(obj) obj$nextElem()

iblkgrouprow <- function(data, by, chunks) {
  
  all_combinations <- unique(data, by = by)[, ..by]
  
  # iterator inside an iterator. all_combinations will serve as data
  itr <- iblkrow(all_combinations, chunks)
  setkeyv(data, by)
  
  nextElemGroup <- function() {
    comb <- nextElem(itr)
    data[(comb), nomatch = 0]
  }
  
  obj <- list(nextElem = nextElemGroup)
  class(obj) <- c('iblkrowgroup','abstractiter','iter')
  obj
}

# over-riding default iterator
nextElem.iblkgrouprow <- function(obj) obj$nextElem()


#' group by - apply - multiprocess data.table
#'
#' @param data input data of type data.table
#' @param by character vector giving columns to group by
#' @param apply_func function to be run in parallel
#' @param preprocess_func function that will be run before apply_func. useful to open file/db handles
#' @param postprocess_func function that will be run after apply_func. useful to close file/db handles
#' @param num_chunks number of chunks to divide the data into. defaults to number of logical cores available
#' @param preprocess_args a list of args to be passed to preprocess_func
#' @param postprocess_args a list of args to be passed to postprocess_func
#' @param packages character vector of package names to be exported on each core. NOTE: each package used by apply_func should be included
#' @param export character vector of variable names to be exported on each core. NOTE: each variable name to be accessed inside apply_func should be exported
#' @param combine the way results should be combined. accepts: c, +, rbind. defaults to c (character vector)
#' @param files_to_source character vector of file names to be sourced on each core. the userr should have permission to read the file
#' @return result of \code{apply_func} after combining results from each core using combine parameter above
#' @seealso \code{\link{http://stat.ethz.ch/R-manual/R-devel/library/parallel/doc/parallel.pdf}} \cr
#'   \code{\link{http://r.adu.org.za/web/packages/foreach/vignettes/foreach.pdf}} \cr
#'   \code{\link{https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf}} \cr
#'   \code{\link{http://michaeljkoontz.weebly.com/uploads/1/9/9/4/19940979/parallel.pdf}} \cr
#'   \code{\link{https://cran.r-project.org/web/packages/iterators/vignettes/writing.pdf}} \cr
#' @export
#' @examples
#' dt <- data.table(fread('sample.csv'))
#' v <- 10
#' foo <- function(data_chunk){
#'   # some complex operations
#'   nrow(data_chunk)
#' }
#' troop(dt, by = c('column1','column2'), apply_func = foo)
#' troop(dt, by = c('column1','column2'), apply_func = foo, files_to_source = c('somefile.R','anotherfile.R'))
#' troop(dt, by = c('column1','column2'), apply_func = foo, num_chunks = 10, packages = c('RODBC','xgboost'), export = c('v'), combine = 'c')
troop <- function(data, by, apply_func, preprocess_func = function() {
}, postprocess_func = function() {
}, num_chunks = detectCores(logical = TRUE), preprocess_args = list(), postprocess_args = list(), packages = c(), export = c(), combine = "c", 
    files_to_source = c()) {
   
   # TODO : make log_file an input
   log_file <- "cluster.log"
   file.create(log_file)
   
   do.call(preprocess_func, preprocess_args)
   
  cl <- makeCluster(num_chunks, outfile = log_file)
  registerDoParallel(cl)

  packages <- c(packages, "foreach", "data.table")

  # core logic goes here
  if (missing(by)) {
    itr <- iblkrow(data = data, chunks = num_chunks)
  } else {
    itr <- iblkgrouprow(data = data, by = by, chunks = num_chunks)
  }

  resR <- foreach(x = itr, .packages = packages, .export = export, .combine = combine) %dopar% {
    # source file on each core
    sapply(files_to_source, source)
    if (missing(by)) {
      apply_func(x)
    } else {
      combinations <- unique(x, by = by)[, ..by]
      setkeyv(x, by)
      res <- foreach(i = 1:nrow(combinations)) %do% {
        itr_comb <- combinations[i, ]
        itr_data <- x[(itr_comb), nomatch = 0]

        apply_func(itr_data)
        }
      return(res)
      }
  }

  do.call(postprocess_func, postprocess_args)
  on.exit(stopCluster(cl))
  return(resR)
}