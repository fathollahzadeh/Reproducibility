WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        UPPER(CONCAT(u.DisplayName, ' - ', CAST(u.Reputation AS VARCHAR))) AS UserInfo
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.UserInfo,
    COALESCE(cph.CloseCount, 0) AS TotalClosed,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'Highly Commented'
        WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Commented'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN ur.BadgeCount > 0 THEN 'Awarded Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPostHistory cph ON rp.PostId = cph.PostId
WHERE 
    ur.Reputation BETWEEN 100 AND 500 
    AND (rp.Score IS NULL OR rp.Score > 10) 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;