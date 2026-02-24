WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
HighScoreComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentTexts
    FROM 
        Comments c
    JOIN 
        RankedPosts rp ON c.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        c.PostId
),
FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        hcc.CommentCount,
        hcc.CommentTexts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        HighScoreComments hcc ON rp.PostId = hcc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.OwnerDisplayName,
    COALESCE(fr.CommentCount, 0) AS CommentCount,
    COALESCE(fr.CommentTexts, 'No comments available') AS CommentTexts
FROM 
    FinalResult fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 10;