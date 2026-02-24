
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionsAsked,
        AnswersGiven,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    RU.ReputationRank,
    RU.DisplayName,
    RU.Reputation,
    RU.QuestionsAsked,
    RU.AnswersGiven,
    RU.UpVotesReceived,
    RU.DownVotesReceived,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(CAST(RP.CreationDate AS DATE), NULL) AS RecentPostDate,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    COALESCE(RP.ViewCount, 0) AS RecentPostViewCount
FROM RankedUsers RU
LEFT JOIN RecentPosts RP ON RU.DisplayName = RP.OwnerDisplayName
WHERE RU.Reputation > 1000
ORDER BY RU.ReputationRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
