
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 53) THEN 1 END) AS ReopenCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 6 THEN ph.CreationDate END) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
), UserReputation AS (
    SELECT 
        u.Id,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), ActiveUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName,
        u.Reputation + COALESCE(ur.TotalBadgePoints, 0) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY u.LastAccessDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.Id
    WHERE 
        u.LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    COALESCE(ph.CloseCount, 0) AS CloseCount,
    COALESCE(ph.DeleteCount, 0) AS DeleteCount,
    COALESCE(ph.ReopenCount, 0) AS ReopenCount,
    ph.LastEditDate,
    au.DisplayName AS ActiveUser,
    au.TotalReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregates ph ON rp.Id = ph.PostId
LEFT JOIN 
    ActiveUsers au ON au.TotalReputation >= 100
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC, 
    au.TotalReputation DESC
LIMIT 50;
