
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN HM.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS FavoriteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (SELECT PostId FROM Votes WHERE VoteTypeId = 5 GROUP BY PostId) HM ON P.Id = HM.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), HighPerformingUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        FavoriteCount,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM UserStatistics
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.UpVotes,
    U.DownVotes,
    U.FavoriteCount,
    HP.Rank
FROM UserStatistics U
JOIN HighPerformingUsers HP ON U.UserId = HP.UserId
WHERE HP.Rank <= 10 
ORDER BY HP.Rank;
