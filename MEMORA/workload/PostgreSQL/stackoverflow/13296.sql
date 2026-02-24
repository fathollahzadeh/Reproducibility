
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.OwnerUserId
    FROM Posts P
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalBounties,
    U.UpVotes,
    U.DownVotes,
    COUNT(DISTINCT PS.PostId) AS ActivePostCount,
    AVG(PS.Score) AS AveragePostScore,
    SUM(PS.ViewCount) AS TotalPostViews
FROM UserStats U
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
GROUP BY U.UserId, U.DisplayName, U.PostCount, U.TotalBounties, U.UpVotes, U.DownVotes
ORDER BY U.UserId;
