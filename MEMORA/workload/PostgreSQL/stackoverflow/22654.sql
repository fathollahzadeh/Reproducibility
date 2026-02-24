
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '2 years'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    ua.DisplayName,
    ua.Reputation,
    ua.Upvotes,
    ua.Downvotes,
    COALESCE(c.CommentCount, 0) AS Comments,
    COALESCE(phd.HistoryDate, '1970-01-01 00:00:00') AS LastChange,
    CASE 
        WHEN phd.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN phd.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN phd.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'Active'
    END AS Status,
    (p.ViewCount * 1.0) / NULLIF((EXTRACT(EPOCH FROM CAST('2024-10-01 12:34:56' AS timestamp) - p.CreationDate) / 3600), 0) AS ViewsPerHour
FROM 
    RankedPosts p
JOIN 
    UserActivity ua ON p.OwnerUserId = ua.UserId
LEFT JOIN 
    CommentCounts c ON p.PostId = c.PostId
LEFT JOIN 
    PostHistoryDetails phd ON p.PostId = phd.PostId
WHERE 
    p.rn = 1 
    AND ua.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (LOWER(p.Title) LIKE '%sql%' OR p.Score > 5) 
ORDER BY 
    ViewsPerHour DESC 
LIMIT 10;
