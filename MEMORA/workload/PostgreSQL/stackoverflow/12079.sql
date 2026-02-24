
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalComments,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
        p.AnswerCount, p.CommentCount, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerReputation,
        TotalComments,
        AvgBountyAmount,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS RankByViews
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerReputation,
    TotalComments,
    AvgBountyAmount,
    RankByScore,
    RankByViews
FROM 
    TopPosts
WHERE 
    RankByScore <= 10 OR RankByViews <= 10
ORDER BY 
    RankByScore, RankByViews;
