WITH UsersReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate, 
        LastAccessDate 
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.PostTypeId, 
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount, 
        COUNT(DISTINCT V.Id) AS VoteCount, 
        AVG(V.BountyAmount) AS AvgBountyAmount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.PostTypeId
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
)
SELECT 
    U.UserId, 
    U.Reputation, 
    U.CreationDate, 
    U.LastAccessDate, 
    PS.TotalPosts, 
    PS.TotalViews, 
    PS.AvgScore, 
    PST.PostId, 
    PST.PostTypeId, 
    PST.CommentCount, 
    PST.VoteCount, 
    PST.AvgBountyAmount
FROM UsersReputation U
JOIN UserPosts PS ON U.UserId = PS.UserId
JOIN PostStats PST ON PS.UserId = PST.PostId
ORDER BY U.Reputation DESC, PS.TotalPosts DESC;