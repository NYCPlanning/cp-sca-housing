
-- Areawide and DOB (rezonings prior to ENY, used rezoning area)

WITH dob AS (
SELECT
	z.project_id, z.project_na, z.projected_units, j.dob_job_number, j.dob_address, j.u_net
FROM 
	capitalplanning.cityled_projects AS z
LEFT JOIN
    capitalplanning.dobdev_jobs_20180316 AS j
ON ST_Intersects(j.the_geom,z.the_geom)
WHERE z.in_site_specific is null AND z.projected_units >= 200
AND (EXTRACT(YEAR FROM j.status_a) - EXTRACT(YEAR FROM z.effective) >= -3
OR EXTRACT(YEAR FROM j.status_q) - EXTRACT(YEAR FROM z.effective) >= -3)
AND j.dcp_status <> 'Withdrawn'
AND j.dcp_status <> 'Disapproved'
AND j.dcp_status <> 'Suspended'
AND (j.dcp_occ_init = 'Residential' OR j.dcp_occ_prop = 'Residential')
AND j.x_dup_flag <> 'Possible Duplicate'
AND j.x_outlier <> 'true'
AND j.dob_type <> 'DM'
AND j.u_net > 0
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018'))



areahpd AS (
SELECT
	z.project_id, z.project_na, z.projected_units, j.project_id AS hpd_project_id, j.building_id, j.project_name AS hpd_project_name, j.incremental_hpd_units
FROM 
	capitalplanning.cityled_projects AS z
LEFT JOIN
    capitalplanning.hpd_2018_sca_inputs_geo_pts AS j
ON ST_Intersects(j.the_geom,z.the_geom)
WHERE z.in_site_specific is null AND z.projected_units >= 200
AND EXTRACT(YEAR FROM j.x_start_date) - EXTRACT(YEAR FROM z.effective) >= -3)
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018')
