
WITH RecursiveTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags AS t
    JOIN 
        Posts AS p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(p.Id) > 0
),
RankedTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        RecursiveTagCounts
),
PopularPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts AS p
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    JOIN 
        Tags AS t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.ViewCount,
        pp.Score,
        pp.CommentCount,
        pp.Tags,
        RANK() OVER (ORDER BY pp.ViewCount DESC) AS PostRank
    FROM 
        PopularPosts AS pp
)
SELECT 
    rt.TagName,
    rt.PostCount,
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount
FROM 
    RankedTags AS rt
JOIN 
    TopPosts AS tp ON tp.Tags LIKE CONCAT('%', rt.TagName, '%')
WHERE 
    rt.TagRank <= 10
ORDER BY 
    rt.TagRank,
    tp.ViewCount DESC;
