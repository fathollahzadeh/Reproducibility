
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostsCount,
        COALESCE(SUM(COALESCE(P.Score, 0)), 0) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesCount,
        DownVotesCount,
        PostsCount,
        TotalScore,
        RANK() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS UserRank
    FROM UserMetrics
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UserRank
    FROM UserRankings
    WHERE UserRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(V.UpVotesCount, 0) AS TotalUpVotes,
        COALESCE(V.DownVotesCount, 0) AS TotalDownVotes,
        P.Score AS PostScore,
        P.OwnerUserId
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
)
SELECT 
    T.UserRank,
    T.DisplayName,
    TD.Title,
    TD.CreationDate,
    TD.TotalUpVotes,
    TD.TotalDownVotes,
    TD.PostScore
FROM TopUsers T
JOIN PostDetails TD ON T.UserId = TD.OwnerUserId
ORDER BY T.UserRank, TD.TotalUpVotes DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
