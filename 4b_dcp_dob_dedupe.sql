--- Check that completed projects have either a completion or certification date
SELECT DISTINCT(project_status), COUNT(*) 
FROM capitalplanning.all_possible_projects
WHERE CHAR_LENGTH(project_completed)<2
AND CHAR_LENGTH(certified_referred)<2
GROUP BY project_status

--- Match if DOB job falls within project area AND DOB job status q or status a within 3 years of project completion or certification
SELECT 
    i.borough, community_districts, lead_planner, project_id, project_name, project_completed, certified_referred, units, build_year,
	j.dob_job_number, address, dob_type, dcp_status, status_q, u_init, u_prop, u_net, u_net_complete, u_net_incomplete
FROM 
    capitalplanning.all_possible_projects AS i
LEFT JOIN
    capitalplanning.dobdev_jobs_20180316 AS j
ON ST_Intersects(j.the_geom,i.the_geom)
WHERE j.dob_type <> 'DM'
AND j.dcp_status <> 'Withdrawn'
AND j.dcp_status <> 'Disapproved'
AND j.dcp_status <> 'Suspended'
AND (j.dcp_occ_init = 'Residential' OR j.dcp_occ_prop = 'Residential')
AND j.x_dup_flag <> 'Possible Duplicate'
AND j.x_outlier <> 'true'
AND (CASE 
WHEN project_completed is not null AND status_q is not null THEN EXTRACT(YEAR FROM project_completed) - EXTRACT(YEAR FROM j.status_q) BETWEEN -3 AND 3
WHEN project_completed is not null AND status_a is not null THEN EXTRACT(YEAR FROM project_completed) - EXTRACT(YEAR FROM j.status_a) BETWEEN -3 AND 3
WHEN certified_referred is not null AND status_q is not null THEN EXTRACT(YEAR FROM certified_referred) - EXTRACT(YEAR FROM j.status_q) BETWEEN -3 AND 3
WHEN certified_referred is not null AND status_a is not null THEN EXTRACT(YEAR FROM certified_referred) - EXTRACT(YEAR FROM j.status_a) BETWEEN -3 AND 3 END)
AND manual_exclude is null
AND applicant_type <> 'DCP'
ORDER BY project_id, dob_job_number

--- Create new dataset from query AS dcp_dob_dedupe
