# cp-sca-housing
SQL and processing steps used to create housing inputs to SCA's Housing Pipeline

## Table of Contents
- Introduction
- Data sources
- Limitations and future improvements
- Process diagram

## Introduction


## Data sources
### Primary data sources
- **[DCP Housing Developments Database](https://github.com/NYCPlanning/db-housingdev)** - This database is created by DCP using DOB permit and certificate of occupany data
- **HPD projects** - This data is requested from HPD. It contains information on HPD's New Construction projects and includes all projects completed within past 2 years, in construction, or projected to close financing within next 2 years
- **EDC projects** - This data is requested from EDC. It contains information on EDC's pipeline projects that contain residential developments
- **DCP projects** - This data is generated from DCP's internal project tracking system. Several processing steps are required to identify projects that facilitate residential development (detailed in [1a_dcp_data_prep](https://github.com/mqli322/cp-sca-housing/blob/master/1a_dob_data_prep.sql))
- **Cityled areawide rezonings** - This data is manually compiled as DCP's internal project tracking system does not date as far back as needed. It contains information on areawide rezonings undertaken by NYC that created additional capacity for residential development. Several processing steps are required to create this data (detailed here)

### Prerequisites
- Obtain from HPD their annual submission for SCA's Housing Pipeline
- Obtain from EDC their annual submission of pipeline projects for SCA's Housing Pipeline
- Download project data from DCP's internal project tracking system (ZAP)
- Download project actions from DCP's internal project tracking system (ZAP)
- Download **[NYC Zoning Map Amendments](https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-gis-zoning.page)** from Bytes of the Big Apple - This dataset contains project area polygons for all certified or approved projects seeking a zoning map amendment (ZM action)
- Open DCP's imPACT Visualization polygons in ArcGIS, export as Shapefile - This dataset contains the polygons associated with all DCP projects. Because there are accuracy concerns with this dataset, nyzma was used where possible
- Locate tracker of projected units and build year for areawide rezonings prior to 2012

## Limitations
- **Disclaimer** - The dataset produced contains information on known and possible housing starts based on currently available project information collected from DOB, HPD, EDC, and DCP. This information does NOT represent a housing projection produced by DCP, nor can DCP attest to the certainty that each of these developments will lead to future housing starts
- **Limitations** - 

