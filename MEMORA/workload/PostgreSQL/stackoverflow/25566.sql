
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS RankInLocation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND u.Location IS NOT NULL
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.Owner,
        t.TagName
    FROM 
        RankedPosts rp
    CROSS JOIN 
        (SELECT DISTINCT UNNEST(string_to_array(rp.Tags, '><')) AS TagName FROM RankedPosts) t 
    WHERE 
        rp.RankInLocation <= 5 
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        b.Date > DATE '2024-10-01' - INTERVAL '1 year' 
    GROUP BY 
        u.Id
)
SELECT 
    tp.Owner,
    tp.Title,
    tp.Tags,
    tp.Score,
    tp.CreationDate,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    TaggedPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    BadgeCounts bc ON tp.Owner = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
GROUP BY 
    tp.Owner, tp.Title, tp.Tags, tp.Score, tp.CreationDate, bc.TotalBadges
ORDER BY 
    tp.Score DESC, TotalBadges DESC
LIMIT 10;
