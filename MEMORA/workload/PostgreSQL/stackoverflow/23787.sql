
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.DisplayName
),
QuestionStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS QuestionCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        P.CreationDate
    FROM Posts P
    WHERE P.PostTypeId = 1  
    GROUP BY P.OwnerUserId, P.CreationDate
),
UserViewCounts AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(P.ViewCount), 0) AS TotalPostViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentVotingActivity AS (
    SELECT 
        V.UserId,
        COUNT(*) AS TotalVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY V.UserId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.Reputation,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    QS.QuestionCount,
    QS.TotalAnswers,
    QS.TotalViews,
    QS.AvgScore,
    UVC.TotalPostViews,
    RVA.TotalVotes,
    RVA.UpVotes,
    RVA.DownVotes
FROM UserBadges UB
LEFT JOIN QuestionStatistics QS ON UB.UserId = QS.OwnerUserId
LEFT JOIN UserViewCounts UVC ON UB.UserId = UVC.UserId
LEFT JOIN RecentVotingActivity RVA ON UB.UserId = RVA.UserId
WHERE (UB.BadgeCount > 0 OR QS.QuestionCount > 0)
AND (UVC.TotalPostViews > 100 OR RVA.TotalVotes > 0 OR UB.Reputation > 500)
ORDER BY UB.Reputation DESC, UB.BadgeCount DESC;
