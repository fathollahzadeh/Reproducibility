
WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
    HAVING COUNT(DISTINCT P.Id) > 10
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.ViewCount,
        RP.Score,
        SUM(V.BountyAmount) AS TotalBounties,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount
    FROM RecentPosts RP
    LEFT JOIN Votes V ON RP.PostId = V.PostId
    LEFT JOIN Comments C ON RP.PostId = C.PostId
    GROUP BY RP.PostId, RP.Title, RP.CreationDate, RP.OwnerDisplayName, RP.ViewCount, RP.Score
),
FinalReport AS (
    SELECT 
        TU.DisplayName AS TopUserName,
        TU.Reputation,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.Score,
        PS.TotalBounties,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount
    FROM TopUsers TU
    JOIN PostStatistics PS ON TU.UserId = PS.PostId
)
SELECT 
    * 
FROM FinalReport 
ORDER BY reputation DESC, ViewCount DESC;
