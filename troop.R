library(doParallel)

source('iterators.R')

troop <- function(data,
	by,
	apply_func,
	preprocess_func = function(){},
	postprocess_func = function(){},
	num_chunks = detectCores(logical = TRUE),
	preprocess_args = list(),
	postprocess_args = list(),
	packages = c(),
	export = c(),
	combine = 'c',
	files_to_source = c()){

	# TODO : make log_file an input
	log_file <- 'cluster.log'
	file.create(log_file)
	Sys.setenv(OMP_THREAD_LIMIT = 1)

	do.call(preprocess_func, preprocess_args)

	# initialize cluster
	cl <- makeCluster(num_chunks, outfile = log_file)
	registerDoParallel(cl)

	packages <- c(packages,'foreach','data.table')
	
	# core logic goes here
	if(missing(by)){
		itr <- iblkrow(data = data, chunks = num_chunks)
	} else{
		itr <- iblkgrouprow(data = data, by = by, chunks = num_chunks)
	}

	resR <- foreach(x = itr, .packages = packages, .export = export, .combine = combine) %dopar%
	{
		# source file on each core
		sapply(files_to_source, source)
		if(missing(by)){
			apply_func(x)
		} else{
			
			combinations <- data.table:::unique.data.table(x, by=by)[,..by]
			setkeyv(x, by)
		 	res <- foreach(i = 1:nrow(combinations)) %do% {
		 
		 		itr_comb <- combinations[i,]
		 		itr_data <- x[(itr_comb), nomatch = 0]
        
		 		apply_func(itr_data)
		 	}
		 	return (res)
		}
		
	}


	do.call(postprocess_func, postprocess_args)
	on.exit(stopCluster(cl))
	return(resR)
}