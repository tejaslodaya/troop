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
    
    structure(list(nextElem = nextElem), class = c("iblkrow", "iter"))
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
    structure(list(nextElem = nextElemGroup), class = c("iblkgrouprow", "iter"))
}

# over-riding default iterator
nextElem.iblkgrouprow <- function(obj) obj$nextElem()
