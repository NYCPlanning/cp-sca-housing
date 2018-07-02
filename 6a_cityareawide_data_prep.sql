-- Locate Planning Coordination tracker that recorded residential upzonings (only source in agency that tracks projected units from rezonings prior to imPACT, info up to 2013)
-- Add in studies since 2012, including future studies (starting with ENY)
-- *Note that projected units represent the increment from no action to with action. Total units projected may be higher, but would require digitization of no action residential development list to ensure not duplicated in existing sources used here. Ongoing effort

/**Identify adopted city-initiated area-wide rezonings since 2000**/
-- *Chose 2000 onwards because build years are typically 10-15 years

WITH projects AS (
SELECT * FROM capitalplanning.bx_projects
UNION
SELECT * FROM capitalplanning.bK_projects
UNION
SELECT * FROM capitalplanning.mn_projects
UNION
SELECT * FROM capitalplanning.qn_projects
UNION
SELECT * FROM capitalplanning.si_projects),

cityled AS (
SELECT z.the_geom, z.project_id, z.ulurpno, z.project_na, z.status, z.effective,
p.applicant_type, p.project_description, p.lead_action, p.new_dwelling_units, p.anticipated_year_built, p.new_commercial_sq_ft, p.new_community_facility_sq_ft, p.new_industrial_sq_ft, p.residential_sq_ft, p.total_dwelling_units_in_project
FROM capitalplanning.nyzma_may2018 AS z
INNER JOIN projects AS p
ON z.project_id = p.project_id
WHERE EXTRACT(YEAR FROM z.effective) >= 2000
AND p.applicant_type = 'DCP' OR p.applicant_type = 'Other Public Agency'
ORDER BY ulurpno)

SELECT cityled.*, s.projected_units, s.build_year
FROM cityled
LEFT JOIN capitalplanning.old_sca_report_with_units AS s
ON cityled.ulurpno = LOWER(s.ulurpno)

-- Create new dataset from query as cityled_projects

/**Rule out projects already in site-specific (will be Other City Agency projects)**/

ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN in_site_specific numeric;

UPDATE capitalplanning.cityled_projects
SET in_site_specific = 1
WHERE project_id IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects WHERE manual_exclude is null);

SELECT * FROM capitalplanning.cityled_projects
WHERE in_site_specific is null AND projected_units >= 200
ORDER BY effective

