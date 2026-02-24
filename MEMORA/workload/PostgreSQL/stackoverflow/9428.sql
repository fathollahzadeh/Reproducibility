
WITH PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName
    HAVING 
        COUNT(c.Id) > 5
),
TopTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        pt.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.OwnerName,
    pp.CommentCount,
    tt.TagName
FROM 
    PopularPosts pp
JOIN 
    PostLinks pl ON pp.PostId = pl.PostId
JOIN 
    TopTags tt ON pl.RelatedPostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', tt.TagName, '%'))
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
