# Troop

Group-by and apply function to `data.table` using parallel processing achieved by `doParallel` package.

SOCK clusters are created and a chunk of data runs on each cluster.

## Getting Started

Logic behind this package is explained in the image below

![](https://raw.githubusercontent.com/tejaslodaya/troop/master/troop.png)


### Prerequisites

R (>= 3.3.2)

### Installing

troop can directly be installed from github

```
install.packages("devtools")
devtools::install_github("tejaslodaya/troop")
```

Thats it! Now you can use the library from your machine.

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
