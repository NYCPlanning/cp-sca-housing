/**Calculate proportion of project in subdistrict in order to split units remaining by subdist**/

SELECT 
  	p.the_geom, p.the_geom_webmercator, p.project_id, p.project_name, b.distzone, 
ROUND(CAST(ST_Area(ST_Intersection(p.the_geom::geography,b.the_geom::geography))/ST_Area(p.the_geom::geography)*100 AS DECIMAL),0) AS pct_overlap
FROM 
capitalplanning.all_possible_projects AS p,
dcpadmin.doe_schoolsubdistricts AS b
WHERE ST_Intersects(p.the_geom, b.the_geom)
AND manual_exclude is null
ORDER BY project_id, pct_overlap

-- Create new dataset from query as dcp_subdist_distribute

ALTER TABLE capitalplanning.dcp_subdist_distribute
ADD COLUMN temp_pct numeric,
ADD COLUMN temp_sum numeric,
ADD COLUMN final_pct_overlap numeric;

-- Check if any outside of subdistricts (for example, if DCP polygon extends in water)

WITH summed as (
SELECT project_id, project_name, SUM(pct_overlap) AS pct_overlap FROM capitalplanning.dcp_subdist_distribute
GROUP BY project_id, project_name
ORDER BY pct_overlap ASC)

update capitalplanning.dcp_subdist_distribute
set temp_sum = summed.pct_overlap
from summed where dcp_subdist_distribute.project_id = summed.project_id;

update capitalplanning.dcp_subdist_distribute
set temp_pct = pct_overlap/temp_sum;

update capitalplanning.dcp_subdist_distribute
set final_pct_overlap = decimal(temp_pct * 100,0)
