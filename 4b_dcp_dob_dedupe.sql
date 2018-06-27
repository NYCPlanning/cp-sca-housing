/**Develop deduping methodology and check match rate of various options**/
-- Method used - match if spatial overlap, permit issued 3 years prior OR after dcp project completion or cert
-- Results
	--- 81 of the 171 certified/completed projects had matches
	--- Too conservative if limiting to permits issued strictly AFTER (only 23 of the 171 had matches)

WITH matches AS (
SELECT 
    i.project_id, project_name, project_description, lead_action, applicant_type, geom_source,
    i.project_completed, certified_referred, units, build_year,
	j.dob_job_number, dob_type, dcp_status, status_a, status_q, u_init, u_prop, u_net, u_net_complete, u_net_incomplete
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
WHEN project_completed is not null AND status_q is not null THEN EXTRACT(YEAR FROM project_completed) - EXTRACT(YEAR FROM j.status_q) >= -3
WHEN project_completed is not null AND status_a is not null THEN EXTRACT(YEAR FROM project_completed) - EXTRACT(YEAR FROM j.status_a) >= -3
WHEN certified_referred is not null AND status_q is not null THEN EXTRACT(YEAR FROM certified_referred) - EXTRACT(YEAR FROM j.status_q) >= -3
WHEN certified_referred is not null AND status_a is not null THEN EXTRACT(YEAR FROM certified_referred) - EXTRACT(YEAR FROM j.status_a) >= -3 END)
AND manual_exclude is null
AND applicant_type <> 'DCP'
ORDER BY project_id, dob_job_number)

SELECT i.project_id, i.project_name, i.lead_action, 
	i.units, i.build_year,
	count(matches.dob_job_number) AS num_dob_jobs_matched,
	sum(matches.u_net) AS dob_u_matched,
	sum(matches.units)-sum(matches.u_net) AS u_remaining
FROM capitalplanning.all_possible_projects AS i
LEFT JOIN matches
ON i.project_id = matches.project_id
GROUP BY i.project_id, i.project_name, i.lead_action, i.units, i.build_year
ORDER BY u_remaining

--- Create new dataset from query AS dcp_dob_dedupe

-- Check that a DOB job is not matched more than once
SELECT DISTINCT dob_job_number, count(*) FROM capitalplanning.dcp_dob_dedupe
GROUP BY dob_job_number

-- 1 job is, but the 2 dcp projects are same (1 should be closed out)
SELECT * FROM capitalplanning.dcp_dob_dedupe
WHERE dob_job_number = '421067767'
ORDER BY count DESC
