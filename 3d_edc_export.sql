/**Add boundaries so that units can be aggregated by sub-district**/

ALTER TABLE capitalplanning.edc_2018_sca_input
ADD COLUMN geo_subdist text;

UPDATE capitalplanning.edc_2018_sca_input
SET geo_subdist = b.distzone
FROM dcpadmin.doe_schoolsubdistricts AS b
WHERE ST_Intersects(edc_2018_sca_input.the_geom, b.the_geom)

-- Check
SELECT * FROM capitalplanning.edc_2018_sca_input
WHERE geo_subdist is null

/**Export list of projects to Excel for sharing**/

SELECT
	edc_id, dcp_project_id, project_name, project_description, 
    total_units, build_year, comments_on_phasing, incremental_hpd_u_matched, incremental_edc_units,
    geo_subdist, borough
FROM 
	capitalplanning.edc_2018_sca_input
ORDER BY edc_id ASC
