
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON POSITION(',' || t.TagName || ',' IN ',' || p.Tags || ',') > 0
    WHERE 
        p.CreationDate >= DATE '2023-01-01' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.Tags,
        rp.RankByScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.ViewCount,
    fp.CommentCount,
    fp.VoteCount,
    fp.Tags,
    fp.CreationDate,
    REPLACE(REPLACE(REPLACE(fp.Body, '<p>', ''), '</p>', ''), '<br>', '') AS CleanedBody
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;
