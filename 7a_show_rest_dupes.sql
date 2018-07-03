/**Integrate all DOB, HPD, EDC, DCP excl cityled areawide into 1 single dataset**/
-- Create empty dataset

ALTER TABLE capitalplanning.merged_site_specific_developments
ADD COLUMN unique_id text,
ADD COLUMN id_type text,
ADD COLUMN project_source text,
ADD COLUMN project_name text,
ADD COLUMN project_description text,
ADD COLUMN project_status text,
ADD COLUMN total_units numeric,
ADD COLUMN projected_build_year numeric,
ADD COLUMN dob_job_matched numeric,
ADD COLUMN dob_u_net numeric,
ADD COLUMN hpd_matched text,
ADD COLUMN hpd_u_total numeric,
ADD COLUMN hpd_u_increm numeric,
ADD COLUMN edc_matched numeric,
ADD COLUMN edc_u_increm numeric,
ADD COLUMN u_remaining numeric,
ADD COLUMN project_start numeric,
ADD COLUMN project_start_type text,
ADD COLUMN project_completion numeric,
ADD COLUMN project_completion_type text,
ADD COLUMN dcp_u_likely_to_be_built text,
ADD COLUMN dcp_u_rationale text,
ADD COLUMN project_address text

/**Add in DCP deduping**/
WITH dob AS (
SELECT i.unique_id, i.project_name, d.dob_job_number, d.dcp_status, d.address, d.u_net, d.u_net_complete + d.u_net_incomplete AS u_net_summed, d.c_date_latest
FROM
  capitalplanning.merged_site_specific_developments AS i
LEFT JOIN
  capitalplanning.dcp_dob_dedupe AS d
ON i.unique_id = d.project_id),

hpd AS (


INSERT INTO 


/**Add in all DCP projects**/
INSERT INTO capitalplanning.merged_site_specific_developments (unique_id, project_name, project_description, project_status, total_units, projected_build_year, dcp_u_likely_to_be_built, dcp_u_rationale)
SELECT i.project_id, project_name, project_description, project_status, units, build_year, likely_to_be_built, rationale
FROM capitalplanning.all_possible_projects AS i
WHERE i.manual_exclude is null
