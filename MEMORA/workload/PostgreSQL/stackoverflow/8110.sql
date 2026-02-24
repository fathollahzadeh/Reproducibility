WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        RankScore <= 5
),
PostAggregates AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM 
        TopPosts
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    p.OwnerDisplayName,
    p.PostCount,
    p.TotalScore,
    p.TotalViews,
    p.TotalAnswers,
    p.TotalComments,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId IN (SELECT Id FROM TopPosts) AND v.VoteTypeId = 2) AS TotalUpvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId IN (SELECT Id FROM TopPosts) AND v.VoteTypeId = 3) AS TotalDownvotes
FROM 
    PostAggregates p
ORDER BY 
    p.TotalScore DESC, 
    p.TotalViews DESC;