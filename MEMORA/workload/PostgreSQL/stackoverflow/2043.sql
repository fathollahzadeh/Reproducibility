
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN TotalPosts = 0 THEN 'NoPosts' ELSE 'WithPosts' END ORDER BY Reputation DESC) AS PostRank
    FROM UserStats
),

RecentVotes AS (
    SELECT 
        V.PostId,
        V.UserId,
        V.CreationDate,
        vt.Name AS VoteTypeName,
        COUNT(*) OVER (PARTITION BY V.PostId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY V.PostId ORDER BY V.CreationDate DESC) AS RecentVoteRank
    FROM Votes V
    JOIN VoteTypes vt ON V.VoteTypeId = vt.Id
    WHERE V.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)

SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.Questions,
    T.Answers,
    T.AcceptedAnswers,
    T.AvgScore,
    T.TotalViews,
    R.VoteTypeName,
    R.VoteCount
FROM TopUsers T
LEFT JOIN RecentVotes R ON T.UserId = R.UserId AND R.RecentVoteRank <= 5
WHERE 
    T.ReputationRank <= 10 
    OR (T.TotalPosts = 0 AND T.Reputation > 100)
ORDER BY 
    T.ReputationRank, T.UserId;
