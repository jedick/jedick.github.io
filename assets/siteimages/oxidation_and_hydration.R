# overview.R by Jeffrey M. Dick
# Schematic overview of trends in nH2O-ZC space 20210727
# Modifications and licenses added for https://chnosz.net/jeff 20221120
# License for image: CC-BY-NC
# License for code: GPL-3

# We need plotrix for draw.ellipse
library(plotrix)

# To get hyphen instead of minus sign 20220630
# https://stackoverflow.com/questions/10438398/any-way-to-disable-the-minus-hack-in-pdf-poscript-output
hyphen.in.pdf <- function(x) {
  # We only want to make the substitution in a pdf device (won't work in png, e.g. for knitr vignettes)
  if(identical(names(dev.cur()), "pdf")) gsub("-", "\uad", x, fixed = TRUE) else x
}

# Arrows in png are too small (cairo), and type = "Xlib" doesn't support transparency 20230301
#png("overview.png", width = 660, height = 500)
# Create pdf in R then convert to png in Gimp
# (72 dpi, don't fill transparent areas with white)
pdf("overview.pdf", width = 660/72, height = 500/72)
par(cex = 1.5)
par(bg = "transparent")

# Start with blank plot
par(mar = c(0, 0, 0, 0))
plot(c(-1.1, 1.1), c(-1, 1), type = "n", axes = FALSE, xlab = NA, ylab = NA)
# Add axis lines
lines(c(0, 0), c(-0.11, 0.11), length = 0.1, angle = 40, code = 3)
lines(c(-0.1, 0.1), c(0, 0), length = 0.1, angle = 40, code = 3)
# Add axis labels
text(0.21, 0, quote(phantom(.) %up% italic(Z)[C]), cex = 1.1)
text(-0.24, 0, quote(phantom(.) %down% italic(Z)[C]), cex = 1.1)
text(0, 0.2, quote(phantom(.) %up% italic(n)[H[2]*O]), cex = 1.1)
text(0, -0.2, quote(phantom(.) %down% italic(n)[H[2]*O]), cex = 1.1)

# Function to draw ellipse or circle with gradient color fill
ellifill <- function(x, y, color, vertical = FALSE, circle = FALSE) {
  # Set colors 20210802
  # https://cdn.elifesciences.org/author-guide/tables-colour.pdf
  elife_tables <- c(blue = "#90CAF9", green = "#C5E1A5", orange = "#FFB74D", yellow = "#FFF176",
                    purple = "#9E86C9", red = "#E57373", pink = "#F48FB1", grey = "#E6E6E6")
  rgb <- col2rgb(elife_tables)
  col <- rgb[, color]
  col <- col / 255
  # Number of ellipses to draw
  n <- 50
  # Fractions from 1/1 to 1/n (to compute radii)
  frac <- (n:1) / n
  # Ramp from transparent white
  #cols <- colorRampPalette(c(rgb(1,1,1,0), rgb(col[1],col[2],col[3],1)), alpha = TRUE, interpolate = "spline")(n)
  # Ramp from transparent only 20221120
  cols <- colorRampPalette(c(rgb(col[1],col[2],col[3],0), rgb(col[1],col[2],col[3],0.3)), alpha = TRUE, interpolate = "spline")(n)
  for(i in 1:n) {
    if(circle) draw.circle(x, y, r = 0.3 * frac[i], border = NA, col = cols[i])
    else {
      if(!vertical) draw.ellipse(x, y, a = 0.7 * frac[i], b = 0.4 * frac[i], border = NA, col = cols[i])
      if(vertical) draw.ellipse(x, y, a = 0.3 * frac[i], b = 0.8 * frac[i], border = NA, col = cols[i])
    }
  }
}

# Draw ellipse for hypersaline systems
ellifill(0.77, 0, "blue", TRUE)
# Draw ellipse for reducing systems
ellifill(-0.77, 0, "red", TRUE)
# Draw ellipse for cancer proteomes
ellifill(0, 0.7, "green")
# Draw ellipse for saline waters
ellifill(0, -0.7, "purple")
# Draw circle for 3D cell culture
ellifill(-0.44, -0.4, "orange", circle = TRUE)

# Add labels
# font = 2 for prokaryotes
# font = 4 for eukaryotes
legend("bottomleft", c("Prokaryote", ""), text.font = 2, bty = "n")
legend("bottomleft", c("", "Eukaryote"), text.font = 4, bty = "n")
text(0, 0.7, "Cancer, embryos,\noldest gene families,\n", font = 4)
text(0, 0.7, "\n\nfreshwater communities", font = 2)
text(0, -0.7, hyphen.in.pdf("Seawater and\nparticle-associated communities,\n"), font = 2)
text(0, -0.7, hyphen.in.pdf("\n\nhigh-glucose media"), font = 4)
#text(-0.77, 0, hyphen.in.pdf("Reducing\nenvironments;\nCOVID-19"), srt = 90, font = 2)
text(-0.77, 0, hyphen.in.pdf("Reducing\nenvironments"), srt = 90, font = 2)
text(0.77, 0, "Hypersaline\nenvironments", srt = 90, font = 2)
text(-0.44, -0.4, "3D vs 2D\ncell culture", font = 4)
legend("topleft", c("Overall trends from", "multiple studies"), bty = "n")

# Add copyright line 20221120
text(1.1, -1, hyphen.in.pdf("© 2023 Jeffrey M. Dick / CC-BY-NC"), cex = 0.7, adj = 1)

dev.off()
