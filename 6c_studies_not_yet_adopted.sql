/**Add in rezoning boundaries for studies that have not been adopted, but have defined or draft rezoning boundaries**/
-- *Note these steps were required due to lack of central repository for studies (planned in future). DCP should also make sure to maintain rezoning boundaries for non-DCP led studies such as Inwood
-- *Note that boundaries may change
-- *Deduping not required

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.edc_area_wide_rezonings AS g
WHERE g.rezoning = 'Inwood'
AND old_sca_report_with_units.name like 'Inwood%';

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.table_2017gowanusstudyarea AS g
WHERE g.cartodb_id = 1
AND old_sca_report_with_units.name like 'Gowanus%';

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.lic_core_study_area_updated_04192016 AS g
WHERE g.cartodb_id = 1
AND old_sca_report_with_units.name like 'LIC Core%';

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.bsc_rezoning_area_20170316 AS g
WHERE g.cartodb_id = 1
AND old_sca_report_with_units.name like 'Bay Street%'

/**Add in context area for early stage studies that have not yet defined rezoning boundaries**/

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.dcp_neighborhood_studies AS g
WHERE g.context = 'Bushwick'
AND old_sca_report_with_units.name like 'Bushwick%';

UPDATE capitalplanning.old_sca_report_with_units
SET the_geom = g.the_geom
FROM capitalplanning.dcp_neighborhood_studies AS g
WHERE g.context like 'Southern%'
AND old_sca_report_with_units.name like 'Southern%'

/**Add in study status and units**/

WITH recent AS (
SELECT the_geom, ulurpno, name, projected_units, build_year
FROM capitalplanning.old_sca_report_with_units
WHERE name LIKE 'Southern%'
OR name LIKE 'Bushwick%'
OR name LIKE 'Gowanus%'
OR name LIKE 'Inwood%'
OR name LIKE 'LIC Core%'
OR name LIKE 'Bay Street%')

INSERT INTO capitalplanning.cityled_projects (the_geom, ulurpno, project_na, projected_units, build_year)
SELECT the_geom, ulurpno, name, projected_units, build_year
FROM recent;

UPDATE capitalplanning.cityled_projects
SET status = (
CASE WHEN project_na like 'Inwood%' THEN 'Certified'
WHEN project_na LIKE 'LIC Core%' THEN 'Unconfirmed'
WHEN project_na LIKE 'Bushwick%' THEN 'Unconfirmed'
WHEN project_na LIKE 'Southern%' THEN 'Active Study'
WHEN project_na LIKE 'Gowanus%' THEN 'Active Study'
WHEN project_na LIKE 'Bay Street%' THEN 'Active Study' END);

UPDATE capitalplanning.cityled_projects
SET final_remaining_units = projected_units
WHERE project_id is null

/**Add in project id if available**/



