
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostsRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.ViewCount, p.Score, u.DisplayName, p.OwnerUserId
),
HighScoredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        ScoreRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank = 1 AND Score > 10  
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM
        RankedPosts
    WHERE 
        RecentPostsRank <= 10  
)
SELECT 
    H.PostId,
    H.Title AS HighScoreTitle,
    H.Body AS HighScoreBody,
    H.OwnerDisplayName AS HighScoreOwner,
    H.Score AS HighScore,
    R.Title AS RecentTitle,
    R.Body AS RecentBody,
    R.OwnerDisplayName AS RecentOwner,
    R.Score AS RecentScore
FROM 
    HighScoredPosts H
JOIN 
    RecentPosts R ON R.OwnerDisplayName = H.OwnerDisplayName 
ORDER BY 
    H.Score DESC, R.ViewCount DESC;
