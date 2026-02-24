
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostsRanking,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
SuspiciousUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation < 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5 AND SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) > 2
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.TotalComments,
    pm.Upvotes,
    pm.Downvotes,
    pm.RecentPostsRanking,
    CASE 
        WHEN s.UserId IS NOT NULL THEN 'Suspicious User'
        ELSE 'Normal User'
    END AS UserStatus,
    pm.LastClosedDate,
    COALESCE(pm.Upvotes - pm.Downvotes, 0) AS NetVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = pm.OwnerUserId) AS BadgeCount
FROM 
    PostMetrics pm
LEFT JOIN 
    Users u ON pm.OwnerUserId = u.Id
LEFT JOIN 
    SuspiciousUsers s ON u.Id = s.UserId
WHERE 
    pm.TotalComments > 0
    AND (pm.Upvotes - pm.Downvotes) > 10
ORDER BY 
    NetVotes DESC,
    pm.TotalComments DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
