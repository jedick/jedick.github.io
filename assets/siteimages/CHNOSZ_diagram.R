# CHNOSZ/demo/NaCl.R
# 20121111 first version
# 22051260 adapted for CHNOSZ page on portfolio

library(CHNOSZ)

png("CHNOSZ_diagram.png", width = 800, height = 600, res = 150)
print(par("mar"))
par(mar = c(3, 3, 1, 1.5))

# Read the data and start a new plot
expt <- read.csv(system.file("extdata/misc/SOJSH.csv", package = "CHNOSZ"), as.is = TRUE)
expt$pch[expt$pch == 0] <- 15
expt$pch[expt$pch == 1] <- 16
expt$pch[expt$pch == 2] <- 17
expt$pch[expt$pch == 5] <- 18
thermo.plot.new(xlim = c(0, 1000), ylim = c(-5.5, 1), xlab = axis.label("T"), ylab = axis.label("logK"))

# Use viridis palette
expt_Ps <- unique(expt$P)
cols <- hcl.colors(length(expt_Ps), palette = "Harmonic")

# The range of temperature for each pressure
T <- list()
T[[1]] <- seq(0, 354, 1)
T[[2]] <- seq(0, 465, 1)
T[[3]] <- seq(0, 760, 1)
T[[4]] <- seq(0, 920, 1)
T[[5]] <- T[[6]] <- T[[7]] <- T[[8]] <- T[[9]] <- seq(0, 1000, 1)

# Define reaction for calculating logK
species <- c("NaCl", "Na+", "Cl-")
coeffs <- c(-1, 1, 1)
logK <- numeric()
# Use numeric P values (except Psat)
Ps <- suppressWarnings(as.numeric(expt_Ps))
P_list <- as.list(Ps)
P_list[is.na(Ps)] <- "Psat"

# Loop over pressures
for(i in 1:length(T)) {
  # Plot calculated logK
  s <- suppressWarnings(subcrt(species, coeffs, T = T[[i]], P = P_list[[i]]))
  lines(s$out$T, s$out$logK, lwd = 2, col = cols[i])
}

# Loop over pressures
for(i in 1:length(expt_Ps)) {
  # Plot experimental logK
  this_expt <- subset(expt, P == expt_Ps[i])
  points(this_expt$T, this_expt$logK, cex = 1.5, pch = this_expt$pch, col = cols[i])
}

## Add title, labels, and legends
title(describe.reaction(s$reaction, states = 1), line = -1, cex.main = 1)
#text(150, -0.1, quote(italic(P)[sat]), cex = 1.2)
text(462, -4, "500 bar")
#text(620, -4.3, "1000 bar")
#text(796, -4.3, "1500 bar")
text(813, -1.3, "4000 bar")

dev.off()
