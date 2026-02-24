
WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS AuthorReputation,
        u.CreationDate AS AuthorCreationDate,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
        p.AnswerCount, p.CommentCount, p.FavoriteCount, 
        u.Reputation, u.CreationDate
)
SELECT 
    AVG(Score) AS AvgScore,
    AVG(ViewCount) AS AvgViewCount,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(FavoriteCount) AS AvgFavoriteCount,
    AVG(AuthorReputation) AS AvgAuthorReputation,
    MIN(AuthorCreationDate) AS EarliestAuthorCreationDate,
    MAX(CreationDate) AS MostRecentPostDate,
    COUNT(PostId) AS TotalPosts
FROM 
    BenchmarkData
