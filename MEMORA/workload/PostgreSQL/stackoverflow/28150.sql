
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Body, u.DisplayName, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Body,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
        AND rp.ViewCount > 100 
        AND rp.AnswerCount < 5
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    SUBSTRING(fp.Body, 1, 200) AS BodySnippet
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC
LIMIT 10;
