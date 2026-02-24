WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND 
        p.ViewCount > 100 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Body,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        STRING_AGG(c.Text, ' || ') AS CommentTexts 
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.AnswerCount,
        fp.CommentCount,
        pc.TotalComments,
        pc.CommentTexts,
        fp.OwnerDisplayName
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostComments pc ON fp.PostId = pc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.AnswerCount,
    fr.CommentCount,
    COALESCE(fr.TotalComments, 0) AS TotalComments,
    COALESCE(fr.CommentTexts, 'No comments') AS CommentTexts,
    fr.OwnerDisplayName
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 20;