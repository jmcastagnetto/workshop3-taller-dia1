library(tidyverse)

hospital_2020 <- read_csv(
  "data/2020-data/2020-hospital.csv.gz",
  col_types = cols(
    eess_renaes = col_skip(), # remove column
    eess_diresa = col_skip(), # remove column
    eess_red = col_skip(), # remove column
    eess_nombre = col_character(),
    id_eess = col_skip(), # remove column
    id_persona = col_character(),
    edad = col_integer(),
    sexo = col_character(),
    fecha_ingreso_hosp = col_character(),
    flag_uci = col_skip(), # remove column
    fecha_ingreso_uci = col_character(),
    fecha_ingreso_ucin = col_character(),
    con_oxigeno = col_logical(),
    con_ventilacion = col_logical(),
    fecha_segumiento_hosp_ultimo = col_character(),
    evolucion_hosp_ultimo = col_character(),
    flag_vacuna = col_integer(),
    fecha_dosis1 = col_character(),
    fabricante_dosis1 = col_character(),
    fecha_dosis2 = col_character(),
    fabricante_dosis2 = col_character(),
    fecha_dosis3 = col_character(),
    fabricante_dosis3 = col_character(),
    cdc_positividad = col_logical(),
    cdc_fecha_fallecido_covid = col_character(),
    cdc_fallecido_covid = col_logical(),
    ubigeo_inei_domicilio = col_character(), # we will remove this later
    dep_domicilio = col_character(),
    prov_domicilio = col_character(),
    dist_domicilio = col_character(),
    missing = col_skip() # remove column
  )
) %>% 
  rownames_to_column()

set.seed(13579)

# change the date format for `fecha_dosis1` y `fecha_dosis_3` 
# from  YYYY-MM-DD to DD-MM-YYYY
hospital_2020 <- hospital_2020 %>% 
  mutate(
    fecha_dosis1 = ymd(fecha_dosis1) %>% 
      format("%d-%m-%Y"),
    fecha_dosis3 = ymd(fecha_dosis3) %>% 
      format("%d-%m-%Y")
  )

# remove 10% of names from `eess_nombre`
tmp <- hospital_2020 %>% 
  slice_sample(prop = 0.12) %>% 
  mutate(
    eess_nombre = "**remove**"
  ) %>% 
  select(rowname, eess_nombre_new = eess_nombre)

hospital_2020 <- hospital_2020 %>%
  left_join(tmp, by = "rowname") %>% 
  mutate(
    eess_nombre = if_else(
      is.na(eess_nombre_new), 
      eess_nombre, 
      NA
    )
  ) %>% 
  select(-eess_nombre_new)

# remove 2% of `prov_domicilio` for `dep_domicilio == "LIMA"` 
# and `dist_domicilio == "SAN JUAN DE LURIGANCHO"`
tmp <- hospital_2020 %>% 
  filter(dep_domicilio == "LIMA" & 
           dist_domicilio == "SAN JUAN DE LURIGANCHO") %>%
  slice_sample(prop = 0.02) %>% 
  mutate(
    prov_domicilio = "**remove**"
  ) %>% 
  select(rowname, prov_domicilio_new = prov_domicilio)

hospital_2020 <- hospital_2020 %>%
  left_join(tmp, by = "rowname") %>%
  mutate(
    prov_domicilio = if_else(
      is.na(prov_domicilio_new), 
      prov_domicilio,
      NA
    )
  ) %>%
  select(-prov_domicilio_new)

# replace dep_domicilio, prov_domicilio, dist_domicilio 
# using ubigeo_inei_domicilio
hospital_2020 <- hospital_2020 %>% 
  mutate(
    dep_domicilio = str_sub(ubigeo_inei_domicilio, 1, 2),
    prov_domicilio = if_else(
      is.na(prov_domicilio),
      NA,
      str_sub(ubigeo_inei_domicilio, 3, 4)
    ),
    dist_domicilio = str_sub(ubigeo_inei_domicilio, 5, 6)
  ) %>% 
  select(-ubigeo_inei_domicilio, -rowname)

write_csv(
  hospital_2020,
  "data/hospitalizados.csv.gz",
  quote = "all"
)
