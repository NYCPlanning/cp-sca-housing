-- Locate Planning Coordination tracker that recorded residential upzonings (only source in agency that tracks projected units from rezonings prior to imPACT, info up to 2013)
-- Add in studies since 2012, including future studies (starting with ENY)
-- *Note that projected units represent the increment from no action to with action. Total units projected may be higher, but would require digitization of no action residential development list to ensure not duplicated in existing sources used here. Ongoing effort

/**Identify adopted city-initiated area-wide rezonings since 2000**/
-- *Chose 2000 onwards because build years are typically 10-15 years. However old Planning Coordination only dates back to 2003. Confirmed that no major rezonings are missing

WITH unioned AS (
SELECT ST_Union(z.the_geom) AS the_geom, z.project_id, z.ulurpno, z.project_na, z.status, z.effective
FROM capitalplanning.nyzma_may2018 AS z
GROUP BY z.project_id, z.ulurpno, z.project_na, z.status, z.effective),

projectdata AS (
SELECT * FROM capitalplanning.bx_projects
UNION
SELECT * FROM capitalplanning.bK_projects
UNION
SELECT * FROM capitalplanning.mn_projects
UNION
SELECT * FROM capitalplanning.qn_projects
UNION
SELECT * FROM capitalplanning.si_projects),

cityledall AS (
SELECT
    unioned.the_geom, unioned.project_id, unioned.ulurpno, unioned.project_na, unioned.status, unioned.effective,
    p.applicant_type, p.project_description, p.lead_action, p.new_dwelling_units, p.total_dwelling_units_in_project, p.anticipated_year_built
FROM unioned    
INNER JOIN projectdata AS p
ON unioned.project_id = p.project_id
WHERE EXTRACT(YEAR FROM unioned.effective) >= 2000
AND p.applicant_type = 'DCP' OR p.applicant_type = 'Other Public Agency'
ORDER BY ulurpno)

SELECT cityledall.*, s.projected_units, s.build_year
FROM cityledall
INNER JOIN capitalplanning.old_sca_report_with_units AS s
ON cityledall.ulurpno = LOWER(s.ulurpno)
AND (s.projected_units >= 200 OR GREATEST(cityledall.total_dwelling_units_in_project, cityledall.new_dwelling_units) >= 200)

-- Create new dataset from query as cityled_projects

/**Rule out projects already in site-specific (will be Other City Agency projects)**/

ALTER TABLE capitalplanning.cityled_projects
ADD COLUMN in_site_specific numeric;

UPDATE capitalplanning.cityled_projects
SET in_site_specific = 1
WHERE project_id IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects WHERE manual_exclude is null)



