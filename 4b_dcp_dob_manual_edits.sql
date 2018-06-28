/**Exclude false matches**/
-- Check matches where diff btw projected and matched >= 50 OR <= - 50 (reviewed 31 projects)
-- Check completed projects with build years prior to 2018 (or blank) with no matches (reviewed another 20 projects, only reviewed projects with 50+ units)

SELECT i.project_id, i.project_name, i.lead_action, i.project_completed,
	i.units, i.build_year,
	count(matches.dob_job_number) AS num_dob_jobs_matched,
	sum(matches.u_net) AS dob_u_matched,
	sum(matches.units)-sum(matches.u_net) AS u_remaining,
  i.units-sum(matches.u_net) AS diff_orig_matched
FROM capitalplanning.all_possible_projects AS i
LEFT JOIN capitalplanning.dcp_dob_dedupe AS matches
ON i.project_id = matches.project_id
WHERE i.manual_exclude is null
GROUP BY i.project_id, i.project_name, i.lead_action, i.project_completed, i.units, i.build_year
ORDER BY diff_orig_matched

/**Flagged for manual changed based on review
P2012M0635	606 West 57th Street (TF Cornerstone) - built, no units remaining
P2012M0564	505-513 West 43rd Street - built, no units remaining
P2012K0085	EMPIRE BOULEVARD REZONING - existing use still in place, Uncertain on likelihood due to community opposition
P2012M0178	47-50 WEST STREET - 50 West is built, need to manually add DOB
P2012X0204	Melrose Commons North RFP Site B - built, no units remaining
P2016X0408	Park Haven (Formerly St. Ann's, East 142nd Street) - manually exclude, same as 2018X0371
P2014K0530	13-15 Greenpoint Avenue - existing use still in place, Uncertain on likelihood
P2012Q0031	FLUSHING MEADOWS EAST REZONING
P2016K0052	1535 Bedford Ave FRESH (Chair Cert)
P2014M0430	551 Tenth Ave. (HY DIB application) - built, need to manually add DOB
P2015M0004	537-545 W. 37th Street (DIB application)

-- To do: if project has units remaining, but DOB is C-Co, only 1-to-1 match then exclude units (e.g., TF Cornerstone, 505-513 West 43rd Street)

---------------------- old --------------------------------
--- Exclude false matches
ALTER TABLE capitalplanning.dcp_dob_dedupe
ADD COLUMN manual_check text,
ADD COLUMN dob_u_matched numeric,
ADD COLUMN incremental_dcp_units numeric;

UPDATE capitalplanning.dcp_dob_dedupe
SET manual_check = 'Different'
WHERE (project_id = 'P2014K0144' AND dob_job_number = '320374064')
OR (project_id = 'P2017Q0385' AND dob_job_number = '421067767')
OR (project_id = 'P2017Q0386' AND dob_job_number = '421067767')
OR (project_id = 'P2012K0153' AND dob_job_number = '310201616')
OR (project_id = 'P2012M0485' AND dob_job_number = '110030485')
OR (project_id = 'P2012M0635' AND dob_job_number = '121190585')
OR (project_id = 'P2012M0680' AND dob_job_number = '121203866')
OR (project_id = 'P2012M0680' AND dob_job_number = '122782186')
OR (project_id = 'P2012Q0316' AND dob_job_number = '421070450')
OR (project_id = 'P2015K0145' AND dob_job_number = '320577531');

--- Add matches manually (checking if any active or on-hold projects are matched, if excluded by the within 3 years rule)

INSERT INTO capitalplanning.dcp_dob_dedupe (project_id, dob_job_number)
SELECT a.project_id, a.dob_job_number
FROM capitalplanning.dcp_dob_dedupe_add AS a
WHERE CONCAT(a.project_id,a.dob_job_number) NOT IN (SELECT DISTINCT CONCAT(project_id,dob_job_number) FROM capitalplanning.dcp_dob_dedupe);

UPDATE capitalplanning.dcp_dob_dedupe
SET manual_check = 'Added'
WHERE borough is null;

UPDATE capitalplanning.dcp_dob_dedupe
SET u_init = j.u_init, u_prop = j.u_prop, u_net = j.u_net, u_net_complete = j.u_net_complete, u_net_incomplete = j.u_net_incomplete
FROM capitalplanning.dobdev_jobs_20180316 AS j
WHERE manual_check = 'Added' AND dcp_dob_dedupe.dob_job_number = j.dob_job_number;

UPDATE capitalplanning.dcp_dob_dedupe
SET units = p.units
FROM capitalplanning.all_possible_projects AS p
WHERE manual_check = 'Added' AND dcp_dob_dedupe.project_id = p.project_id

--- Delete false matches
DELETE FROM capitalplanning.dcp_dob_dedupe
WHERE manual_check = 'Different'
