# Data

## admin1_all_variables.csv

Subnational (admin-1) data for 3,591 administrative divisions. 40 columns: 5 identifiers, 1 population column, and 34 variables (17 extensive, 17 non-extensive).

### Identifiers

| Column | Description |
|-|-|
| `country_code` | ISO 3166-1 alpha-3 |
| `country_name` | Country name |
| `adm_div_name` | Administrative division name |
| `adm_div_code` | World Bank admin-1 code |
| `area` | Area in km² (equal-area projection) |
| `pop_gpw` | GPW v4.11 population 2020 (927 m native resolution) |

### Variables

#### Extensive (17)

| Column | Unit | Source |
|-|-|-|
| `builtup_km2_2020` | km² | JRC GHSL Built-Up Surface 2020 (3 arc-sec) |
| `builtup_volume_2020` | m³ | JRC GHSL Built-Up Volume 2020 (3 arc-sec) |
| `burned_area_pixels_2020` | Pixel count | MODIS MCD64A1 2020 (native 463 m) |
| `co2_emissions_2020` | kg/m²/s (summed) | EDGAR v8.0 2024 GHG |
| `cropland_area_km2` | km² | Derived: cropland_fraction × area |
| `et_total_mm_km2_2020` | mm·km² | Derived: et_mean_mm_2020 × area |
| `forest_area_km2` | km² | Derived: forest_fraction × area |
| `forest_loss_pixels` | Pixel count | Hansen forest loss 2001–2023 |
| `gdp_total_2020` | PPP USD | Derived: gdp_per_capita × pop_gpw |
| `nightlights_sum_2020` | nW/cm²/sr (summed) | VIIRS DNB Monthly Composites (native 463 m) |
| `pm25_total_2019` | µg/m³·km² | Derived: pm25_annual_2019 × area |
| `pop_ghsl` | People | JRC GHSL-POP 2020 (100 m) |
| `pop_wp` | People | WorldPop 2020 (92.77 m) |
| `precip_total_mm_km2` | mm·km² | Derived: precip_annual_mm × area |
| `tree_cover_km2_2000` | km² | Derived: tree_cover_pct_2000 / 100 × area |
| `urban_area_km2` | km² | Derived: urban_fraction × area |
| `water_area_km2` | km² | Derived: water_occurrence_pct / 100 × area |

#### Non-Extensive (17)

| Column | Unit | Source |
|-|-|-|
| `builtup_fraction` | 0–1 | Derived: builtup_km2_2020 / area |
| `cloud_fraction_mean` | 0–10000 | MODIS MOD08_M3 (2015–2020 mean) |
| `elevation_mean_m` | Metres | SRTM GL1 |
| `et_mean_mm_2020` | mm | MODIS MOD16A2GF 2020 |
| `forest_fraction` | 0–1 | MODIS MCD12Q1 2020 (IGBP classes 1–5) |
| `cropland_fraction` | 0–1 | MODIS MCD12Q1 2020 (IGBP classes 12, 14) |
| `gdp_per_capita_2020` | PPP USD | Gridded GDP (Kummu et al.) |
| `ndvi_mean_2020` | NDVI × 10000 | MODIS MOD13A2 2020 |
| `nightlights_per_km2` | nW/cm²/sr per km² | Derived: nightlights_sum_2020 / area |
| `pm25_annual_2019` | µg/m³ | Global Satellite PM2.5 (van Donkelaar et al.) |
| `precip_annual_mm` | mm | WorldClim v1 BIO12 |
| `ruggedness_mean` | Metres (std dev) | Terrain ruggedness from SRTM |
| `soil_organic_carbon_g_per_kg` | g/kg | OpenLandMap SOC (0 cm depth) |
| `temp_annual_mean_C` | °C | WorldClim v1 BIO1 |
| `travel_time_to_city_min` | Minutes | Oxford MAP Accessibility to Cities 2015 |
| `tree_cover_pct_2000` | % | Hansen Global Forest Change |
| `urban_fraction` | 0–1 | MODIS MCD12Q1 2020 (IGBP class 13) |
| `water_occurrence_pct` | % | JRC Global Surface Water |

### Aggregation

Extensive variables use **sum** reducers (total across pixels) at native raster resolution where possible. Non-extensive variables use **mean** reducers (spatial average across pixels). Population, nightlights, burned area, built-up surface, and built-up volume are computed at native resolution. Other extensive variables are derived from multiplying intensive (i.e., non-extensive and independent of system size) × area.

### Sources

- **Population**: [GPW v4.11](https://sedac.ciesin.columbia.edu/data/collection/gpw-v4) (CIESIN/NASA), [GHSL-POP](https://ghsl.jrc.ec.europa.eu/) (JRC), [WorldPop](https://www.worldpop.org/)
- **Boundaries**: [World Bank Official Boundaries – Admin 1](https://datacatalog.worldbank.org/)
- **Built-up**: [JRC GHSL](https://ghsl.jrc.ec.europa.eu/) (direct download, 3 arc-second)
- **Nightlights**: [VIIRS DNB](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMSLCFG) (GEE)
- **Forest**: [Hansen Global Forest Change](https://storage.googleapis.com/earthenginepartners-hansen/GFC-2023-v1.11/download.html)
- **Climate**: [WorldClim v1](https://www.worldclim.org/)
- **GDP**: [Gridded GDP](https://doi.org/10.1038/sdata.2018.4) (Kummu et al.)
- **Emissions**: [EDGAR v8.0](https://edgar.jrc.ec.europa.eu/dataset_ghg2024) (JRC)
- **PM2.5**: [Global Satellite PM2.5](https://sites.wustl.edu/acag/datasets/surface-pm2-5/) (van Donkelaar et al.)
- **Land cover**: [MODIS MCD12Q1](https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MCD12Q1) (GEE)

## world_bank_boundaries_simplified.geojson

Admin-1 boundary polygons. The coordinates are derived from the [World Bank](https://datacatalogfiles.worldbank.org/ddh-published/0038272/5/DR0095369/World Bank Official Boundaries (GeoJSON)/World Bank Official Boundaries - Admin 1.geojson) (accessed on 2026-03-09) through polyline simplification. Used for spatial joins and map visualisation. Each feature has an `ADM1CD_c` field that matches `adm_div_code` in the CSV.
