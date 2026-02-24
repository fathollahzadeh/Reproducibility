WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        AVG(COALESCE(CAST(P.Score AS FLOAT) / NULLIF(P.ViewCount, 0), 0)) AS AvgScorePerView,
        MAX(P.CreationDate) AS LastActivityDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalBounty,
    UA.AvgScorePerView,
    UA.LastActivityDate,
    U.Reputation
FROM UserActivity UA
JOIN Users U ON UA.UserId = U.Id
ORDER BY UA.PostCount DESC
LIMIT 100;