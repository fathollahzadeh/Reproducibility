WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AveragePostScore,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN PostTypeId IN (4, 5) THEN 1 END) AS TotalTagWikis
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes
)

SELECT 
    PS.TotalPosts,
    PS.AveragePostScore,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.TotalTagWikis,
    US.TotalUsers,
    US.AverageReputation,
    CS.TotalComments,
    VS.TotalVotes,
    VS.TotalUpvotes,
    VS.TotalDownvotes
FROM 
    PostStats PS,
    UserStats US,
    CommentStats CS,
    VoteStats VS;