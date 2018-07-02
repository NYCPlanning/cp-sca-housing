-- Locate Planning Coordination tracker that recorded residential upzonings (only source in agency that tracks projected units from rezonings prior to imPACT, info up to 2013)
-- Add in studies since 2012, including future studies (starting with ENY)
-- *Note that projected units represent the increment from no action to with action. Total units projected may be higher, but would require digitization of no action residential development list to ensure not duplicated in existing sources used here. Ongoing effort

/**Identify adopted city-initiated area-wide rezonings since 2000**/
-- *Chose 2000 onwards because build years are typically 10-15 years. However old Planning Coordination only dates back to 2003. Confirmed that no major rezonings are missing

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
p.applicant_type, p.project_description, p.lead_action, p.new_dwelling_units, p.anticipated_year_built, p.total_dwelling_units_in_project
FROM capitalplanning.nyzma_may2018 AS z
INNER JOIN projects AS p
ON z.project_id = p.project_id
WHERE EXTRACT(YEAR FROM z.effective) >= 2000
AND p.applicant_type = 'DCP' OR p.applicant_type = 'Other Public Agency'
ORDER BY ulurpno)

SELECT
cityled.the_geom, cityled.project_id, cityled.ulurpno, project_na, status, effective, cityled.applicant_type, project_description, lead_action, new_dwelling_units, total_dwelling_units_in_project, anticipated_year_built, 
s.projected_units, s.build_year
FROM cityled
INNER JOIN capitalplanning.old_sca_report_with_units AS s
ON cityled.ulurpno = LOWER(s.ulurpno)
AND (s.projected_units >= 200 OR GREATEST(total_dwelling_units_in_project, new_dwelling_units) >= 200)

-- Create new dataset from query as cityled_projects

/**Rule out projects already in site-specific (will be Other City Agency projects)**/

ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN in_site_specific numeric;

UPDATE capitalplanning.cityled_projects
SET in_site_specific = 1
WHERE project_id IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects WHERE manual_exclude is null)

