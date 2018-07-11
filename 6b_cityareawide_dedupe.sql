/**Develop deduping methodology**/
-- *Note that ideally, deduping would be on upzoned lots ONLY. However, digitization of shapefiles used in rezonings prior to ENY needs to be completed
-- *PLUTO can be used to identify upzoned lots, however unable to comprehensively identify upzoned lots in cases where many new lots were created (especially in case of Hudson Yards & HTPS). Changes from recent rezonings such as DTFR, E Harlem, Jerome not yet reflected in PLUTO
-- Methodology
    --- DOB matching - if DOB job was filed or permit issued less than 3 years prior or after adoption (compared against matching only if DOB after adoption - no difference in units remaining for projects with more units projected than seen in DOB)
    --- HPD matching - if HPD start date less than 3 years prior or after adoption (no difference if start date after adoption)
    --- EDC matching - based on project ID (only Stapleton)
    --- DCP site specific matching - based on spatial overlap. Time between adoption and project not used as restriction bc all site specific projects would be 2012 after
    
ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN num_dob_jobs_matched numeric, 
ADD COLUMN dob_u_matched numeric, 
ADD COLUMN num_hpd_matched numeric, 
ADD COLUMN incremental_hpd_u_matched numeric,
ADD COLUMN num_edc_matched numeric, 
ADD COLUMN incremental_edc_u_matched numeric,
ADD COLUMN num_dcp_matched numeric,
ADD COLUMN incremental_dcp_u_matched numeric;

WITH dobmatches AS (
SELECT
	z.project_id, z.project_na, z.projected_units, count(dob_job_number) as num_dob, sum(j.u_net) AS area_dob_u_matched
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
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018')
GROUP BY z.project_id, z.project_na, z.projected_units),

hpdmatches AS (
SELECT
	z.project_id, z.project_na, z.projected_units, count(CONCAT(j.project_id, j.building_id)) AS num_hpd, sum(j.incremental_hpd_units) AS area_incremental_hpd_u_matched
FROM 
	capitalplanning.cityled_projects AS z
LEFT JOIN
    capitalplanning.hpd_2018_sca_inputs_geo_pts AS j
ON ST_Intersects(j.the_geom,z.the_geom)
WHERE z.in_site_specific is null AND z.projected_units >= 200
AND EXTRACT(YEAR FROM j.x_start_date) - EXTRACT(YEAR FROM z.effective) >= -3
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018')
GROUP BY z.project_id, z.project_na, z.projected_units),

edcmatches AS (
SELECT
	z.project_id, z.project_na, z.projected_units, count(j.edc_id) as num_edc, sum(j.total_units) AS area_incremental_edc_u_matched
FROM 
	capitalplanning.cityled_projects AS z,
    capitalplanning.edc_2018_sca_input AS j
WHERE z.project_id = j.dcp_project_id
AND z.in_site_specific is null AND z.projected_units >= 200
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018')
GROUP BY z.project_id, z.project_na, z.projected_units),

dcpmatches AS (
SELECT
	z.project_id, z.project_na, z.projected_units, count(j.project_id) AS num_dcp, sum(j.remaining_dcp_units) AS area_incremental_dcp_u_matched
FROM 
	capitalplanning.cityled_projects AS z,
    capitalplanning.all_possible_projects AS j
WHERE ST_Intersects(j.the_geom,z.the_geom)
AND z.in_site_specific is null AND z.projected_units >= 200
AND j.manual_exclude is null
AND j.likely_to_be_built <> 'No'
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
AND left(z.project_id,5) NOT IN ('P2015', 'P2016', 'P2017', 'P2018')
GROUP BY z.project_id, z.project_na, z.projected_units),

combined AS (
SELECT
	z.project_id, z.project_na, 
  dobmatches.num_dob AS num_dob_jobs_matched,
  dobmatches.area_dob_u_matched AS area_dob_u_matched,
  hpdmatches.num_hpd AS num_hpd_matched,
  hpdmatches.area_incremental_hpd_u_matched AS area_incremental_hpd_u_matched,
  edcmatches.num_edc AS num_edc_matched,
  edcmatches.area_incremental_edc_u_matched AS area_incremental_edc_u_matched,
  dcpmatches.num_dcp AS num_dcp_matched,
  dcpmatches.area_incremental_dcp_u_matched AS area_incremental_dcp_u_matched
FROM capitalplanning.cityled_projects AS z
LEFT JOIN dobmatches ON z.project_id = dobmatches.project_id
LEFT JOIN hpdmatches ON z.project_id = hpdmatches.project_id
LEFT JOIN edcmatches ON z.project_id = edcmatches.project_id
LEFT JOIN dcpmatches ON z.project_id = dcpmatches.project_id
WHERE z.in_site_specific is null AND z.projected_units >= 200)

UPDATE capitalplanning.cityled_projects
SET 
  num_dob_jobs_matched = combined.num_dob_jobs_matched,
  dob_u_matched = combined.area_dob_u_matched,
  num_hpd_matched = combined.num_hpd_matched,
  incremental_hpd_u_matched = combined.area_incremental_hpd_u_matched,
  num_edc_matched = combined.num_edc_matched,
  incremental_edc_u_matched = combined.area_incremental_edc_u_matched,
  num_dcp_matched = combined.num_dcp_matched,
  incremental_dcp_u_matched = combined.area_incremental_dcp_u_matched
FROM combined
WHERE cityled_projects.project_id = combined.project_id

/**Calculate units remaining**/
ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN remaining_units NUMERIC;

UPDATE capitalplanning.cityled_projects
SET remaining_units = (
CASE WHEN dob_u_matched >= projected_units THEN 0
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is not null AND incremental_dcp_u_matched is not null THEN projected_units - dob_u_matched - incremental_hpd_u_matched - incremental_edc_u_matched - incremental_dcp_u_matched
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is not null AND incremental_dcp_u_matched is null THEN projected_units - dob_u_matched - incremental_hpd_u_matched - incremental_edc_u_matched
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is null AND incremental_dcp_u_matched is null THEN projected_units - dob_u_matched - incremental_hpd_u_matched
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is null AND incremental_dcp_u_matched is not null THEN projected_units - dob_u_matched - incremental_hpd_u_matched - incremental_dcp_u_matched
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is null AND incremental_dcp_u_matched is null THEN projected_units - dob_u_matched
WHEN dob_u_matched is null AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is null AND incremental_dcp_u_matched is null THEN projected_units
WHEN dob_u_matched < projected_units AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is null AND incremental_dcp_u_matched is not null THEN projected_units - incremental_dcp_u_matched END);

/**Zero out negative units remaining and if 10 or fewer units remaining**/

UPDATE capitalplanning.cityled_projects
SET remaining_units = 0
WHERE remaining_units <= 10

/**Check ENY - manually matches to limit to upzoned lots only**/
-- *ENY - Block 4143 (2 large HPD projects at Atlantic Chestnut included, even though in RWCDS they were projected to be non-res and included in No Action)

/**Check DTRF - manually confirmed matches using rezoning area method on upzoned lots**/
-- to be added


/**Add manual changes based on knowledge of rezonings**/
-- *Broadway Triangle URA - took out Pfizer, explicitly not included in URA

ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN manual_changes numeric,
ADD COLUMN clean_remaining_units numeric;

UPDATE capitalplanning.cityled_projects
SET manual_changes = (
CASE WHEN project_na = 'BROADWAY TRIANGLE URA' THEN -1146
WHEN project_na = 
