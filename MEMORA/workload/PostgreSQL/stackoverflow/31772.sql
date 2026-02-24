
WITH UserScoreSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserScoreSummary
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(C.CommentId), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN (SELECT DISTINCT PostId, Id AS CommentId FROM Comments) C ON P.Id = C.PostId
    WHERE P.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
AggregatedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM PostHistory PH
    GROUP BY PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.QuestionCount,
    U.AnswerCount,
    RPA.PostId,
    RPA.Title,
    RPA.CreationDate AS RecentPostDate,
    RPA.CommentCount,
    APH.HistoryCount AS EditHistoryCount,
    U.ReputationRank
FROM TopUsers U
LEFT JOIN RecentPostActivity RPA ON U.UserId = RPA.OwnerUserId
LEFT JOIN AggregatedPostHistory APH ON RPA.PostId = APH.PostId AND APH.PostHistoryTypeId IN (4, 5, 6) 
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, RPA.CreationDate DESC
LIMIT 10;
