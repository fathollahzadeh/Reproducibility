WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
PostViews AS (
    SELECT 
        p.Id,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(c.Id), 0) AS TotalComments,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        AVG(v.BountyAmount) AS AvgBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 10)  
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        p.CreationDate,
        p.LastActivityDate
    FROM PostHierarchy ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE p.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId = 10)  
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(cv.TotalBounty, 0) AS TotalBounty,
        cv.TotalComments,
        cv.UniqueVoters
    FROM Posts p
    LEFT JOIN PostViews cv ON p.Id = cv.Id
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.TotalBounty,
    pm.TotalComments,
    pm.UniqueVoters,
    ch.Level AS HierarchyLevel,
    CASE 
        WHEN pm.TotalComments = 0 THEN 'No Comments'
        WHEN pm.TotalComments > 10 THEN 'Highly Discussed'
        ELSE 'Moderately Discussed'
    END AS DiscussionLevel,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM PostMetrics pm
LEFT JOIN ClosedPosts ch ON pm.PostId = ch.PostId
LEFT JOIN Posts p ON pm.PostId = p.Id
ORDER BY pm.TotalBounty DESC, pm.UniqueVoters DESC;