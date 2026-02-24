
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        AVG(P.Score) AS AvgPostScore,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT P.Tags) AS UniqueTagsUsed
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, PT.Name, P.OwnerUserId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.AvgPostScore,
    US.TotalPosts,
    US.UniqueTagsUsed,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.PostType,
    PS.CommentCount,
    PS.TotalBounty
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY US.TotalPosts DESC, US.AvgPostScore DESC;
