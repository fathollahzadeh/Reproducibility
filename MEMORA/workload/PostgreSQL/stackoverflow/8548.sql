
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(EXTRACT(EPOCH FROM NOW() - P.CreationDate) / 60) AS AvgPostAgeMinutes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
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
PostInteractionCounts AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Votes V
    GROUP BY V.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.PostCount,
    US.Questions,
    US.Answers,
    US.AvgPostAgeMinutes,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    COALESCE(BC.GoldBadges, 0) AS GoldBadges,
    COALESCE(BC.SilverBadges, 0) AS SilverBadges,
    COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PC.VoteCount, 0) AS VoteCount,
    COALESCE(PC.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(PC.DownVotesCount, 0) AS DownVotesCount
FROM UserStats US
LEFT JOIN BadgeCounts BC ON US.UserId = BC.UserId
LEFT JOIN PostInteractionCounts PC ON US.UserId = PC.UserId
ORDER BY US.Reputation DESC, US.PostCount DESC
LIMIT 50;
