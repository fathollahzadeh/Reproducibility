WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown User'
            ELSE u.DisplayName
        END AS UserDisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.UserDisplayName,
        COUNT(rp.PostId) AS ActivePostCount
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.UserId = rp.PostId
    GROUP BY 
        ur.UserId, ur.UserDisplayName
)
SELECT 
    au.UserDisplayName,
    au.ActivePostCount,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
FROM 
    ActiveUsers au
LEFT JOIN 
    Posts p ON au.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    (p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' OR p.CreationDate IS NULL)
GROUP BY 
    au.UserDisplayName, au.ActivePostCount
HAVING 
    COUNT(p.Id) > 5
ORDER BY 
    ActivePostCount DESC
LIMIT 10;