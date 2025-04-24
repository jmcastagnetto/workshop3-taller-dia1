library(tidyverse)

# deaths

deaths_2020 <- read_csv(
  "data/2020-data/2020-deaths.csv.gz",
  col_types = cols(
    fecha_corte = col_skip(), # remove column
    fecha_fallecimiento = col_character(),
    edad_declarada = col_integer(),
    sexo = col_character(),
    clasificacion_def = col_character(),
    departamento = col_character(),
    provincia = col_character(),
    distrito = col_character(),
    ubigeo = col_skip(), # remove column
    uuid = col_character(),
    age_group = col_character(),
    missing = col_skip(), # remove column
    week = col_skip() # remove column
  )
) %>% 
  rownames_to_column()

set.seed(13579)

# change some dates to from YYYY-MM-DD to DD-MM-YYYY
tmp <- deaths_2020 %>% 
  slice_sample(prop = 0.1) %>% 
  mutate(
    fecha_fallecimiento = ymd(fecha_fallecimiento) %>% 
      format("%d-%m-%Y")
  ) %>% 
  select(rowname, fecha_fallecimiento_new = fecha_fallecimiento)

# replace with the modified dates in the incorrect format
deaths_2020 <- deaths_2020 %>% 
  left_join(tmp, by = "rowname") %>% 
  mutate(
    fecha_fallecimiento = if_else(
      is.na(fecha_fallecimiento_new), 
      fecha_fallecimiento, 
      fecha_fallecimiento_new
    )
  ) %>% 
  select(-fecha_fallecimiento_new)

# create missing in uuid

tmp <- deaths_2020 %>% 
  slice_sample(prop = 0.05) %>% 
  mutate(
    uuid = NA
  ) %>% 
  select(rowname, uuid_new = uuid)

deaths_2020 <- deaths_2020 %>% 
  left_join(tmp, by = "rowname") %>% 
  mutate(
    uuid = if_else(
      is.na(uuid_new), 
      uuid, 
      uuid_new
    )
  ) %>% 
  select(-uuid_new)

# create inconsistent age_group
tmp <- deaths_2020 %>% 
  filter(edad_declarada >= 55 & edad_declarada <= 74) %>%
  slice_sample(prop = 0.06) %>% 
  mutate(
    age_group = "75+"
  ) %>% 
  select(rowname, age_group_new = age_group)

deaths_2020 <- deaths_2020 %>%
  left_join(tmp, by = "rowname") %>% 
  mutate(
    age_group = if_else(
      is.na(age_group_new), 
      age_group, 
      age_group_new
    )
  ) %>% 
  select(-age_group_new)

write_csv(
  deaths_2020 %>% 
    select(-rowname),
  "data/fallecidos.csv.gz",
  quote = "all"
)
