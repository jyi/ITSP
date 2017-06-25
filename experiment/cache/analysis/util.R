InstalledPackage <- function(package)
{
    available <- suppressMessages(suppressWarnings(sapply(package, require, quietly = TRUE, character.only = TRUE, warn.conflicts = FALSE)))
    missing <- package[!available]
    if (length(missing) > 0) return(FALSE)
    return(TRUE)
}

CRANChoosen <- function()
{
    return(getOption("repos")["CRAN"] != "@CRAN@")
}

UsePackage <- function(package, defaultCRANmirror = "http://cran.at.r-project.org")
{
    if(!InstalledPackage(package))
    {
        if(!CRANChoosen())
        {
            # chooseCRANmirror()
            if(!CRANChoosen())
            {
                options(repos = c(CRAN = defaultCRANmirror))
            }
        }

        suppressMessages(suppressWarnings(install.packages(package)))
        if(!InstalledPackage(package)) return(FALSE)
    }
    return(TRUE)
}

InstallUninstalledPackages <- function(libraries) {
    for(library in libraries) {
        if(!UsePackage(library)) {
            stop("Error!", library)
        }
    }
}

MergeComp <- function(df) {
    df$defects <- as.character(df$defects)
    # COMP
    df$defects <- unlist(
        lapply(df$defects,
               FUN = function(x) {
                   if (length(grep(",", x)) > 0)
                       gsub(".*", "COMP", x) else x
               }))

    comp <- subset(df, defects == "COMP")
    non.comp <- subset(df, defects != "COMP")
    df <- non.comp
    df <- rbind(df, c("COMP", sum(comp$repaired), sum(comp$correct), sum(comp$total)))
    return(df)
}

GetDF <- function(file, col.names) {
    df <- read.csv(file, sep="@", header=FALSE)
    names(df) <- col.names

    if ("defects" %in% colnames(df)) {
        df$defects <- as.character(df$defects)

        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("\\[", "", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("\\]", "", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("'", "", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("CONSTANT FOR CONSTANT REPLACEMENT: CCCR", "CCCR", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("SCALAR VARIABLE REFERENCE REPLACEMENT: VSRR", "VSRR", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("RELATIONAL: ORRN", "ORRN", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("INSERT &&", "INSERT \\\\&\\\\&", x)))
        df$defects <- unlist(lapply(df$defects, FUN = function(x) gsub("OFF BY ONE:.*", "OFF BY ONE", x)))
    }

    df <- as.data.frame(lapply(df, function(x) unlist(x)))

    return(df)
}

GenTex <- function(xdf, out.file, addtorow=c(), include.colnames=TRUE) {
    print(xdf, type="latex", include.rownames=FALSE,
          floating.environment = getOption("xtable.floating.environment", "table"),
          table.placement = getOption("xtable.table.placement", "t!"),
          booktabs = getOption("xtable.booktabs", TRUE),
          add.to.row = addtorow,
          include.colnames=include.colnames,
          hline.after=NULL, #c(0, nrow(xdf)),
          caption.placement = "top",
          sanitize.text.function = function(x) {gsub("_", "\\\\_", x)}, # identity,
          file=out.file,
          size="\\normalsize")
}

GetType <- function(df) {
    return(sapply(df$defects, function(x) {
        if (grepl("ORRN", x) || grepl("CCCR", x) || grepl("OLLN", x)
            || grepl("OAAN", x) || grepl("INSERT \\|\\|", x)
            || grepl("INSERT \\\\&\\\\&", x)
            || grepl("OIDO", x)
            || grepl("INSERT ARITHMETIC", x)
            || grepl("OFF BY ONE", x)
            || grepl("VSRR", x)) "Exp"
        else "Stmt"}
        ))
}
