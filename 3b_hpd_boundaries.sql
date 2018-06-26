/**Add boundaries so that units can be aggregated by sub-district**/

ALTER TABLE capitalplanning.hpd_2018_sca_inputs_geo_pts
ADD COLUMN geo_subdist text;

UPDATE capitalplanning.hpd_2018_sca_inputs_geo_pts
SET geo_csd = b.school_dis
FROM dcpadmin.doe_schooldistricts AS b
WHERE ST_Intersects(hpd_2018_sca_inputs_geo_pts.the_geom, b.the_geom)

-- Check
SELECT * FROM capitalplanning.hpd_2018_sca_inputs_geo_pts
WHERE geo_subdist is null
