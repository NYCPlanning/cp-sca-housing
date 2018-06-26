--- Double check if any projects in DCP that appear to be HPD-financed were not matched (*Creston Ave, adAPT, Maple Mesa should’ve been in HPD data, but already captured in permits. Bedford Arms & 126th Bus Depot are EDC. ECD likely too early to be in HPD)

WITH exact AS (
SELECT 
    i.borough, community_districts, lead_planner, i.project_id, i.project_name, project_status, project_completed, units, build_year, applicant_type, project_description,
	h.project_id AS hpd_project_id, h.building_id, h.project_name AS hpd_project_name, status, project_start_date, building_completion_date, total_units
FROM 
    capitalplanning.all_possible_projects AS i
LEFT JOIN
	capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
ON ST_Intersects(h.the_geom,i.the_geom)
WHERE manual_exclude is null
ORDER BY i.project_id, hpd_project_id)

SELECT
	exact.project_id, project_name, project_status, units, SUM(total_units) AS hpd_units_matched, units-SUM(total_units) AS remaining_units
FROM exact
WHERE (project_description LIKE '%HPD%' OR project_description LIKE '%hpd%' OR applicant_type = 'Other Public Agency')
AND project_completed is null
GROUP BY project_id, project_name, project_status, units
ORDER BY remaining_units, units ASC

--- Create deduped sheet
SELECT 
    	i.project_id, i.project_name, project_completed, certified_referred, units,
	h.project_id AS hpd_project_id, h.building_id, h.project_name AS hpd_project_name, status, total_units
FROM 
    capitalplanning.all_possible_projects AS i
LEFT JOIN
	capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
ON ST_Intersects(h.the_geom,i.the_geom)
WHERE manual_exclude is null
ORDER BY i.project_id, hpd_project_id

--- Add any missing (Spofford), bring into main deduping sheet
INSERT INTO capitalplanning.dcp_hpd_dedupe (project_id, hpd_project_id, building_id)
SELECT a.project_id, a.hpd_project_id::numeric, a.hpd_building_id::numeric
FROM capitalplanning.dcp_hpd_dedupe_add AS a
WHERE CONCAT(a.project_id,a.hpd_project_id,a.hpd_building_id) NOT IN (SELECT DISTINCT CONCAT(project_id,hpd_project_id,building_id) FROM capitalplanning.dcp_hpd_dedupe);

UPDATE capitalplanning.dcp_hpd_dedupe
SET project_name = i.project_name, units = i.units, project_completed = i.project_completed, certified_referred = i.certified_referred
FROM capitalplanning.all_possible_projects AS i
WHERE dcp_hpd_dedupe.project_id = i.project_id;

UPDATE capitalplanning.dcp_hpd_dedupe
SET hpd_project_name = h.project_name, status = h.status, total_units = h.total_units
FROM capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
WHERE dcp_hpd_dedupe.hpd_project_id = h.project_id AND dcp_hpd_dedupe.building_id = h.building_id
