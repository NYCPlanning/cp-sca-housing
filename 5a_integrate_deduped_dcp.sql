/**Add in DOB units matched**/

ALTER TABLE capitalplanning.all_possible_projects
ADD COLUMN num_dob_jobs_matched numeric, 
ADD COLUMN dob_u_matched numeric, 
ADD COLUMN num_hpd_matched numeric, 
ADD COLUMN incremental_hpd_u_matched numeric,
ADD COLUMN num_edc_matched numeric, 
ADD COLUMN incremental_edc_units numeric,
ADD COLUMN remaining_dcp_units numeric;

WITH matches AS (
SELECT p.project_id, p.units, count(dob_job_number), sum(u_init) AS u_init, sum(u_prop) AS u_prop, sum(u_net) AS u_net, sum(u_net_complete) AS u_net_complete, sum(u_net_incomplete) AS u_net_incomplete, sum(u_net_complete)+sum(u_net_incomplete) AS u_net_summed
FROM capitalplanning.dcp_dob_dedupe AS p
GROUP BY p.project_id, p.units)

UPDATE capitalplanning.all_possible_projects
SET num_dob_jobs_matched = m.count, dob_u_matched = greatest(m.u_net, m.u_net_summed)
FROM matches AS m WHERE all_possible_projects.project_id = m.project_id;

UPDATE capitalplanning.all_possible_projects
SET num_dob_jobs_matched = 0, dob_u_matched = 0
WHERE dob_u_matched is null

/**Add in HPD units matched**/
