WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(CASE WHEN P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN P.Score ELSE NULL END) AS AvgScoreLastYear
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
EligibleUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalBadges,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        AvgScoreLastYear
    FROM UserStats
    WHERE TotalViews > 1000 
    AND AvgScoreLastYear > 3
),
VotedPosts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY P.Id
)
SELECT 
    EU.UserId,
    EU.DisplayName,
    EU.Reputation,
    EU.TotalBadges,
    EU.QuestionCount,
    EU.AnswerCount,
    EU.TotalViews,
    EU.TotalScore,
    VP.PostId,
    VP.VoteCount,
    VP.UpVotes,
    VP.DownVotes
FROM EligibleUsers EU
JOIN VotedPosts VP ON EU.UserId = VP.PostId
ORDER BY EU.Reputation DESC, VP.VoteCount DESC
LIMIT 100;