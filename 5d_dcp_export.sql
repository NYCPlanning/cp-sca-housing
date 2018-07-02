/**Export to Excel with subdist distribution for sharing**/

SELECT
	c.project_id, c.project_name, c.project_description, c.applicant_type, c.project_status, c.process_stage, c.project_completed, c.certified_referred, 
	c.units AS projected_units, c.build_year AS projected_build_year,
    c.num_dob_jobs_matched, c.dob_u_matched, c.num_hpd_matched, c.incremental_hpd_u_matched, c.num_edc_matched, c.incremental_edc_u_matched, c.remaining_dcp_units,
	d.distzone::text AS geo_subdist, ROUND(d.final_pct_overlap,0) AS pct_in_subdist, ROUND(d.final_pct_overlap/100 * c.remaining_dcp_units,0) AS units_remaining_in_subdist,
    c.likely_to_be_built, c.rationale
FROM capitalplanning.all_possible_projects AS c
LEFT JOIN capitalplanning.dcp_subdist_distribute AS d
ON d.project_id = c.project_id
WHERE manual_exclude is null
AND final_pct_overlap > 0
ORDER BY project_id
