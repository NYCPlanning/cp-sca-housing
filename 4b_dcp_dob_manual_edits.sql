/**Exclude false matches**/
-- Check matches where diff btw projected and matched >= 50 OR <= - 50
-- Check completed projects with build years prior to 2018 (or blank) with no matches

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

/**Add in manual matches**/
-- Create new dataset as dcp_dob_dedupe_add
-- *Reason for manual matches include:
	-- Project area recorded by DCP incorrect
	-- Project is missing project_completed AND certified_referred date
	-- Matching DOB permit was disapproved or categorized as Other Accomodations -> in this case, matched DOB jobs not counted in DOB file, so units will be counted as DCP units remaining
	
-- *Checks to consider in future:
	-- If project is missing project_completed AND certified_referred date, should match based on year implied in project_id (impossible to determine bc no fields indicated project was complete)
	-- If project is only 1 building and has units remaining, but DOB jobs matched have received final CofO, then exclude remaining units (e.g., 606 W 57th TF Cornerstone, 505-513 West 43rd Street)
	-- If project has units remaining, check for signal of likelihood to be built if DM permits in progress, if permit filed but disapproved (e.g, Caton Flats, 537-545 W 37th), or permit issued as non-res (esp other accomodations and commercial)

ALTER TABLE capitalplanning.dcp_dob_dedupe
ADD COLUMN manual_match text;

INSERT INTO capitalplanning.dcp_dob_dedupe (project_id, dob_job_number)
SELECT a.project_id, a.dob_job_number
FROM capitalplanning.dcp_dob_dedupe_add AS a
WHERE CONCAT(a.project_id,a.dob_job_number) NOT IN (SELECT DISTINCT CONCAT(project_id,dob_job_number) FROM capitalplanning.dcp_dob_dedupe);

UPDATE capitalplanning.dcp_dob_dedupe
SET manual_match = 'manual'
WHERE project_name is null;

UPDATE capitalplanning.dcp_dob_dedupe
SET project_name = i.project_name, project_description = i.project_description, lead_action = i.lead_action, applicant_type = i.applicant_type, project_completed = i.project_completed, certified_referred = i.certified_referred, units = i.units, build_year = i.build_year 
FROM capitalplanning.all_possible_projects AS i
WHERE dcp_dob_dedupe.project_id = i.project_id
AND manual_match = 'manual';

UPDATE capitalplanning.dcp_dob_dedupe
SET dob_type = j.dob_type, dcp_status = j.dcp_status, status_a = j.status_a, status_q = j.status_q, u_init = j.u_init, u_prop = j.u_prop, u_net = j.u_net, u_net_complete = j.u_net_complete, u_net_incomplete = j.u_net_incomplete
FROM capitalplanning.dobdev_jobs_20180316 AS j
WHERE dcp_dob_dedupe.dob_job_number = j.dob_job_number
AND manual_match = 'manual'

/**Flagged for additional changes in based on review
P2012M0635	606 West 57th Street (TF Cornerstone) - built, DOB permit matched but no units remaining --> change in final sheet
P2012M0564	505-513 West 43rd Street - built, DOB permit matched but no units remaining --> change in final sheet
P2012K0085	EMPIRE BOULEVARD REZONING - existing use still in place, NOT LIKELY due to community opposition --> change in final sheet
P2012X0204	Melrose Commons North RFP Site B - built, no units remaining (no other DOB permits found) --> change in final sheet
P2016X0408	Park Haven (Formerly St. Ann's, East 142nd Street) - manually exclude, same as 2018X0371
P2014K0530	13-15 Greenpoint Avenue - existing use still in place, Uncertain on likelihood --> change in final sheet**/

UPDATE capitalplanning.all_possible_projects
SET manual_exclude = 0, reason_for_excluding = 'Project recorded 2x - same as 2018X0371'
WHERE project_id = 'P2016X0408'
