WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AnswerCount, 
        u.DisplayName AS OwnerName,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
), 
PostTags AS (
    SELECT 
        p.Id AS PostId, 
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p 
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
), 
PostComments AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) 
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CreationDate,
    rp.Score,
    rp.ScoreRank,
    COALESCE(pt.Tags, 'No Tags') AS Tags,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.ScoreRank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC;