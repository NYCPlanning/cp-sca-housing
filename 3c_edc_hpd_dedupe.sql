/**Develop match method**/
-- Since EDC projects are all projected, match to HPD Projected if HPD point in EDC project area

SELECT
	e.*,
    h.project_id, h.building_id, h.total_units AS hpd_total_units, h.incremental_hpd_units
FROM capitalplanning.edc_2018_sca_input AS e
LEFT JOIN capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
ON ST_Intersects(e.the_geom, h.the_geom)
WHERE h.status = 'Projected'

/**Create list of matches**/
-- Done in Excel directly by adding EDC ID to HPD data as only 2 EDC projects matched
-- Manually matched 1 HPD project (HPD point for 1 of 2 Spofford outside of project area)

/**Calculate incremental EDC units**/

ALTER TABLE capitalplanning.edc_2018_sca_input
ADD COLUMN incremental_hpd_u_matched numeric,
ADD COLUMN incremental_edc_units numeric;

WITH spatial AS (
SELECT
	e.edc_id, SUM(h.incremental_hpd_units)
FROM capitalplanning.edc_2018_sca_input AS e
LEFT JOIN capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
ON ST_Intersects(e.the_geom, h.the_geom)
WHERE h.status = 'Projected'
GROUP BY edc_id)

UPDATE capitalplanning.edc_2018_sca_input
SET incremental_hpd_u_matched = spatial.sum
FROM spatial
WHERE edc_2018_sca_input.edc_id = spatial.edc_id

-- Manually matched 1 HPD project (HPD point for 1 of 2 Spofford outside of project area)
UPDATE capitalplanning.edc_2018_sca_input
SET incremental_hpd_u_matched = incremental_hpd_u_matched + h.incremental_hpd_units
FROM capitalplanning.hpd_2018_sca_inputs_geo_pts AS h
WHERE edc_id = 3
AND project_id = '63757' AND building_id = '975409';

UPDATE capitalplanning.edc_2018_sca_input
SET incremental_edc_units = 
(CASE WHEN incremental_hpd_u_matched is null THEN total_units
 ELSE total_units - incremental_hpd_u_matched END)
