
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount
    FROM Posts P
    WHERE P.LastActivityDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') 
)
SELECT 
    TC.DisplayName,
    TC.Reputation,
    TC.PostCount,
    TC.QuestionCount,
    TC.AnswerCount,
    TC.UpVoteCount,
    TC.DownVoteCount,
    TC.BadgeCount,
    AP.PostId,
    AP.Title,
    AP.CreationDate,
    AP.LastActivityDate,
    AP.ViewCount,
    AP.AnswerCount,
    AP.CommentCount
FROM TopContributors TC
JOIN ActivePosts AP ON TC.UserId = AP.OwnerUserId
WHERE TC.Rank <= 10
ORDER BY TC.Reputation DESC, AP.LastActivityDate DESC;
