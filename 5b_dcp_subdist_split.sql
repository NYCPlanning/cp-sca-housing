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
