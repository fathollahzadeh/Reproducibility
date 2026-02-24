
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes,
    (TotalUpvotes - TotalDownvotes) AS NetVotes,
    CASE 
        WHEN TotalPosts = 0 THEN 0
        ELSE (TotalComments * 1.0 / TotalPosts) 
    END AS CommentPerPostRatio
FROM 
    UserEngagement
ORDER BY 
    TotalPosts DESC;
