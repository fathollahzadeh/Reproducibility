
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY P.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ClosedPostCount,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.UserId
),
FinalStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UV.VoteCount, 0) AS TotalVotes,
        COALESCE(RP.QuestionCount, 0) AS TotalQuestions,
        COALESCE(RP.AnswerCount, 0) AS TotalAnswers,
        COALESCE(CP.ClosedPostCount, 0) AS TotalClosedPosts,
        COALESCE(CP.FirstCloseDate, '1970-01-01') AS FirstClosedDate,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes,
        COALESCE(RP.AverageScore, 0) AS AverageScore
    FROM Users U
    LEFT JOIN UserVoteStats UV ON U.Id = UV.UserId
    LEFT JOIN RecentPostStats RP ON U.Id = RP.OwnerUserId
    LEFT JOIN ClosedPostStats CP ON U.Id = CP.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalVotes,
    TotalQuestions,
    TotalAnswers,
    TotalClosedPosts,
    FirstClosedDate,
    UpVotes,
    DownVotes,
    AverageScore
FROM FinalStats
WHERE TotalVotes > 10 
    OR (TotalQuestions > 5 AND AverageScore > 0)
ORDER BY TotalVotes DESC, FirstClosedDate ASC
LIMIT 100;
