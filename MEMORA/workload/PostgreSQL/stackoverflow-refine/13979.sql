WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    BadgeCount,
    TotalVotes,
    TotalComments
FROM 
    UserStats
WHERE 
    PostCount > 0
ORDER BY 
    Reputation DESC, TotalVotes DESC
LIMIT 100;