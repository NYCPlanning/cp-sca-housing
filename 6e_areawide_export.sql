/**Export to Excel for sharing**/

WITH projects AS (
SELECT 
	c.project_id, c.ulurpno, c.project_na AS project_name, project_description, applicant_type, status, effective AS effective_date, projected_units, build_year AS projected_build_year, final_dob_u_matched as dob_u_matched, final_incremental_hpd_u_matched AS incremental_hpd_u_matched, final_incremental_edc_u_matched AS incremental_edc_u_matched, final_incremental_dcp_u_matched AS incremental_dcp_u_matched, final_remaining_units AS remaining_units,
    d.distzone AS geo_subdist
FROM capitalplanning.cityled_projects AS c, capitalplanning.cityled_subdist_distribute AS d
WHERE c.project_na = d.project_na
AND (projected_units is not null AND in_site_specific is null) OR c.project_id is null
ORDER BY effective ASC),

joined AS (
SELECT projects.*, d.final_pct_overlap AS pct_in_subdist
FROM projects
LEFT JOIN capitalplanning.cityled_subdist_distribute AS d ON projects.project_name = d.project_na AND projects.geo_subdist = d.distzone)

SELECT * FROM joined WHERE pct_in_subdist > 0
