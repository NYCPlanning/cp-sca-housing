# cp-sca-housing
SQL and processing steps used to create housing inputs to SCA's Housing Pipeline

## Table of Contents
- Introduction
- Data sources
- Limitations and future improvements
- Process diagram

## Introduction


## Data sources
- [DCP Housing Developments Database](https://github.com/NYCPlanning/db-housingdev) - This database is created by DCP using DOB permit and certificate of occupany data
- HPD projects - This data is requested from HPD. It contains information on HPD's New Construction projects and includes all projects completed within past 2 years, in construction, or projected to close financing within next 2 years
- EDC projects - This data is requested from EDC. It contains information on EDC's pipeline projects that contain residential developments
- DCP projects - This data is generated from DCP's internal project tracking system. Several processing steps are required to identify projects that facilitate residential development (detailed here)
- Cityled areawide rezonings - This data is manually compiled as DCP's internal project tracking system does not date as far back as needed. It contains information on areawide rezonings undertaken by NYC that created additional capacity for residential development. Several processing steps are required to create this data (detailed here)
