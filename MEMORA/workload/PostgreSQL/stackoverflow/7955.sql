
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(tg.TagName, 'No Tags') AS TagName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         pt.Id AS PostId,
         STRING_AGG(t.TagName, ', ') AS TagName
     FROM 
         Posts pt
     JOIN 
         UNNEST(string_to_array(pt.Tags, ',')) AS tag ON TRUE
     JOIN 
         Tags t ON t.TagName = tag
     GROUP BY 
         pt.Id) tg ON tp.PostId = tg.PostId
LEFT JOIN 
    (SELECT 
         UserId, COUNT(*) AS BadgeCount
     FROM 
         Badges
     GROUP BY 
         UserId) b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Users.Id = b.UserId)
ORDER BY 
    tp.Score DESC;
