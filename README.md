# troop

Pre-requisites for troop - 

1. If you are able to identify repeated patterns in R code and exploit to greatly improve efficiency, both within a multi-core machine and for communication across machines. 
2. If you can replace dynamic cache and server structures with static pre-serialized structures
3. If you can pre-fetch information and determine which data should be cached at each thread to avoid contention and slow access to memory banks attached to sockets.

troop follows a **data-parallel** approach rather than a model-parallel approach where the training data is divided among worker threads that execute in parallel, each performing the work associated with their shard of the training data and communicating updates after completing task over that shard.

In working, troop expects these parameters:

1. Input data of type data.table (`data`)
2. Character vector giving columns to group by (`by`)
3. Function to be run in parallel (`apply_func`)
4. Function that will be run before apply_func. Use it to open file/db handles(`preprocess_func`)
5. Function that will be run after apply_func. useful to close file/db handles (`postprocess_func`)
6. Number of chunks to divide the data into. defaults to number of logical cores available (`num_chunks`)
7. A list of args to be passed to preprocess_func (`preprocess_args`)
8. A list of args to be passed to postprocess_func (`postprocess_args`)
9. Character vector of package names to be exported on each core. Each package used by `apply_func` should be included (`packages`)
10. Character vector of variable names to be exported on each core. Each variable name to be accessed inside `apply_func` should be exported (`export`)
11. The way results should be combined. Accepts: c, +, rbind. Defaults to c (`combine`)
12. Character vector of file names to be sourced on each core. The user should have permission to read the file (`files_to_source`)

troop follows SIMD approach (Single Instruction, Multiple Data), using the `doParallel` package of R. SOCK clusters are created and a chunk of data runs on each cluster

  ![](https://upload.wikimedia.org/wikipedia/commons/2/21/SIMD.svg)

## Getting Started

Logic behind this package is explained in the image below

![](https://raw.githubusercontent.com/tejaslodaya/troop/master/troop.png)


### Prerequisites

R (>= 3.3.2)

### Installation

troop can directly be installed from github

```
install.packages("devtools")
devtools::install_github("tejaslodaya/troop")
```

Thats it! Now you can use the package on your machine

## Example

Barebone example
```
library(data.table)
dt <- data.table(fread('sample.csv'))

resR <- troop::troop(dt, by = c('column1','column2'), apply_func = nrow)
```

Complex example
```
library(data.table)
dt <- data.table(fread('sample.csv'))

var <- 10
foo <- function(data_chunk){
  # some complex operation
  
  resR <- summary(data_chunk)
  return (resR)
}

#source file on each core
result <- troop::troop(dt, by = c('column1','column2'), apply_func = foo, files_to_source = c('somefile.R','anotherfile.R'))

#using packages and exporting variables
result <- troop::troop(dt, by = c('column1','column2'), apply_func = foo, num_chunks = 10, packages = c('RODBC','xgboost'), export = c('var'), combine = 'c')

```

## NOTE

1. Complete documentation of the method can be found by executing `?troop::troop` in R console
2. All variables which are used in apply_func method have to be included in export parameter
3. All packages which are used in apply_func method have to be included in packages parameter
4. If num_chunks passed is less than total number of combinations, in that case each core will execute more than one combination **sequentially**

## TODO

1. Straggler Mitigation - Each time synchronization is required, any one slowed worker thread can cause significant unproductive wait time for the others. Troop should temporarily offload a portion of its work to workers that are currently faster, helping the slowed worker catch up.


## Built With

* [draw.io](http://draw.io/) - website used to create image
* [devtools](https://github.com/hadley/devtools) - making developer's life easy
* [roxygen](https://github.com/klutometis/roxygen) - generate documentation

## Contributing

Please read [CONTRIBUTING.md](https://github.com/tejaslodaya/troop/blob/master/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.


## Authors

* **Tejas Lodaya** - [tejaslodaya.me](https://tejaslodaya.me)

## License

This project is licensed under the MIT License

## See also

* [http://stat.ethz.ch/R-manual/R-devel/library/parallel/doc/parallel.pdf](http://stat.ethz.ch/R-manual/R-devel/library/parallel/doc/parallel.pdf)
* [http://r.adu.org.za/web/packages/foreach/vignettes/foreach.pdf](http://r.adu.org.za/web/packages/foreach/vignettes/foreach.pdf)
* [https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf](https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf)
* [http://michaeljkoontz.weebly.com/uploads/1/9/9/4/19940979/parallel.pdf](http://michaeljkoontz.weebly.com/uploads/1/9/9/4/19940979/parallel.pdf)
* [https://cran.r-project.org/web/packages/iterators/vignettes/writing.pdf](https://cran.r-project.org/web/packages/iterators/vignettes/writing.pdf)
