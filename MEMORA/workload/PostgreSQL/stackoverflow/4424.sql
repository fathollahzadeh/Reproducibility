WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
PostWithBadges AS (
    SELECT 
        tp.Id,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id LIMIT 1)
)
SELECT 
    pwb.Id,
    pwb.Title,
    pwb.ViewCount,
    pwb.Score,
    pwb.BadgeName,
    'Total Posts in Last Year: ' || (SELECT COUNT(*) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year') AS TotalPosts,
    CASE 
        WHEN pwb.Score > 100 THEN 'Highly Rated'
        WHEN pwb.Score BETWEEN 51 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rating'
    END AS RatingCategory
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.ViewCount DESC
LIMIT 10;