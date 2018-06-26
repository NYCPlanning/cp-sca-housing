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
-- Done in Excel directly by adding EDC ID to HPD data as only 2 EDC projects matched (to 3 unique HPD projects)

/**Calculate incremental EDC units**/

ALTER TABLE capitalplanning.edc_2018_sca_input
ADD COLUMN incremental_hpd_u_matched numeric;

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
