
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    ur.TotalBadges,
    ph.CloseReopenCount,
    ph.DeleteCount,
    CASE 
        WHEN r.Score > 50 THEN 'High'
        WHEN r.Score BETWEEN 20 AND 50 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON ur.UserId = u.Id
LEFT JOIN 
    PostHistoryStats ph ON r.PostId = ph.PostId
WHERE 
    r.UserRank <= 3 
    AND (ph.CloseReopenCount > 1 OR ph.DeleteCount = 0)
ORDER BY 
    r.Score DESC, u.Reputation DESC;
