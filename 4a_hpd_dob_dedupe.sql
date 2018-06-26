--- Get list of projects (deduped)
ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN dob_job_number numeric,
ADD COLUMN dob_u_matched numeric

--- Create new dataset from deduping (too large to update as query)
SELECT 
	h.project_id, building_id, project_name, primary_program_at_start, construction_type, status, project_start_date, building_completion_date, projected_start_date, projected_completion_date, total_units,
    ST_X(h.the_geom) AS latitude, ST_Y(h.the_geom) AS longitude, h.bbl AS hpd_bbl, CONCAT(h.house_number,' ',h.street_name) AS address, h.borough, h.geo_csd, h.geo_subdist, h.geo_subdistname, h.geo_pszone201718, h.geo_pszone_remarks, h.geo_mszone201718, h.geo_mszone_remarks, h.geo_communitydistrict, h.geo_councildistrict, h.geo_councilname, h.geo_censusblock, h.geo_nta, h.geo_ntaname,
    j.dob_job_number, u_net AS dob_u_matched
FROM 
    capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
LEFT JOIN 
	capitalplanning.dobdev_jobs_20180316 AS j
ON ST_DWithin(j.the_geom::geography, h.the_geom::geography, 3)
WHERE j.dob_type <> 'DM'
AND j.dcp_status <> 'Withdrawn'
AND j.dcp_status <> 'Disapproved'
AND j.dcp_status <> 'Suspended'
AND (j.dcp_occ_init = 'Residential' OR j.dcp_occ_prop = 'Residential')
AND j.x_dup_flag <> 'Possible Duplicate'
AND j.x_outlier <> 'true'
AND (EXTRACT(YEAR FROM status_q) - EXTRACT(YEAR FROM x_start_date) BETWEEN -3 AND 3
OR EXTRACT(YEAR FROM status_a) - EXTRACT(YEAR FROM x_start_date) BETWEEN -3 AND 3)

--- Bring back matches into primary hpd dataset
UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET dob_job_number = d.dob_job_number, dob_u_matched = d.dob_u_matched
FROM capitalplanning.hpd_dob_deduped AS d
WHERE hpd_2018_sca_inputs_geo_pts.project_id = d.project_id AND hpd_2018_sca_inputs_geo_pts.building_id = d.building_id 

--- Double check for high match rate for completed and in construction
SELECT status, count(*) FROM capitalplanning.hpd_2018_sca_inputs_geo_pts
WHERE dob_job_number is null
GROUP BY status

--- Calculate incremental units
ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN incremental_hpd_units numeric;

UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET incremental_hpd_units =
(CASE WHEN dob_u_matched is null THEN total_units
 WHEN total_units - dob_u_matched < 0 THEN 0
 ELSE total_units - dob_u_matched END)

--- Export list of projects to Excel for sharing
SELECT
	project_id, building_id, project_name, primary_program_at_start, construction_type, 
    status, project_start_date, building_completion_date, projected_start_date, projected_completion_date, total_units,
    ST_X(the_geom) AS latitude, ST_Y(the_geom) AS longitude, bbl AS hpd_bbl, CONCAT(house_number,' ',street_name) AS address, borough,
    geo_csd, geo_subdist, geo_subdistname, geo_pszone201718, geo_pszone_remarks, geo_mszone201718, geo_mszone_remarks, geo_communitydistrict, geo_councildistrict, geo_councilname,geo_censusblock, geo_nta, geo_ntaname,
    dob_job_number, dob_u_matched, incremental_hpd_units
FROM 
    capitalplanning.hpd_2018_sca_inputs_geo_pts
ORDER BY project_id, building_id
