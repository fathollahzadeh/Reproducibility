
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.ID) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR')
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
),
TopUsers AS (
    SELECT 
        UM.UserId,
        UM.DisplayName,
        UM.Reputation,
        ROW_NUMBER() OVER (ORDER BY UM.Reputation DESC, UM.TotalPosts DESC) AS Rank
    FROM UserMetrics UM
    WHERE UM.TotalPosts > 10
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViews,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes
FROM TopUsers TU
JOIN PostEngagement P ON TU.UserId = P.PostId
WHERE P.Score > 5
ORDER BY TU.Rank, P.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
