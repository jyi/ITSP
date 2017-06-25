source("util.R")

InstallUninstalledPackages(c("dplyr", "scales", "plyr", "xtable", "ggplot2"))
library(plyr)
library(dplyr)
library(xtable)
library(ggplot2)
library(scales)

args <- commandArgs(TRUE)

df <- read.csv("../result-base", sep="\t", header=TRUE)

## sanitize
## df <- subset(df, df$pos >= 0 & df$neg >= 0)
## df.exclude <- subset(df, df$inst == 0 & df$neg == 0)
df.exclude <- subset(df, inst == 0 & (neg <= 0 | pos < 0 | is.na(neg) | is.na(pos)))
df <- df[ !(df$prog %in% df.exclude$prog ), ]

df$neg_rate <- df$neg/(df$pos+df$neg)

df.inst.zero <- subset(df, inst == 0)
df.rep.complete <- subset(df, rep_ok == 0 & neg == 0 & inst > 0)
df.rep.partial <- subset(aggregate(rep_ok ~ lab + prob + prog, data=df, FUN=min), rep_ok == 0)

df.min.inst <- merge(aggregate(inst ~ lab + prob + prog, data=subset(df, rep_ok==0), FUN=min), df)
df.min.inst$pos[is.na(df.min.inst$pos)] <- 0
df.min.inst$neg[is.na(df.min.inst$neg)] <- 0

df.max.inst <- merge(aggregate(inst ~ lab + prob + prog, data=subset(df, rep_ok==0), FUN=max), df)
df.max.inst$pos[is.na(df.max.inst$pos)] <- 0
df.max.inst$neg[is.na(df.max.inst$neg)] <- 0

total.complete.repair.rate <- round(nrow(df.rep.complete)/nrow(df.inst.zero)*100, digits=0)
mean.complete.repair.time <- round(mean(df.rep.complete$time), digits=0)

####################################
## df.more.neg and df.more.pos
####################################

df.more.neg <- subset(df, inst == 0 & neg_rate > 0.5)
df.more.pos <- subset(df, inst == 0 & neg_rate <= 0.5)

df.rep.complete.when.more.pos <- subset(df.rep.complete,
                                        df.rep.complete$lab %in% df.more.pos$lab &
                                        df.rep.complete$prob %in% df.more.pos$prob &
                                        df.rep.complete$prog %in% df.more.pos$prog)
df.rep.complete.when.more.neg <- subset(df.rep.complete,
                                        df.rep.complete$lab %in% df.more.neg$lab &
                                        df.rep.complete$prob %in% df.more.neg$prob &
                                        df.rep.complete$prog %in% df.more.neg$prog)

total.complete.repair.rate.pos <-
    round(nrow(df.rep.complete.when.more.pos)
          /
          nrow(subset(df.more.pos, inst == 0))*100,
          digits=0)
total.complete.repair.rate.neg <-
    round(nrow(df.rep.complete.when.more.neg)
          /
          nrow(subset(df.more.neg, inst == 0))*100,
          digits=0)


####################################
## df.small.change and df.big.change
####################################

df$lab <- as.numeric(gsub("Lab-", "", df$lab))

sum.overall <- data.frame()
sum.more.pos <- data.frame()
sum.more.neg <- data.frame()

for (lab.id in sort(unique(df$lab))) {
    df.lab <- subset(df, lab==lab.id)
    df.lab.inst.zero <- subset(df.lab, inst == 0)
    df.lab.rep.complete <- subset(df.lab, rep_ok == 0 & neg == 0 & inst > 0)
    df.lab.rep.partial <- subset(aggregate(rep_ok ~ lab + prob + prog, data=df.lab, FUN=min),
                             rep_ok == 0)

    complete.repair.rate.lab <- round(nrow(df.lab.rep.complete)
                                      /
                                      nrow(df.lab.inst.zero)*100,
                                      digits=0)
    mean.complete.repair.time.lab <- round(mean(df.lab.rep.complete$time), digits=0)

    new.row <- c(lab.id, nrow(df.lab.inst.zero), nrow(df.lab.rep.complete),
                 complete.repair.rate.lab, mean.complete.repair.time.lab)
    sum.overall <- rbind(sum.overall, new.row)

    df.more.neg.lab <- subset(df.lab, inst == 0 & neg_rate > 0.5)
    df.more.pos.lab <- subset(df.lab, inst == 0 & neg_rate <= 0.5)

    df.repair.when.more.pos <- subset(df.lab.rep.complete,
                                      df.lab.rep.complete$lab %in% df.more.pos.lab$lab &
                                      df.lab.rep.complete$prob %in% df.more.pos.lab$prob &
                                      df.lab.rep.complete$prog %in% df.more.pos.lab$prog)
    complete.repair.rate.lab.more.pos <-
        round(nrow(df.repair.when.more.pos)
              /
              nrow(subset(df.more.pos.lab, inst == 0))*100,
              digits=0)
    new.row.more.pos <- c(lab.id, complete.repair.rate.lab.more.pos)
    sum.more.pos <- rbind(sum.more.pos, new.row.more.pos)

    df.repair.when.more.neg <- subset(df.lab.rep.complete,
                                      df.lab.rep.complete$lab %in% df.more.neg.lab$lab &
                                      df.lab.rep.complete$prob %in% df.more.neg.lab$prob &
                                      df.lab.rep.complete$prog %in% df.more.neg.lab$prog)
    complete.repair.rate.lab.more.neg <-
        round(nrow(df.repair.when.more.neg)
              /
              nrow(subset(df.more.neg.lab, inst == 0))*100,
              digits=0)
    new.row.more.neg <- c(lab.id, complete.repair.rate.lab.more.neg)
    sum.more.neg <- rbind(sum.more.neg, new.row.more.neg)
}

colnames(sum.overall) <- c("lab", "prog", "fixed", "rate", "time")
sum.overall$lab <- paste("Lab", sum.overall$lab)

colnames(sum.more.pos) <- c("lab", "rate")
sum.more.pos$Group <- "Low failure rate"

colnames(sum.more.neg) <- c("lab", "rate")
sum.more.neg$Group <- "High failure rate"

## add Total
new.row <- c("Total", nrow(df.inst.zero), nrow(df.rep.complete),
             total.complete.repair.rate, mean.complete.repair.time)
sum.overall <- rbind(sum.overall, new.row)

sum.overall$rate <- paste(sum.overall$rate, "\\%")
sum.overall$time <- paste(sum.overall$time, "s")

## Generate a latex table
GenTex(xtable(sum.overall,
              digits=xdigits(sum.overall),
              caption="The result of our initial experiment in which the existing APR tools are used out of the box. The overall repair rate is 31\\%.",
              label="fig:base-result",),
       include.colnames=FALSE,
       addtorow=list(pos=list(-1, nrow(sum.overall), nrow(sum.overall)-1),
                     command = c(paste("\\toprule \n",
                                       "Lab & \\# Programs & \\# Fixed & Repair Rate & Time \\\\\n",
                                       "\\midrule \n"),
                                 paste("\\midrule \n"),
                                 paste("\\bottomrule \n"))),
       "result-base.tex")

## Generate a plot (compare-pos-neg.pdf)
sum.cmp <- rbind(sum.more.neg, sum.more.pos)

sum.cmp$lab <- paste("Lab", sum.cmp$lab)

new.row <- c("Total", total.complete.repair.rate.neg, "High failure rate")
sum.cmp <- rbind(sum.cmp, new.row)

new.row <- c("Total", total.complete.repair.rate.pos, "Low failure rate")
sum.cmp <- rbind(sum.cmp, new.row)

sum.cmp$rate <- as.numeric(sum.cmp$rate)
pl <- ggplot(data=sum.cmp,
             aes(x=lab, y=rate, fill=Group))
pl <- pl + geom_bar(stat="identity", position=position_dodge())
pl <- pl + scale_x_discrete(limits=c("Lab 3", "Lab 4", "Lab 5", "Lab 6", "Lab 7",
                                     "Lab 8", "Lab 9", "Lab 10", "Lab 11",
                                     "Lab 12", "Total"))
pl <- pl + theme_grey(base_size = 20)
pl <- pl + theme(legend.position="top",
                 axis.title.x=element_blank(),
                 axis.title.y=element_blank())
plot(pl)
ggsave("compare-pos-neg.pdf", plot=pl, scale=.7, device=cairo_pdf, width=14, height=10)

base.df <- sum.overall

#######################################################################
## result-main
#######################################################################

df <- read.csv("../result-inc-repair", sep="\t", header=TRUE)
df <- df[ !(df$prog %in% df.exclude$prog ), ]
df.main <- df
sum.overall <- data.frame()
df$lab <- as.numeric(gsub("Lab-", "", df$lab))
for (lab.id in sort(unique(df$lab))) {
    ## print(paste("[Lab", lab.id, "]"))
    df.lab <- subset(df, lab==lab.id)
    df.lab.inst.zero <- subset(df.lab, inst == 0)
    df.lab.rep.complete <- subset(df.lab, rep_ok == 0 & neg == 0 & inst > 0)
    df.lab.rep.partial <- subset(aggregate(rep_ok ~ lab + prob + prog,
                                           data=df.lab, FUN=min),
                                 rep_ok == 0)

    ## print(df.lab.rep.partial)
    get.time <- function(x, df) {
        subset(df, df$prog == x$prog & df$inst == 0)
    }
    df.lab.rep.partial <- adply(df.lab.rep.partial, 1, get.time, df=df.lab)

    partial.repair.rate.lab <- round(nrow(df.lab.rep.partial)
                                     /
                                     nrow(df.lab.inst.zero)*100,
                                     digits=0)
    mean.partial.repair.time.lab <- round(mean(df.lab.rep.partial$time), digits=0)
    new.row <- c(lab.id, nrow(df.lab.inst.zero), nrow(df.lab.rep.partial),
                 partial.repair.rate.lab, mean.partial.repair.time.lab)
    sum.overall <- rbind(sum.overall, new.row)
}
colnames(sum.overall) <- c("lab", "prog", "fixed", "rate", "time")
main.df <- sum.overall
main.df$lab <- paste("Lab", main.df$lab)
## add Total
df.inst.zero <- subset(df, inst == 0)
df.rep.partial <- subset(aggregate(rep_ok ~ lab + prob + prog, data=df, FUN=min),
                         rep_ok == 0)
get.time <- function(x, df) {
    subset(df, df$prog == x$prog & df$inst == 0)
}
df.rep.partial <- adply(df.rep.partial, 1, get.time, df=df)
total.partial.repair.rate <- round(nrow(df.rep.partial)/nrow(df.inst.zero)*100, digits=0)
mean.partial.repair.time <- round(mean(df.rep.partial$time), digits=0)
new.row <- c("Total",
             nrow(df.inst.zero),
             nrow(df.rep.partial),
             total.partial.repair.rate,
             mean.partial.repair.time)
main.df <- rbind(main.df, new.row)

## Generate a latex table
main.df.bak <- main.df
main.df$rate <- paste(main.df$rate, "\\%")
main.df$time <- paste(main.df$time, "s")
GenTex(xtable(main.df,
              digits=xdigits(main.df),
              caption="The result of an experiment in which partial repairs are sought for in case a complete repair is not found out. The overall repair rate is about 60\\%.",
              label="fig:main-result",),
       include.colnames=FALSE,
       addtorow=list(pos=list(-1, nrow(main.df), nrow(main.df)-1),
                     command = c(paste("\\toprule \n",
                                       "Lab & \\# Programs & \\# Fixed & Repair Rate & Time \\\\\n",
                                       "\\midrule \n"),
                                 paste("\\midrule \n"),
                                 paste("\\bottomrule \n"))),
       "result-main.tex")
main.df <- main.df.bak

## Generate a plot (compare-complete-partial.pdf)
base.df$rate <- as.numeric(gsub("\\\\%", "", base.df$rate))

base.df$Policy <- "Complete"
main.df$Policy <- "Partial+Complete"
sum.cmp <- rbind(base.df, main.df)
sum.cmp$rate <- as.numeric(sum.cmp$rate)

pl <- ggplot(data=sum.cmp,
             aes(x=lab, y=rate, fill=Policy))
pl <- pl + geom_bar(stat="identity", position=position_dodge())
pl <- pl + scale_x_discrete(limits=c("Lab 3", "Lab 4", "Lab 5", "Lab 6", "Lab 7",
                                     "Lab 8", "Lab 9", "Lab 10", "Lab 11",
                                     "Lab 12", "Total"))
pl <- pl + theme_grey(base_size = 20)
pl <- pl + theme(legend.position="top",
                 axis.title.x=element_blank(),
                 axis.title.y=element_blank())
plot(pl)
ggsave("compare-complete-partial.pdf", plot=pl, scale=.7, device=cairo_pdf, width=14, height=10)
