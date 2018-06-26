/**Organization data shared**/
-- EDC inputs came in 3 files: Excel with project info, Shapefile for site-specific projects, Shapefile for areawide rezonings
-- Uploaded to CARTO as edc_temp
-- Created empty dataset

ALTER TABLE capitalplanning.edc_2018_sca_input
ADD COLUMN borough text,
ADD COLUMN total_units numeric,
ADD COLUMN senior_units numeric,
ADD COLUMN build_year numeric,
ADD COLUMN project_description text,
ADD COLUMN comments_on_phasing text,
ADD COLUMN dcp_project_id text,
ADD COLUMN geom_source text;

UPDATE capitalplanning.edc_2018_sca_input
SET borough = t.borough, total_units = t.dus, senior_units = t.senior_units, build_year = t.anticipated_year_built, 
project_description = t.project_description, comments_on_phasing = t.comments_on_phasing, dcp_project_id = t.dcp_project_id
FROM capitalplanning.edc_temp AS t
WHERE edc_2018_sca_input.edc_id = t.edc_id

/**Geocode**/

UPDATE capitalplanning.edc_2018_sca_input
SET geom_source = 'edc'
WHERE edc_id <> 1 AND edc_id <> 5

UPDATE capitalplanning.edc_2018_sca_input
SET the_geom = d.the_geom
FROM capitalplanning.all_possible_projects AS d
WHERE edc_id = 1 AND d.project_id = 'P2016K0272';

UPDATE capitalplanning.edc_2018_sca_input
SET geom_source = 'nyzma'
WHERE edc_id = 1;

UPDATE capitalplanning.edc_2018_sca_input
SET the_geom = d.the_geom
FROM capitalplanning.all_possible_projects AS d
WHERE edc_id = 5 AND d.project_id = 'P2017X0037';

UPDATE capitalplanning.edc_2018_sca_input
SET geom_source = 'imPACT Visualization'
WHERE edc_id = 5
