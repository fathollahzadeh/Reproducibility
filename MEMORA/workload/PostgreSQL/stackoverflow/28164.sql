WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score, p.ViewCount, u.DisplayName
),

MostCommentedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Tags, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM 
        RankedPosts
)

SELECT 
    mp.PostId,
    mp.Title,
    mp.Tags,
    mp.Score,
    mp.ViewCount,
    mp.OwnerDisplayName,
    mp.CommentCount,
    CASE 
        WHEN mp.CommentRank <= 10 THEN 'Most Commented'
        ELSE 'Less Commented'
    END AS CommentStatus,
    RANK() OVER (ORDER BY mp.Score) AS ScoreRank,
    RANK() OVER (ORDER BY mp.ViewCount) AS ViewRank
FROM 
    MostCommentedPosts mp
WHERE 
    mp.CommentCount > 0
ORDER BY 
    CommentCount DESC,
    Score DESC;