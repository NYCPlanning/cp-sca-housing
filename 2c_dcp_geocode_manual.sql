/**Add in polygons that did not automatically match to nyzma or imPACT Visualization**/
-- *Note that these manual edits should NOT be needed if 1) ZAP validates that geographic info is captured for all projects in system, 2) ZAP creates polygons for project area data for all projects

-- First source - project in nyzma (all adopted ZMs should be in nyzma, potential differences in ulurpno resulting in no match)

UPDATE capitalplanning.all_possible_projects
SET the_geom = z.the_geom
FROM capitalplanning.nyzma_may2018 AS z
WHERE project_name = 'Melrose Commons North RFP Site B'
AND z.ulurpno = '080002zmx';
UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, nyzma'
FROM capitalplanning.nyzma_may2018 AS z
WHERE project_name = 'Melrose Commons North RFP Site B';

UPDATE capitalplanning.all_possible_projects
SET the_geom = z.the_geom
FROM capitalplanning.nyzma_may2018 AS z
WHERE all_possible_projects.project_id = '2018X0371'
AND z.ulurpno = '180131zmx';
UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, nyzma'
FROM capitalplanning.nyzma_may2018 AS z
WHERE all_possible_projects.project_id = '2018X0371'

-- Second source - project in imPACT Visualization (Franklin Ave - same project as what's recorded for old project ID; 77 Commercial - reason uncertain)

UPDATE capitalplanning.all_possible_projects
SET the_geom = i.the_geom
FROM capitalplanning.impact_poly_latest AS i
WHERE project_name = 'Franklin Avenue Rezoning'
AND i.projectid = 'P2015K0057';
UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, impact visualization'
FROM capitalplanning.impact_poly_latest AS i
WHERE project_name = 'Franklin Avenue Rezoning';

UPDATE capitalplanning.all_possible_projects
SET the_geom = i.the_geom
FROM capitalplanning.impact_poly_latest AS i
WHERE project_name = '77 Commercial Street Special Permit Renewal'
AND i.projectid = 'P2012K0578';
UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, impact visualization'
FROM capitalplanning.impact_poly_latest AS i
WHERE project_name = '77 Commercial Street Special Permit Renewal'

-- Third source - BBLs in ZAP, project documents, planner (all sources used because not every project had BBLs recorded in ZAP)
-- Download project BBLs table from ZAP
-- Create empty dataset and add in relevant BBLs

/**Add polygons from PLUTO to project BBLs table**/
UPDATE capitalplanning.sca_housing_manual_bbl
SET the_geom = p.the_geom
FROM dcpadmin.dcp_mappluto_2017v1 AS p
WHERE sca_housing_manual_bbl.bbl = p.bbl;

WITH subset as (
  SELECT project_id, the_geom FROM capitalplanning.all_possible_projects
  WHERE project_id IN (SELECT DISTINCT project_id FROM capitalplanning.sca_housing_manual_bbl)
),
unioned_manual as (
  SELECT project_id, ST_Union(the_geom) as the_geom
  FROM capitalplanning.sca_housing_manual_bbl
  GROUP BY project_id
),
combined AS (
SELECT * FROM unioned_manual
UNION
SELECT * FROM subset)
select project_id, ST_Union(the_geom) as the_geom
FROM combined
GROUP BY project_id
--- Save as new dataset sca_housing_manual_bbl_unioned

UPDATE capitalplanning.all_possible_projects
SET the_geom = u.the_geom
FROM capitalplanning.sca_housing_manual_bbl_unioned AS u
WHERE all_possible_projects.project_id = u.project_id;

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, various'
WHERE all_possible_projects.project_id IN (SELECT DISTINCT project_id FROM  capitalplanning.sca_housing_manual_bbl_unioned)

/**Check for projects missing geometries**/
SELECT * FROM capitalplanning.all_possible_projects
WHERE the_geom is null
-- *1 project was not res, 1 project was a ZS completed in 2014 - assumed built, 2 projects were South Rich SS, 1 project was age-restricted housing

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Not found'
WHERE the_geom is null
