WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedOrReopenedDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.CreationDate, p.Score, p.Title, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.CreationDate,
        rp.Score,
        rp.Title,
        rp.OwnerUserId,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN rp.ClosedOrReopenedDate IS NOT NULL AND rp.ClosedOrReopenedDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
            THEN 'Closed Recently'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.PostStatus,
    ur.Reputation,
    ur.BadgeCount
FROM 
    FilteredPosts fp
JOIN 
    UserReputation ur ON fp.OwnerUserId = ur.UserId
WHERE 
    (fp.Score > 10 OR fp.CommentCount > 5)  
    AND ur.BadgeCount > 0  
    AND ur.Reputation > 100  
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;