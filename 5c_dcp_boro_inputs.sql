/**Add in borough planner inputs on likelihood to be built and rationale**/
-- Uploaded to CARTO as dcp_add_boro_inputs
-- *Waiting on final round of borough sign-offs, certain projects may change

ALTER TABLE capitalplanning.all_possible_projects
ADD COLUMN likely_to_be_built text,
ADD COLUMN rationale text;

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = b.remaining_likely_to_be_built, rationale = b.rationale
FROM capitalplanning.dcp_add_boro_inputs AS b
WHERE all_possible_projects.project_id = b.project_id

/**Add exclusions identified in 4b_dcp_dob_manual_edits.sql**/

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = 'No', rationale = 'Fully built, no units remaining'
WHERE project_id IN (
'P2012M0635',
'P2012M0564',
'P2012X0204');
  
UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = 'No', rationale = 'Existing use still in place, community opposed'
WHERE project_id = 'P2012K0085';

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = 'Uncertain', rationale = 'Existing use still in place'
WHERE project_id = 'P2014K0530';

UPDATE capitalplanning.all_possible_projects
SET manual_exclude = 0, rationale = 'Duplicate project, same as 2018X0371'
WHERE project_id = 'P2016X0408'

/**Fill in likely to be built for remaining projects**/

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = 'No units remaining'
WHERE likely_to_be_built is null AND remaining_dcp_units = 0;

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = 'Likely'
WHERE likely_to_be_built is null AND remaining_dcp_units <> 0

/**Clean up project status to ensure properly marked as Active or Complete**/
-- Check for projects that should be recorded as Complete bc have project completed dates recorded
/**P2017X0037
P2015M0428
P2015M0236
P2017M0259
P2012K0041
P2014K0056
P2016M0355
P2016Q0238**/

UPDATE capitalplanning.all_possible_projects
SET project_status = 'Complete'
WHERE project_status <> 'Complete' 
AND project_completed is not null;

-- Check for projects that should be recorded as Complete bc process stage is marked as Completed
/**P2015K0515
P2016K0120
P2016K0433
P2015M0320
P2017X0271
P2016M0421**/

UPDATE capitalplanning.all_possible_projects
SET project_status = 'Complete'
WHERE project_status <> 'Complete' 
AND certified_referred is not null
AND process_stage <> 'Public Review'
AND manual_exclude is null

/**Add in final inputs from EDC**/
UPDATE capitalplanning.all_possible_projects
SET manual_exclude = 0, reason_for_excluding = 'Originally conceived as all senior'
WHERE project_id = 'P2012R0625'

/**Add in final inputs from DCP boroughs**/
-- Adding in P2017R0111 (uncertain why it was not captured automatically) and P2018R0035 (not picked up bc no units filled & no indicators in text description)
-- Deduping not needed bc both projects are on-hold

INSERT INTO capitalplanning.all_possible_projects (borough, community_districts, lead_planner, project_id, project_name, project_description, lead_action, project_status, process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project)
SELECT borough, community_districts, lead_planner, project_id, project_name, project_description, lead_action, project_status, process_stage_name_stage_id_process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project FROM si_projects
WHERE project_id = 'P2017R0111' OR project_id = 'P2018R0035';

UPDATE capitalplanning.all_possible_projects
SET the_geom = i.the_geom, geom_source = 'imPACT Visualization'
FROM capitalplanning.impact_poly_latest AS i
WHERE project_id = 'P2017R0111' OR project_id = 'P2018R0035'

-- Adjusting likelihood to be built
UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = c.remaining_units_likely_to_be_built, rationale = c.rationale
FROM capitalplanning.project_info_cleaning_072018 AS c
WHERE all_possible_projects.project_id = c.project_id;

UPDATE capitalplanning.all_possible_projects
SET likely_to_be_built = c.remaining_units_likely_to_be_built, rationale = c.rationale
FROM capitalplanning.project_info_cleaning_072018 AS c
WHERE all_possible_projects.project_id = c.project_id

-- Adjusting manual exclusions
UPDATE capitalplanning.all_possible_projects
SET manual_exclude = c.manual_exclude::numeric, reason_for_excluding = c.reason_for_excluding
FROM capitalplanning.project_info_cleaning_072018 AS c
WHERE all_possible_projects.project_id = 'P2018R0035'
AND all_possible_projects.project_id = c.project_id

