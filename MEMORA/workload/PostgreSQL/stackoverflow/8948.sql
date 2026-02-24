WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        ScoreRank,
        ViewRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10 OR ViewRank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.AnswerCount,
    trp.CommentCount,
    trp.OwnerDisplayName,
    (SELECT AVG(Score) FROM RankedPosts) AS AvgScore,
    (SELECT AVG(ViewCount) FROM RankedPosts) AS AvgViewCount,
    CASE 
        WHEN trp.Score > (SELECT AVG(Score) FROM RankedPosts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS ScoreComparison,
    CASE 
        WHEN trp.ViewCount > (SELECT AVG(ViewCount) FROM RankedPosts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS ViewComparison
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;