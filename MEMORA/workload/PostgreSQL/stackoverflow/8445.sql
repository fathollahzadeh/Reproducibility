WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), PopularPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE Rank <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.VoteCount,
    COALESCE(t.TagName, 'No Tags') AS TagName
FROM 
    PopularPosts pp
    LEFT JOIN (
        SELECT 
            pt.Id,
            STRING_AGG(t.TagName, ', ') AS TagName
        FROM 
            Posts pt
            JOIN Tags t ON pt.Tags LIKE '%' || t.TagName || '%'
        GROUP BY 
            pt.Id
    ) t ON pp.PostId = t.Id
ORDER BY 
    pp.VoteCount DESC, pp.CommentCount DESC;