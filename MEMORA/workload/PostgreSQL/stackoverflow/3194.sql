WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(P.QuestionCount, 0) AS QuestionCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        U.Upvotes,
        U.Downvotes,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.TotalViews,
        P.LatestPostDate
    FROM UserStats U
    FULL OUTER JOIN PostStats P ON U.UserId = P.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    Views,
    PostCount,
    QuestionCount,
    AnswerCount,
    Upvotes,
    Downvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalViews,
    LatestPostDate,
    ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
FROM CombinedStats
WHERE (PostCount > 0 OR Upvotes > 0 OR GoldBadges > 0)
ORDER BY Reputation DESC, DisplayName;
