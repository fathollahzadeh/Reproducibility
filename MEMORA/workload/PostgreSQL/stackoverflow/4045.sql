WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*)
         FROM Comments c
         WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = u.Id)
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
      AND p.PostTypeId = 1
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score > 10 THEN 'High'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 OR (rp.CommentCount = 0 AND rp.Rank = 1)
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.BadgeClass,
    f.ScoreCategory
FROM 
    FilteredPosts f
LEFT JOIN 
    Votes v ON f.Id = v.PostId AND v.VoteTypeId = 2
WHERE 
    f.BadgeClass > 1
ORDER BY 
    f.Score DESC, 
    f.ViewCount ASC;