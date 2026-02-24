
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        LAST_VALUE(Reputation) OVER (PARTITION BY Id ORDER BY CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS FinalReputation
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty  
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),
PostMetrics AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount,
        COALESCE(c.Count, 0) AS TagCount,
        COALESCE(ur.Reputation, 0) AS UserReputation,
        rp.CommentCount,
        rp.TotalBounty
    FROM RecentPosts rp
    LEFT JOIN Tags t ON t.ExcerptPostId = rp.PostId
    LEFT JOIN UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
    LEFT JOIN (SELECT PostId, COUNT(*) AS Count FROM Tags GROUP BY PostId) c ON c.PostId = rp.PostId
)
SELECT 
    pm.PostId, 
    pm.Title, 
    pm.CreationDate, 
    pm.ViewCount, 
    pm.TagCount, 
    pm.UserReputation, 
    pm.CommentCount, 
    pm.TotalBounty,
    CASE 
        WHEN pm.CommentCount > 10 THEN 'High Engagement'
        WHEN pm.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN pm.ViewCount > 1000 THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity,
    NULLIF(pm.TotalBounty, 0) AS BountyAmount
FROM PostMetrics pm
WHERE pm.UserReputation > 1000
ORDER BY pm.ViewCount DESC, pm.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
