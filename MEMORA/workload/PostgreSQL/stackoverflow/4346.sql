
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 AND p.PostTypeId = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        pc.LatestCommentDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.UserPostRank <= 3 
)

SELECT 
    hsp.Id,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.CommentCount,
    CASE 
        WHEN hsp.LatestCommentDate IS NULL THEN 'No comments'
        ELSE 'Has comments'
    END AS CommentStatus
FROM 
    HighScoringPosts hsp
WHERE 
    hsp.Score > 10

UNION ALL

SELECT 
    NULL, 
    'Total High Scoring Posts', 
    NULL, 
    COUNT(*), 
    NULL, 
    NULL 
FROM 
    HighScoringPosts;
