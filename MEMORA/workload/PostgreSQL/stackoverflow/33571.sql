
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END), 0) AS TotalQuestionViews,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount ELSE 0 END), 0) AS TotalAnswerViews,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyEarned
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        TotalQuestionViews,
        TotalAnswerViews,
        TotalBountyEarned,
        ROW_NUMBER() OVER (ORDER BY TotalQuestionViews DESC) AS RankByQuestions,
        ROW_NUMBER() OVER (ORDER BY TotalAnswerViews DESC) AS RankByAnswers
    FROM UserActivity
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    R.DisplayName,
    R.QuestionCount,
    R.AnswerCount,
    R.TotalQuestionViews,
    R.TotalAnswerViews,
    R.TotalBountyEarned,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    R.RankByQuestions,
    R.RankByAnswers
FROM RankedUsers R
LEFT JOIN UserBadges B ON R.UserId = B.UserId
WHERE R.TotalQuestionViews > 0 OR R.TotalAnswerViews > 0
ORDER BY R.RankByQuestions, R.RankByAnswers;
