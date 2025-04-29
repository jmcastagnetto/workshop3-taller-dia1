library(tidyverse)

positives_2020 <- read_csv(
  "data/2020-data/2020-positives.csv.gz",
  col_types = cols(
    fecha_corte = col_skip(), # remove column
    departamento = col_character(),
    provincia = col_character(),
    distrito = col_character(),
    metododx = col_character(),
    edad = col_integer(),
    sexo = col_character(),
    fecha_resultado = col_character(),
    ubigeo = col_character(),  # we will remove this later
    id_persona = col_character(),
    missing = col_skip(), # remove column
    week = col_skip() # remove column
  )
) %>% 
  rownames_to_column()

set.seed(13579)

# change some dates to from YYYY-MM-DD to DD-MM-YYYY
tmp <- positives_2020 %>% 
  slice_sample(prop = 0.12) %>% 
  mutate(
    fecha_resultado = ymd(fecha_resultado) %>% 
      format("%d-%m-%Y")
  ) %>% 
  select(rowname, fecha_resultado_new = fecha_resultado)

# replace with the modified dates in the incorrect format
positives_2020 <- positives_2020 %>% 
  left_join(tmp, by = "rowname") %>% 
  mutate(
    fecha_resultado = if_else(
      is.na(fecha_resultado_new), 
      fecha_resultado, 
      fecha_resultado_new
    )
  ) %>% 
  select(-fecha_resultado_new)


# create missing metododx for the Department of AMAZONAS
tmp <- positives_2020 %>% 
  filter(departamento == "AMAZONAS") %>%
  slice_sample(prop = 0.09) %>% 
  mutate(
    metododx = NA
  ) %>% 
  select(rowname, metododx_new = metododx)

positives_2020 <- positives_2020 %>% 
  left_join(tmp, by = "rowname") %>%
  mutate(
    metododx = if_else(
      is.na(metododx_new), 
      metododx, 
      metododx_new
    )
  ) %>%
  select(-metododx_new)

# create missing departamento for 8% of sexo == FEMENINO & edad > 65
tmp <- positives_2020 %>% 
  filter(sexo == "FEMENINO" & edad > 65) %>%
  slice_sample(prop = 0.08) %>% 
  mutate(
    departamento = "**remove**"
  ) %>% 
  select(rowname, departamento_new = departamento)

positives_2020 <- positives_2020 %>%
  left_join(tmp, by = "rowname") %>% 
  mutate(
    departamento = if_else(
      is.na(departamento_new), 
      departamento, 
      NA
    )
  ) %>% 
  select(-departamento_new)

# replace departamento, provincia, distrito using ubigeo
positives_2020 <- positives_2020 %>% 
  mutate(
    departamento = if_else(
      is.na(departamento),
      NA,
      str_sub(ubigeo, 1, 2)
    ),
    provincia = str_sub(ubigeo, 3, 4),
    distrito = str_sub(ubigeo, 5, 6)
  ) %>% 
  select(-ubigeo, -rowname)

write_csv(
  positives_2020,
  "data/positivos.csv.gz",
  quote = "all"
)
