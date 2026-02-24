
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, u.Reputation, u.DisplayName
),
PostEngagement AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        OwnerReputation,
        OwnerDisplayName,
        TotalComments,
        (ViewCount + TotalComments + Score) AS EngagementScore 
    FROM 
        PostStats
)
SELECT 
    *,
    RANK() OVER (ORDER BY EngagementScore DESC) AS EngagementRank
FROM 
    PostEngagement
ORDER BY 
    EngagementScore DESC;
