
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgPostScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes V
    WHERE V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY V.UserId
),
CombinedStats AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(RV.VoteCount, 0) AS VoteCount,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PS.AvgPostScore,
        PS.TotalViewCount,
        PS.QuestionCount,
        PS.AnswerCount
    FROM UserBadges UB
    LEFT JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
    LEFT JOIN RecentVotes RV ON UB.UserId = RV.UserId
),
RankedStats AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, VoteCount DESC, BadgeCount DESC) AS Rank
    FROM CombinedStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    VoteCount,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    AvgPostScore,
    TotalViewCount,
    QuestionCount,
    AnswerCount,
    Rank
FROM RankedStats
WHERE (PostCount + VoteCount) > 0
AND (BadgeCount > 0 OR TotalViewCount > 100)
ORDER BY Rank
LIMIT 10;
