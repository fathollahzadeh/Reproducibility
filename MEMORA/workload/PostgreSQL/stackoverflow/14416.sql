WITH PostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
UserPerformance AS (
    SELECT 
        UserId,
        PostCount,
        CommentCount,
        VoteCount,
        (PostCount + CommentCount + VoteCount) AS TotalEngagement
    FROM 
        PostStats
)
SELECT 
    UserId,
    PostCount,
    CommentCount,
    VoteCount,
    TotalEngagement
FROM 
    UserPerformance
ORDER BY 
    TotalEngagement DESC;