-- Download from DCP project tracking system (ZAP) using Advanced Query: Look for ‘Projects’ where project status is Completed, Active, or On-Hold, download all reocrds & all fields
-- Import into CARTO as bx_projects
-- *Note that data must be exported from ZAP borough-by-borough due to limitations on exports with 5000+ records

/**Identify relevant projects**/

ALTER TABLE capitalplanning.bx_projects
ADD COLUMN relevant_projects numeric,
ADD COLUMN check_additional_possible numeric,
ADD COLUMN too_early_stage numeric;

-- Automatically mark as a relevant project if it's not a South Richmond School Seat Certs, has submitted a PAS, and has 10+ dwelling units
-- *Assumed no “lingering” units from projects prior to 2012. Assumption driven by limitation in data associated with projects prior to creation of DCP's project tracking system (formerly imPACT, now ZAP)

UPDATE capitalplanning.bx_projects
SET relevant_projects = 1
WHERE si_school_seat <> true
AND process_stage_name_stage_id_process_stage <> 'Initiation'
AND process_stage_name_stage_id_process_stage <> 'Pre-Pas'
AND GREATEST(new_dwelling_units, total_dwelling_units_in_project) >= 10

-- Mark as check additional possible if the project description suggests it may be residential but currently does not have units recorded (exclude early stage projects, DCP-led rezonings which are captured in areawide, and anything that's On-Hold or Completed)

UPDATE capitalplanning.bx_projects
SET check_additional_possible = 1
WHERE relevant_projects is null
AND ((project_description LIKE '%residential%' 
OR project_description LIKE '%housing%'
OR project_description LIKE '%dwelling%'))
AND si_school_seat <> true
AND process_stage_name_stage_id_process_stage <> 'Initiation'
AND process_stage_name_stage_id_process_stage <> 'Pre-Pas'
AND applicant_type <> 'DCP'
AND project_status = 'Active'

-- Mark as too early stage if it has not submitted a PAS but has 10+ dwelling units OR the project description suggests it may be residential

UPDATE capitalplanning.bx_projects
SET too_early_stage = 1
WHERE relevant_projects is null
AND check_additional_possible is null
AND ((project_description LIKE '%residential%' 
OR project_description LIKE '%housing%'
OR project_description LIKE '%dwelling%')
OR (new_dwelling_units >= 10 OR total_dwelling_units_in_project >= 10))
AND si_school_seat <> true
AND (process_stage_name_stage_id_process_stage = 'Initiation'
OR process_stage_name_stage_id_process_stage = 'Pre-Pas')
AND applicant_type <> 'DCP'
AND project_status = 'Active'

/**Consolidate into single dataset**/

SELECT borough, community_districts, lead_planner, project_id, project_name, project_description,  lead_action, project_status, process_stage_name_stage_id_process_stage AS process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, relevant_projects, check_additional_possible, too_early_stage, city_areawide
FROM capitalplanning.bx_projects
WHERE (relevant_projects = 1 OR check_additional_possible = 1 OR too_early_stage = 1)
UNION

SELECT borough, community_districts, lead_planner, project_id, project_name, project_description,  lead_action, project_status, process_stage_name_stage_id_process_stage AS process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, relevant_projects, check_additional_possible, too_early_stage, city_areawide
FROM capitalplanning.bk_projects
WHERE (relevant_projects = 1 OR check_additional_possible = 1 OR too_early_stage = 1)
UNION

SELECT borough, community_districts, lead_planner, project_id, project_name, project_description,  lead_action, project_status, process_stage_name_stage_id_process_stage AS process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, relevant_projects, check_additional_possible, too_early_stage, city_areawide
FROM capitalplanning.mn_projects
WHERE (relevant_projects = 1 OR check_additional_possible = 1 OR too_early_stage = 1)
UNION

SELECT borough, community_districts, lead_planner, project_id, project_name, project_description,  lead_action, project_status, process_stage_name_stage_id_process_stage AS process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, relevant_projects, check_additional_possible, too_early_stage, city_areawide
FROM capitalplanning.qn_projects
WHERE (relevant_projects = 1 OR check_additional_possible = 1 OR too_early_stage = 1)
UNION

SELECT borough, community_districts, lead_planner, project_id, project_name, project_description,  lead_action, project_status, process_stage_name_stage_id_process_stage AS process_stage, project_completed, certified_referred, system_target_certification_date, applicant_type, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, relevant_projects, check_additional_possible, too_early_stage, city_areawide
FROM capitalplanning.si_projects
WHERE (relevant_projects = 1 OR check_additional_possible = 1 OR too_early_stage = 1)
ORDER BY borough ASC, project_id DESC

-- Create new dataset from query as all_possible_projects
