# G and S are from Gordiyenko and Ponomareva (1989)
# Cp coefficients are from Boschetti (2023)
mod.OBIGT("Li-mica", formula = "KLi0.5Al1.5Si4O10(OH)2",
  ref1 = "GP89", ref2 = "Bos23", E_units = "cal", state = "cr",
  G = -1302260, S = 78.03,
  V = 144.32, Cp = 77.29,
  a = 94.486, b = 0.030360, c = -2165900,
  d = 0, e = 0, f = 0, lambda = 0, T = 2000
)

source("calc_ppm_Li.R")
