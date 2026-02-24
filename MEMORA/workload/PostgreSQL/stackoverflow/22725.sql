
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryMetrics AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '6 months'
    AND 
        ph.PostHistoryTypeId IN (10, 11, 12)
),
CombinedMetrics AS (
    SELECT 
        ra.PostId,
        ra.Title,
        ra.CreationDate,
        ua.UserId,
        ua.DisplayName,
        ra.PostRank,
        ra.CommentCount,
        COALESCE(pm.PostHistoryTypeId, 0) AS RecentActivity,
        ua.TotalBounties,
        ua.TotalPosts,
        ua.TotalBadges
    FROM 
        RankedPosts ra
    LEFT JOIN 
        UserActivity ua ON ra.OwnerUserId = ua.UserId
    LEFT JOIN 
        PostHistoryMetrics pm ON ra.PostId = pm.PostId
)
SELECT 
    cm.PostId,
    cm.Title,
    cm.CreationDate,
    cm.DisplayName AS Owner,
    cm.CommentCount,
    CASE WHEN cm.PostRank = 1 THEN 'Most Recent Post' ELSE 'Older Post' END AS PostClassification,
    COUNT(DISTINCT ul.UserId) AS UniqueLikers,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalLikes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDislikes
FROM 
    CombinedMetrics cm
LEFT JOIN 
    Votes v ON v.PostId = cm.PostId
LEFT JOIN 
    (SELECT DISTINCT UserId FROM Votes WHERE VoteTypeId = 2) ul ON ul.UserId = v.UserId
WHERE 
    cm.TotalBadges >= 3
GROUP BY 
    cm.PostId, cm.Title, cm.CreationDate, cm.DisplayName, cm.PostRank, cm.CommentCount
ORDER BY 
    cm.CreationDate DESC, cm.PostRank
LIMIT 100 OFFSET 0;
