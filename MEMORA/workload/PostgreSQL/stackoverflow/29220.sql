
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank = 1
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.CommentCount,
    tp.PopularityRank,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    TopPosts tp
LEFT JOIN 
    PostLinks pl ON pl.PostId = tp.PostId
LEFT JOIN 
    Posts related ON pl.RelatedPostId = related.Id
LEFT JOIN 
    Tags t ON related.Id = t.ExcerptPostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.OwnerDisplayName, tp.AnswerCount, tp.CommentCount, tp.PopularityRank
ORDER BY 
    tp.PopularityRank;
