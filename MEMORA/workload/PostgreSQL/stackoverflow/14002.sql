
WITH UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, P.Id, P.Title, P.CreationDate, P.Score
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    COUNT(DISTINCT PostId) AS TotalPosts,
    SUM(PostScore) AS TotalPostScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes,
    SUM(BadgeCount) AS TotalBadges
FROM 
    UserPostDetails
GROUP BY 
    UserId, DisplayName, Reputation
ORDER BY 
    TotalPosts DESC, TotalPostScore DESC
LIMIT 100;
