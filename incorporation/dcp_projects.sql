/**Identify which projects are rezonings (ZM)**/

SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action, count(CASE WHEN project_action_status = 'Active' THEN 1 END) AS action_status_active, count(CASE WHEN project_action_status = 'Certified' THEN 1 WHEN project_action_status = 'Referred' THEN 1 end) aS action_status_cert_ref, count(CASE WHEN project_action_status = 'Approved' THEN 1 END) AS action_status_approved
FROM capitalplanning.bx_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
UNION
SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action, count(CASE WHEN project_action_status = 'Active' THEN 1 END) AS action_status_active, count(CASE WHEN project_action_status = 'Certified' THEN 1 WHEN project_action_status = 'Referred' THEN 1 end) aS action_status_cert_ref, count(CASE WHEN project_action_status = 'Approved' THEN 1 END) AS action_status_approved
FROM capitalplanning.bK_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
UNION
SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action, count(CASE WHEN project_action_status = 'Active' THEN 1 END) AS action_status_active, count(CASE WHEN project_action_status = 'Certified' THEN 1 WHEN project_action_status = 'Referred' THEN 1 end) aS action_status_cert_ref, count(CASE WHEN project_action_status = 'Approved' THEN 1 END) AS action_status_approved
FROM capitalplanning.mn_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
UNION
SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action, count(CASE WHEN project_action_status = 'Active' THEN 1 END) AS action_status_active, count(CASE WHEN project_action_status = 'Certified' THEN 1 WHEN project_action_status = 'Referred' THEN 1 end) aS action_status_cert_ref, count(CASE WHEN project_action_status = 'Approved' THEN 1 END) AS action_status_approved
FROM capitalplanning.qn_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
UNION
SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action, count(CASE WHEN project_action_status = 'Active' THEN 1 END) AS action_status_active, count(CASE WHEN project_action_status = 'Certified' THEN 1 WHEN project_action_status = 'Referred' THEN 1 end) aS action_status_cert_ref, count(CASE WHEN project_action_status = 'Approved' THEN 1 END) AS action_status_approved
FROM capitalplanning.si_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
