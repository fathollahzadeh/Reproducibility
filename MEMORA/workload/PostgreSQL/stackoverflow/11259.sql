WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(COALESCE(CLOSED.Rate, 0)) AS ClosedPostRate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Rate
        FROM PostHistory
        WHERE PostHistoryTypeId = 10 
        GROUP BY PostId
    ) AS CLOSED ON P.Id = CLOSED.PostId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVoteCount,
    DownVoteCount,
    ClosedPostRate
FROM UserActivity
WHERE PostCount > 10
ORDER BY PostCount DESC;