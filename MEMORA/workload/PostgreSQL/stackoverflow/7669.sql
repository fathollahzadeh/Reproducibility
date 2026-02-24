
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        AVG(P.Score) AS AvgPostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.QuestionCount,
        US.AnswerCount,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
        US.UpVotesReceived,
        US.DownVotesReceived,
        US.AvgPostScore
    FROM UserStats US
    LEFT JOIN BadgeCounts BC ON US.UserId = BC.UserId
)
SELECT 
    C.DisplayName,
    C.Reputation,
    C.PostCount,
    C.QuestionCount,
    C.AnswerCount,
    C.BadgeCount,
    C.GoldBadges,
    C.SilverBadges,
    C.BronzeBadges,
    C.UpVotesReceived,
    C.DownVotesReceived,
    C.AvgPostScore
FROM CombinedStats C
WHERE C.Reputation > 1000 
ORDER BY C.Reputation DESC, C.PostCount DESC
LIMIT 10;
