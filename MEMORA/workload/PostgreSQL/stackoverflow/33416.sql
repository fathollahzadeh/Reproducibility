
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    WHERE 
        u.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS ChangeCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, ph.PostHistoryTypeId
)
SELECT 
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.Upvotes,
    u.DisplayName AS TopUser,
    ua.TotalPosts,
    ua.TotalBadges,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    phs.ChangeCount,
    STRING_AGG(DISTINCT pht.Name, ', ') AS Changes
FROM 
    RankedPosts ra
JOIN 
    RecentUserActivity ua ON ua.TotalPosts > 0 
JOIN 
    Users u ON u.Reputation = (SELECT MAX(Reputation) FROM Users) 
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = ra.PostId
LEFT JOIN 
    PostHistoryTypes pht ON pht.Id = phs.PostHistoryTypeId
WHERE 
    ra.Rank <= 5
GROUP BY 
    ra.PostId, ra.Title, ra.CreationDate, ra.Score, ra.Upvotes, u.DisplayName, ua.TotalPosts, ua.TotalBadges, ua.TotalUpvotes, ua.TotalDownvotes, phs.ChangeCount
ORDER BY 
    ra.Score DESC, ra.CreationDate DESC;
