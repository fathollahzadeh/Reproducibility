WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    PCT.PostTypeId,
    PCT.TotalPosts,
    PCT.TotalAcceptedAnswers,
    US.UserId,
    US.Reputation,
    US.PostsCount,
    US.TotalBounties
FROM 
    PostCounts PCT
JOIN 
    UserStats US ON US.PostsCount > 0
ORDER BY 
    PCT.TotalPosts DESC, 
    US.Reputation DESC;