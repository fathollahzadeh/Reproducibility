WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(ptv.Reputation) AS AverageReputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Users ptv ON p.OwnerUserId = ptv.Id
    GROUP BY u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId AS EditorUserId,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5) 
),
PostMetrics AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(MAX(pa.EditDate), pa.CreationDate) AS LastEditDate,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedLinks,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM PostActivity pa
    LEFT JOIN Comments c ON pa.PostId = c.PostId
    LEFT JOIN PostLinks pl ON pa.PostId = pl.PostId
    LEFT JOIN PostHistory ph ON pa.PostId = ph.PostId
    GROUP BY pa.PostId, pa.Title, pa.CreationDate
)
SELECT 
    us.DisplayName,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalBounty,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.CommentCount,
    pm.LastEditDate,
    pm.RelatedLinks,
    pm.CloseCount
FROM UserScoreSummary us
JOIN PostMetrics pm ON us.UserId = pm.PostId
ORDER BY us.TotalUpvotes DESC, pm.CommentCount DESC
LIMIT 100;