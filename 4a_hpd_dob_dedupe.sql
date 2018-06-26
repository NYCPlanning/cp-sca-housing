/**Develop deduping methodology and check match rate of various options**/
-- First method - match by exact address (selected this as first option bc not subject to quality of geocoding)
-- Results/quality of method
	-- 27.2K of 49.2K units from Completed or In Construction projects were matched this way (to 27.7K units in DOB)
	-- DOB matches for all but one Projected project are Application Filed (no project had completed units in DOB)
	
SELECT 
	h.project_id AS hpd_project_id, building_id, project_name, CONCAT(house_number,' ',street_name) AS hpd_address, status, x_start_date, x_completion_date, total_units AS units,
    j.dob_job_number, address, dob_type, dcp_status, status_a, status_q, u_init, u_prop, u_net, u_net_complete, u_net_incomplete
FROM 
    capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
LEFT JOIN 
capitalplanning.dobdev_jobs_20180316 AS j
ON CONCAT(h.house_number,' ',h.street_name) = j.address
WHERE j.dob_type <> 'DM'
AND j.dcp_status <> 'Withdrawn'
AND j.dcp_status <> 'Disapproved'
AND j.dcp_status <> 'Suspended'
AND (j.dcp_occ_init = 'Residential' OR j.dcp_occ_prop = 'Residential')
AND j.x_dup_flag <> 'Possible Duplicate'
AND j.x_outlier <> 'true'

-- Second method - match by distance AND timeframe between HPD & DOB 
-- If HPD project did not result in matches using address method, then try to find matches if the HPD and DOB points are within 3 meters of each other AND DOB status a or q within 3 years of HPD's start date
-- Results/quality of method (to be added)
	--- 20.5K of the unmatched 22K units from Completed or In Construction matched this way (to 21.2K units in DOB)
	--- DOB matches for all Projected project are Application Filed or Permit Issued (no project had completed units in DOB)

WITH address AS (
SELECT 
	h.project_id AS hpd_project_id, building_id, j.dob_job_number
FROM 
    capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
LEFT JOIN 
capitalplanning.dobdev_jobs_20180316 AS j
ON CONCAT(h.house_number,' ',h.street_name) = j.address
WHERE j.dob_type <> 'DM'
AND j.dcp_status <> 'Withdrawn'
AND j.dcp_status <> 'Disapproved'
AND j.dcp_status <> 'Suspended'
AND (j.dcp_occ_init = 'Residential' OR j.dcp_occ_prop = 'Residential')
AND j.x_dup_flag <> 'Possible Duplicate'
AND j.x_outlier <> 'true'),

spatial AS (
SELECT 
	h.project_id AS hpd_project_id, building_id, project_name, CONCAT(house_number,' ',street_name) AS hpd_address, status, x_start_date, x_completion_date, total_units AS units,
    j.dob_job_number, address, dob_type, dcp_status, status_a, status_q, u_init, u_prop, u_net, u_net_complete, u_net_incomplete
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
OR EXTRACT(YEAR FROM status_a) - EXTRACT(YEAR FROM x_start_date) BETWEEN -3 AND 3))

SELECT * FROM spatial
WHERE CONCAT(spatial.hpd_project_id, spatial.building_id) NOT IN (SELECT DISTINCT CONCAT(address.hpd_project_id, address.building_id) FROM address)
AND spatial.dob_job_number NOT IN (SELECT DISTINCT address.dob_job_number FROM address)

--- !!!! Saved result of the above 2 methods as new datasets, but ideally could run this altogether

-- Check that dob job is not matched to more than 1 hpd project via each method
-- Results for first method
	--- 5 DOB jobs were matched to more than 1 HPD project
	--- Of the 5, 1 is correct (HPD listed as 2 separate projects)
	--- 1 appears to be a duplicate in HPD list (53558/953668/Phipps Plaza South/KB25 Article XI/56 units AND 52075/953668/PHIPPS PLAZA SOUTH/KB 25/56 units)
	--- Remaining 3 each have false matches (however, manual edits not made bc only 400 units falsely matched) 
	
WITH num AS (
SELECT dob_job_number, count(*) FROM capitalplanning.method1
group by dob_job_number
order by count desc)

SELECT * FROM capitalplanning.method1
WHERE dob_job_number IN (SELECT dob_job_number FROM num WHERE count > 1)
ORDER BY dob_job_number

-- Results for second method
	--- 4 DOB jobs were matched to more than 1 HPD project
	--- Of the 4, 1 is correct (HPD listed as 2 separate projects)
	--- Remaining 3 each have false matches (however, manual edits not made bc all are complete AND fewer than 70 units falsely matched) 
	
WITH num AS (
SELECT dob_job_number, count(*) FROM capitalplanning.method2
group by dob_job_number
order by count desc)

SELECT * FROM capitalplanning.method2
WHERE dob_job_number IN (SELECT dob_job_number FROM num WHERE count > 1)
ORDER BY dob_job_number

-- Check projects without matches from either of the 2 methods
-- Results
	--- Only 2K of the 49.2K units from Completed or In Construction projects were unmatched (4% unmatched)
	--- Remaining unmatched all Projected projects
	
SELECT * FROM capitalplanning.hpd_2018_sca_inputs_geo_pts
WHERE CONCAT(project_id, building_id) NOT IN (SELECT DISTINCT CONCAT(project_id, building_id) FROM method1)
AND CONCAT(project_id, building_id) NOT IN (SELECT DISTINCT CONCAT(project_id, building_id) FROM method2)

/**Create list of matches and note method**/

ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN match_method text,
ADD COLUMN dob_job_number numeric,
ADD COLUMN dob_u_matched numeric, 
ADD COLUMN incremental_hpd_units numeric;



-----------old ------------------
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
