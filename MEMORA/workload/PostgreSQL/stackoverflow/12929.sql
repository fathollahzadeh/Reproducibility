WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.UpVotes, U.DownVotes, U.Views
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.CommentCount) AS AvgComments
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.Views,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COALESCE(P.QuestionCount, 0) AS QuestionCount,
    COALESCE(P.AnswerCount, 0) AS AnswerCount,
    COALESCE(P.TotalScore, 0) AS TotalScore,
    COALESCE(P.TotalViews, 0) AS TotalViews,
    COALESCE(P.AvgComments, 0) AS AvgComments
FROM UserStats U
LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC;