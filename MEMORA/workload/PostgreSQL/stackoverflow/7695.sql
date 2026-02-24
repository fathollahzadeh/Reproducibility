
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31' 
        AND p.PostTypeId = 1   
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, b.BadgeCount
),
TopRanked AS (
    SELECT 
        rp.*, 
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS OverallRank 
    FROM 
        RankedPosts rp
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.CreationDate,
    tr.ViewCount,
    tr.Score,
    tr.CommentCount,
    tr.BadgeCount,
    CASE 
        WHEN tr.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    TopRanked tr
WHERE 
    tr.OverallRank <= 10
ORDER BY 
    tr.OverallRank;
