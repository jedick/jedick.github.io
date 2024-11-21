# Add Li-mica from Boschetti (2023)
# 20230428 jmd
mod.OBIGT("Li-mica", formula = "KLi0.5Al1.5Si4O10(OH)2",
  ref1 = "Bos23", E_units = "cal", state = "cr",
  G = -1296883.37, H = -1384933.08, S = 77.182,
  V = 144.32, Cp = 77.29,
  a = 94.486, b = 0.030360, c = -2165900,
  d = 0, e = 0, f = 0, lambda = 0, T = 2000
)

source("calc_ppm_Li.R")
