-- Upload nyzma (May 2018 version used)
-- Upload imPACT Visualization polygons (April 2018 version used, frozen to ZAP go-live date)
-- Upload project actions

/**Add project_id to nyzma**/
-- *Note that this step is required because nyzma only tracks a project by lead ulurp number (assumed it's lead ulurp number). However, ZAP project data only tracks projects by project ID. ZAP project actions tables is the only dataset that links project ID to each ulurp number associated with the project
-- *Note again that this must be done borough-by-borough due to limitations with exporting data with 5000+ records from ZAP

ALTER TABLE capitalplanning.nyzma_may2018
ADD COLUMN project_id text,
ADD COLUMN project_action_status text;

WITH temp AS (
SELECT
  z.ulurpno AS ulurp,
  a.project AS project,
  a.project_action_status AS status
FROM 
  capitalplanning.nyzma_may2018 AS z,
  capitalplanning.bx_actions AS a
WHERE z.ulurpno = lower(right(a.ulurp_number,char_length(a.ulurp_number)-1)))

UPDATE capitalplanning.nyzma_may2018
SET project_id = temp.project, project_action_status = temp.status
FROM temp
WHERE ulurpno = temp.ulurp

/**Repeat above for other boroughs**/

/**Identify projects in nyzma that did not automatically match to project IDs**/
SELECT * FROM capitalplanning.nyzma_may2018
WHERE project_id is null

/**Manually add in project IDs that are in nyzma but did not match by ulurpno**/
-- *Note that theoretically this should not be occur as ZAP should've recorded all ulurp numbers associated with a project

UPDATE capitalplanning.nyzma_may2018
SET project_id = 'P2012K0184'
WHERE project_na = 'MILL BASIN' 
AND project_id is null;

UPDATE capitalplanning.nyzma_may2018
SET project_id = 'P2016M0065'
WHERE project_na = 'Inwood Rezoning' 
AND project_id is null;

UPDATE capitalplanning.nyzma_may2018
SET project_id = 'P2015X0380'
WHERE project_na = 'Westchester Mews Rezoning' 
AND project_id is null;

UPDATE capitalplanning.nyzma_may2018
SET project_id = 'P2014K0163'
WHERE project_na like 'Hamilton%Patio' 
AND project_id is null;

UPDATE capitalplanning.nyzma_may2018
SET project_id = 'P2012M0224'
WHERE project_na = 'RIVER PLAZA REZONING' 
AND project_id is null

/**Geocode to nyzma first, then to imPACT Visualization polygons**/

ALTER TABLE capitalplanning.all_possible_projects
ADD COLUMN geom_source text;

UPDATE capitalplanning.all_possible_projects
SET the_geom = z.the_geom
FROM capitalplanning.nyzma_may2018 AS z
WHERE all_possible_projects.project_id = z.project_id;

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'nyzma'
WHERE the_geom is not null;

UPDATE capitalplanning.all_possible_projects
SET the_geom = i.the_geom
FROM capitalplanning.impact_poly_latest AS i
WHERE all_possible_projects.project_id = i.projectid
AND all_possible_projects.the_geom is null;

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'imPACT Visualization'
WHERE the_geom is not null AND geom_source is null;

UPDATE capitalplanning.all_possible_projects
SET the_geom = z.the_geom
FROM capitalplanning.nyzma_may2018 AS z
WHERE project_name = 'Melrose Commons North RFP Site B'
AND z.ulurpno = '080002zmx';

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, nyzma'
FROM capitalplanning.nyzma_may2018 AS z
WHERE project_name = 'Melrose Commons North RFP Site B'

UPDATE capitalplanning.all_possible_projects
SET the_geom = z.the_geom
FROM capitalplanning.nyzma_may2018 AS z
WHERE all_possible_projects.project_id = '2018X0371'
AND z.ulurpno = '180131zmx';

UPDATE capitalplanning.all_possible_projects
SET geom_source = 'Manual, nyzma'
FROM capitalplanning.nyzma_may2018 AS z
WHERE all_possible_projects.project_id = '2018X0371'

/**Identify projects with missing geometries**/
SELECT * FROM capitalplanning.all_possible_projects
WHERE the_geom is null
