# calc_ppm_Li.R
# Calculate ppm of Li in equilibrium with muscovite and Li-mica
# 20230428 jmd first version: add Li-mica from Boschetti (2023)
# 20231201 Predicted Li concentration is too high: use G and S from Gordiyenko and Ponomareva (1989)
# 20231204 Use wt% NaCl equiv.

# Tested with CHNOSZ version 2.1.0
library(CHNOSZ)

# Setup basis species to balance reactions
basis(c("Al+3", "quartz", "Li+", "K+", "H+", "H2O", "oxygen"))
# Create a pH buffer (effectively KMQ because quartz is in the basis species)
mod.buffer("KM", c("K-feldspar", "muscovite"), "cr", 0)

# Define temperature and pressure
T <- seq(100, 700, 50)
P <- 2000
# Define wt% NaCl equivalent
wt_percent_NaCl <- c(10, 1, 0.1)
# Define pH values for Plot 1
pH <- c(4, 5, 6)

# Convert wt% NaCl to molality
wt2m <- function(wt_percent_NaCl) {
  wt_permil_NaCl <- wt_percent_NaCl * 10
  molar_mass_NaCl <- mass("NaCl") # 58.44277
  moles_NaCl <- wt_permil_NaCl / molar_mass_NaCl
  grams_H2O <- 1000 - wt_permil_NaCl
  kg_H2O <- grams_H2O / 1000
  molality_NaCl <- moles_NaCl / kg_H2O
  # Compute molality of Cl- and IS in NaCl solution
  nacl <- NaCl(molality_NaCl, T = T, P = P)
  # Return molality of Cl- (==IS when no HCl is formed, e.g. pH = NA in preceding function call)
  nacl$m_Cl
}

# Setup plots
#pdf("muscovite.pdf", width = 12, height = 5)
par(mfrow = c(1, 3))

# Plot 1: log (aLi+ * aK+)
# Adjust y-axis limit based on thermodynamic data source
ylim <- c(-2, 5)
if(identical(info(info("Li-mica"))$ref2, "GP89")) ylim <- c(-6, 1)
plot(range(T), ylim, xlab = axis.label("T"), ylab = "log (mLi+ * mK+)", type = "n")
# This plot is for 1 wt% NaCl equiv.
m_Cl <- wt2m(1)
IS <- m_Cl
for(i in seq_along(pH)) {

  sres <- subcrt(c("muscovite", "Li-mica"), c(-1, 2), T = T, P = P, IS = IS)
  logK <- sres$out$logK
  logmLimK <- - (logK + 2 * pH[i])
  lines(T, logmLimK, lty = i)

}
legend("topleft", c("Quartz saturation", "1 wt% NaCl equiv."), bty = "n")
legend("bottomright", legend = pH, lty = 1:3, title = "pH", bty = "n")
title(describe.reaction(sres$reaction), cex.main = 1, xpd = NA)

# Plot 2: KMQ pH buffer
plot(range(T), c(4, 8), xlab = axis.label("T"), ylab = "pH", type = "n")
for(i in seq_along(wt_percent_NaCl)) {

  m_Cl <- wt2m(wt_percent_NaCl[i])
  IS <- m_Cl
  # Calculate equilibrium constant for Ab-Kfs reaction, corrected for ionic strength
  sres_AK <- subcrt(c("albite", "K+", "K-feldspar", "Na+"), c(-1, -1, 1, 1), T = T, P = P, IS = IS)
  logK_AK <- sres_AK$out$logK
  K_AK <- 10 ^ logK_AK
  # Calculate molality of K+
  m_K <- m_Cl / (K_AK + 1)

  # Calculate pH from KMQ buffer
  basis("H+", "KM")
  bufval <- affinity(`K+` = log10(m_K), T = T, P = P, IS = IS, return.buffer = TRUE)
  lines(T, -bufval$`H+`, lty = i)

  # Calculate ppm Li with KMQ pH buffer and AK Na+/K+ buffer
  logK <- subcrt(c("muscovite", "Li-mica"), c(-1, 2), T = T, P = P, IS = IS)$out$logK
  pH <- - bufval$`H+`
  logmLimK <- - (logK + 2 * pH)
  logmLi <- logmLimK - log10(m_K)
  # Molar mass of Li
  grams.per.mole <- 6.941
  ## To convert moles to mass (g)
  #grams <- moles * grams.per.mole
  ## To convert grams to ppm
  ## 1 ppm = 1 mg / kg H2O
  #ppm <- grams * 1e3
  ppm_Li <- 10^logmLi * grams.per.mole * 1e3
  if(i==1) ppm_Li_10 <- ppm_Li
  if(i==2) ppm_Li_1 <- ppm_Li
  if(i==3) ppm_Li_0.1 <- ppm_Li

}
legend("bottomright", legend = rev(wt_percent_NaCl), lty = 3:1, title = "wt% NaCl equiv.", bty = "n")
title("Ab-Kfs Na/K buffer and KMQ pH buffer", font.main = 1)
#title(describe.reaction(sres_KMQ$reaction))

# Plot 3: ppm Li at different chlorinity
par(las = 1)
par(mar = c(5.1, 6, 4.1, 2.1))
# Adjust y-axis limit based on calculated ppm Li
ylim <- c(0.1, 10000)
if(min(ppm_Li_1) > 10000) ylim <- c(10000, 2500000)
plot(range(T), ylim, xlab = axis.label("T"), ylab = "ppm Li", log = "y", yaxt = "n", type = "n")
# Make y-axis labels not in scientific notation
at <- c("0.1", "1", "10", "100", "1000", "10000", "100000", "1000000")
for(i in 1:length(at)) axis(2, as.numeric(at[i]), at[i])
n <- length(T)
lines(T, ppm_Li_0.1, lty = 3)
text(T[n], ppm_Li_0.1[n] * 0.4, "0.1 wt% NaCl", adj = 1)
lines(T, ppm_Li_1, lty = 2)
text(T[n], ppm_Li_1[n] * 0.4, "1 wt% NaCl", adj = 1)
lines(T, ppm_Li_10, lty = 1)
text(T[n], ppm_Li_10[n] * 0.4, "10 wt% NaCl", adj = 1)

#dev.off()
