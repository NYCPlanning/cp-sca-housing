/**Add boundaries so that units can be aggregated by sub-district**/

ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN geo_subdist text;

UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET geo_subdist = b.distzone
FROM dcpadmin.doe_schoolsubdistricts AS b
WHERE ST_Intersects(hpd_2018_sca_inputs_geo_pts_copy.the_geom, b.the_geom)

-- Check
SELECT * FROM capitalplanning.hpd_2018_sca_inputs_geo_pts
WHERE geo_subdist is null

/**Export list of projects to Excel for sharing**/

SELECT
	project_id, building_id, project_name, primary_program_at_start, construction_type, 
  status, cast(project_start_date as date), cast(building_completion_date as date), cast(projected_start_date as date), cast(projected_completion_date as date), total_units,
  match_method, dob_job_number, dob_u_matched, incremental_hpd_units,
  geo_subdist,
  ST_X(the_geom) AS latitude, ST_Y(the_geom) AS longitude, bbl AS hpd_bbl, CONCAT(house_number,' ',street_name) AS address, borough
FROM 
    capitalplanning.hpd_2018_sca_inputs_geo_pts_copy
ORDER BY status, project_id, building_id
