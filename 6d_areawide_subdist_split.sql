/**Split units remaining by subdistrict based on pct spatial overlap**/

WITH unioned AS (
SELECT 
  	ST_Union(p.the_geom) AS the_geom, p.project_id, p.ulurpno, p.project_na
FROM 
capitalplanning.cityled_projects AS p
WHERE p.in_site_specific is null AND p.projected_units >= 200 OR project_id is null
GROUP BY p.project_id, p.ulurpno, p.project_na)

SELECT
  	p.project_id, p.ulurpno, p.project_na, b.distzone, 
ROUND(CAST(ST_Area(ST_Intersection(p.the_geom::geography,b.the_geom::geography))/ST_Area(p.the_geom::geography)*100 AS DECIMAL),0) AS pct_overlap
FROM 
unioned AS p,
dcpadmin.doe_schoolsubdistricts AS b
WHERE ST_Intersects(p.the_geom, b.the_geom)

--- Create new dataset from query as cityled_subdist_distribute
--- Check if any outside of subdistricts (for example, if polygon extends in water)
ALTER TABLE capitalplanning.cityled_subdist_distribute
ADD COLUMN temp_pct numeric,
ADD COLUMN temp_summed numeric,
ADD COLUMN final_pct_overlap numeric;

WITH summed AS (
SELECT project_na, SUM(pct_overlap) AS pct_overlap FROM capitalplanning.cityled_subdist_distribute
GROUP BY project_na)

UPDATE capitalplanning.cityled_subdist_distribute
SET temp_summed = summed.pct_overlap
FROM summed, capitalplanning.cityled_subdist_distribute AS d
WHERE cityled_subdist_distribute.project_na = summed.project_na;

update capitalplanning.cityled_subdist_distribute
set temp_pct = pct_overlap/temp_summed;
update capitalplanning.cityled_subdist_distribute
set final_pct_overlap = temp_pct * 100
