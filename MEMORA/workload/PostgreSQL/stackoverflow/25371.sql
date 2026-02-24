WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND pt.Name = 'Question'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.OwnerName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    fp.Title,
    LEFT(fp.Body, 200) AS ShortBody,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerName,
    fp.CommentCount,
    string_agg(t.TagName, ', ') AS TagsList
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT 
         Id, 
         unnest(string_to_array(Tags, '><')) AS TagName 
     FROM 
         Posts) t ON t.Id = fp.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.ViewCount, fp.Score, fp.OwnerName, fp.CommentCount
ORDER BY 
    fp.Score DESC;