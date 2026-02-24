
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
),
PostCommentSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(pcs.TotalComments, 0) AS TotalComments,
    pcs.LastCommentDate,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Question'
        WHEN rp.Rank <= 5 THEN 'High Interest'
        ELSE 'Low Interest'
    END AS InterestLevel
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostCommentSummary pcs ON rp.PostId = pcs.PostId
WHERE 
    ur.Reputation >= 1000 
ORDER BY 
    rp.ViewCount DESC,
    ur.Reputation DESC;
