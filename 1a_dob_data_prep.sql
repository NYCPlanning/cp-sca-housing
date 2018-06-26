/*** From DCP’s DOB database, get list of all residential jobs***/

WITH completions AS (
SELECT
    the_geom, dob_job_number, address, dcp_dev_category, dcp_occ_category, dcp_occ_init, dcp_occ_prop, 
  	dcp_status, status_q, c_date_earliest, c_type_latest,
  	stories_init, stories_prop, u_init, u_prop, u_net,
    u_2010pre_increm + u_2010post_increm AS units_complete_2010, u_2011_increm, u_2012_increm, u_2013_increm, u_2014_increm, u_2015_increm, u_2016_increm, u_2017_increm, u_net_complete,
  	geo_subdistrict, latitude, longitude, bin, bbl
FROM
	capitalplanning.dobdev_jobs_20180316
WHERE the_geom is not null
AND dcp_status <> 'Withdrawn'
AND dcp_status <> 'Disapproved'
AND dcp_status <> 'Suspended'
AND (dcp_occ_init = 'Residential' OR dcp_occ_prop = 'Residential')
AND x_dup_flag <> 'Possible Duplicate'
AND x_outlier <> 'true'),

permitted AS (
SELECT
    dob_job_number, 
  	u_net_incomplete
FROM
	capitalplanning.dobdev_jobs_20180316
WHERE the_geom is not null
AND dcp_status <> 'Withdrawn'
AND dcp_status <> 'Disapproved'
AND dcp_status <> 'Suspended'
AND (dcp_occ_init = 'Residential' OR dcp_occ_prop = 'Residential')
AND x_dup_flag <> 'Possible Duplicate'
AND x_outlier <> 'true'
AND x_inactive <> 'true')

SELECT
	completions.the_geom,
completions.dob_job_number,
    address,
   	dcp_dev_category AS dob_type,
    dcp_occ_category AS occupancy_type,
    dcp_occ_init AS occupancy_initial,
    dcp_occ_prop AS occupancy_proposed, 
  	dcp_status AS status,
    status_q AS permit_issued_date_status_q,
    c_date_earliest AS earliest_cofo_date, 
    c_type_latest as cofo_type_latest,
  	stories_init AS stories_initial, stories_prop AS stories_proposed, u_init AS units_initial, u_prop AS units_proposed, u_net AS units_net_new, 
    units_complete_2010,
    u_2011_increm AS units_complete_2011,
    u_2012_increm AS units_complete_2012,
    u_2013_increm AS units_complete_2013,
    u_2014_increm AS units_complete_2014,
  	u_2015_increm AS units_complete_2015,
    u_2016_increm AS units_complete_2016,
    u_2017_increm AS units_complete_2017,
  	u_net_complete AS units_complete,
	permitted.u_net_incomplete AS units_incomplete,
    completions.geo_subdistrict AS geo_subdist, latitude, longitude, bin, bbl
FROM completions
LEFT JOIN permitted ON completions.dob_job_number = permitted.dob_job_number

--- Create new dataset from query as dob_2018_sca_inputs

/***Sum by subdistrict***/
WITH completions AS (
SELECT
    geo_subdist,
    sum(units_complete_2010) AS units_complete_2010,
   	sum(units_complete_2011) AS units_complete_2011,
   	sum(units_complete_2012) AS units_complete_2012,
   	sum(units_complete_2013) AS units_complete_2013,
    sum(units_complete_2014) AS units_complete_2014,
    sum(units_complete_2015) AS units_complete_2015,
    sum(units_complete_2016) AS units_complete_2016,
    sum(units_complete_2017) AS units_complete_2017
FROM
	capitalplanning.dob_2018_sca_inputs
WHERE the_geom is not null
AND status not like '%Application%'
GROUP BY geo_subdist),

permitted AS (
SELECT
    geo_subdist,
    sum(units_incomplete) AS units_incomplete
FROM
	capitalplanning.dob_2018_sca_inputs
WHERE the_geom is not null
AND status not like '%Application%'
GROUP BY geo_subdist),

complete_permitted AS (
SELECT
	completions.*,
	permitted.units_incomplete AS u_permitted
FROM completions
LEFT JOIN permitted ON completions.geo_subdist = permitted.geo_subdist),

applications AS (
SELECT
    geo_subdist,
    sum(units_incomplete) AS units_permit_app_status
FROM
	capitalplanning.dob_2018_sca_inputs
WHERE the_geom is not null
AND status like '%Application%'
GROUP BY geo_subdist)

SELECT
	complete_permitted.*,
	applications.units_permit_app_status AS units_permit_app_status  
FROM complete_permitted
LEFT JOIN applications ON complete_permitted.geo_subdist = applications.geo_subdist

--- Export to Excel for sharing

