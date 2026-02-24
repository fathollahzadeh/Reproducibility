WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.Score IS NOT NULL
),
PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        PopularPosts pp
    LEFT JOIN 
        PostComments pc ON pp.PostId = pc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.OwnerDisplayName,
    fr.CommentCount,
    CASE
        WHEN fr.Score > 50 THEN 'High Score'
        WHEN fr.Score BETWEEN 20 AND 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    FinalResults fr
WHERE 
    fr.CommentCount > 5
ORDER BY 
    fr.Score DESC,
    fr.PostId;
