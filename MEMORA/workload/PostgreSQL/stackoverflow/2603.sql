
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    us.Upvotes,
    us.Downvotes,
    COALESCE(phe.EditCount, 0) AS EditCount,
    phe.LastEditDate,
    us.BadgeCount,
    CASE 
        WHEN us.UserId IS NULL THEN 'Anonymous'
        ELSE 'User'
    END AS UserType
FROM 
    UserStats us
FULL OUTER JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryStats phe ON rp.Id = phe.PostId
WHERE 
    (rp.rn <= 5 OR rp.rn IS NULL) 
    AND (us.Upvotes - us.Downvotes) > 3
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
