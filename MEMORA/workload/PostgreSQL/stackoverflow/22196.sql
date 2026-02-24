
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL AND U.Reputation > 0
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(ROUND(CAST(P.ViewCount AS FLOAT) / NULLIF(P.AnswerCount, 0), 2), 0) AS ViewPerAnswer,
        P.CreationDate,
        MIN(P.CreationDate) OVER (PARTITION BY P.OwnerUserId) AS FirstPostDate,
        P.OwnerUserId
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE PH.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ',') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
PostActivity AS (
    SELECT 
        P.Id,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    P.Title,
    P.ViewPerAnswer,
    P.FirstPostDate,
    COALESCE(CP.CloseReason, 'N/A') AS CloseReason,
    UA.BadgeCount,
    UA.BadgeNames,
    PA.UpVotes,
    PA.DownVotes,
    PA.CommentCount
FROM UserReputation U
LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN ClosedPosts CP ON P.PostId = CP.PostId
LEFT JOIN UserBadges UA ON U.UserId = UA.UserId
LEFT JOIN PostActivity PA ON P.PostId = PA.Id
WHERE U.ReputationRank <= 100 
AND (P.ViewPerAnswer IS NOT NULL OR P.ViewPerAnswer > 0) 
ORDER BY U.Reputation DESC, P.ViewPerAnswer DESC NULLS LAST;
