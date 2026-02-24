WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate,
        COUNT(h.Id) AS HistoryCount,
        STRING_AGG(h.Comment, '; ') AS UserComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory h ON rp.PostId = h.PostId
    WHERE 
        rp.UserRank <= 3 
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CommentCount, rp.CreationDate
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.Tags,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.CreationDate,
    pp.HistoryCount,
    pp.UserComments,
    pt.TagName AS PopularTag,
    pt.PostCount AS PopularTagPostCount
FROM 
    TopPosts pp
JOIN 
    PopularTags pt ON pp.Tags LIKE '%' || pt.TagName || '%'
ORDER BY 
    pp.Score DESC, pp.CreationDate DESC
LIMIT 50;