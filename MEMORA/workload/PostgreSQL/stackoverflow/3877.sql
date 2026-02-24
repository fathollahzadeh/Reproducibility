WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END), 0) AS WikiCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT *,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank
    FROM UserStats
),
ClosedPosts AS (
    SELECT 
        DISTINCT P.Id AS ClosedPostId, 
        PH.UserId AS CloserUserId,
        CRT.Name AS CloseReason
    FROM PostHistory PH 
    JOIN CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS varchar)
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.QuestionCount,
    RU.AnswerCount,
    RU.WikiCount,
    RU.CommentCount,
    RU.TotalBounties,
    CP.ClosedPostId,
    CP.CloseReason
FROM RankedUsers RU
LEFT JOIN ClosedPosts CP ON RU.UserId = CP.CloserUserId
WHERE RU.Reputation > 1000 AND RU.QuestionCount > 5
ORDER BY RU.Reputation DESC, RU.QuestionCount DESC
FETCH FIRST 50 ROWS ONLY;
