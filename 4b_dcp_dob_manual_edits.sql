/**Exclude false matches**/
-- Export dcp_dob_dedupe to Excel
-- Check matches where diff btw projected and matched >= 50 OR <= - 50
/**Flagged for manual checks
P2012K0085	EMPIRE BOULEVARD REZONING
P2012M0178	47-50 WEST STREET
P2012M0680	West 117th Street Rezoning
P2012X0204	Melrose Commons North RFP Site B
P2014K0469	376-378 Flushing Ave, 43 Franklin Ave(Rose Castle)
P2015K0353	1860 Eastern Parkway
P2016X0408	Park Haven (Formerly St. Ann's, East 142nd Street)**/

/**Check for projects that **/



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
