WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        PositiveScorePosts,
        NegativeScorePosts,
        Questions,
        Answers,
        CommentsCount,
        LastPostDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.PositiveScorePosts,
    T.NegativeScorePosts,
    T.Questions,
    T.Answers,
    T.CommentsCount,
    T.LastPostDate,
    ROW_NUMBER() OVER (PARTITION BY T.ReputationRank ORDER BY T.LastPostDate DESC) AS PostRecencyRank
FROM TopUsers T
WHERE T.ReputationRank <= 10
ORDER BY T.Reputation DESC, T.LastPostDate DESC;
