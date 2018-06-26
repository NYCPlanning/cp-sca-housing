/**Add geocode to file from HPD**/
-- Import to CARTO as hpd_2018_sca_inputs
-- Geocode using HPD address via GBAT (done by Bill)
-- Add geocoding from Bill (uploaded to CARTO as hpd_sca_bill_gbat)

UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET the_geom = b.the_geom
FROM capitalplanning.hpd_sca_bill_gbat AS b
WHERE b.project_id = hpd_2018_sca_inputs_geo_pts.project_id AND b.building_id = hpd_2018_sca_inputs_geo_pts.building_id

/**Create columns for analysis**/
ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN x_start_date date;
ADD COLUMN x_completion_date date;

UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET x_start_date = 
(CASE WHEN project_start_date is not null THEN project_start_date
 ELSE projected_start_date END); 
 
UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET x_completion_date = 
(CASE WHEN building_completion_date is not null THEN building_completion_date
 ELSE projected_completion_date END)
 
 -- Save as hpd_2018_sca_inputs_geo_pts
