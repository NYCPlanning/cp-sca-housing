-- In Excel, rule out irrelevant projects in manual exclude column and note reason
-- In Excel, add in units and build year if missing & where possible and note source
-- Saved in CARTO as all_possible_projects_cleaning

/**Bring into master project list**/

ALTER TABLE capitalplanning.all_possible_projects
ADD COLUMN manual_exclude numeric,
ADD COLUMN reason_for_excluding text,
ADD COLUMN units numeric,
ADD COLUMN build_year numeric;

UPDATE capitalplanning.all_possible_projects
SET manual_exclude = c.manual_exclude, reason_for_excluding = c.reason_for_excluding
FROM capitalplanning.all_possible_projects_cleaning AS c
WHERE all_possible_projects.project_id = c.project_id;

UPDATE capitalplanning.all_possible_projects
SET units = GREATEST(all_possible_projects.new_dwelling_units,all_possible_projects.total_dwelling_units_in_project,c.dus_added)
FROM capitalplanning.all_possible_projects_cleaning AS c
WHERE all_possible_projects.project_id = c.project_id;

UPDATE capitalplanning.all_possible_projects
SET build_year = GREATEST(c.build_year_added,anticipated_year_built)
FROM capitalplanning.all_possible_projects_cleaning AS c
WHERE all_possible_projects.project_id = c.project_id
