WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
CommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
BadgesEarned AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(be.TotalBadges, 0) AS TotalBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentsCount cc ON rp.PostId = cc.PostId
LEFT JOIN 
    BadgesEarned be ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = be.UserId)
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC;