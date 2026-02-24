
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(CASE WHEN P.PostTypeId = 1 THEN P.Score END) AS AvgQuestionScore,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalViews,
        QuestionCount,
        AnswerCount,
        AvgQuestionScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalViews DESC) AS Rank
    FROM UserActivity
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedCount
    FROM PostLinks PL
    WHERE PL.CreationDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY PL.PostId
)

SELECT
    AU.DisplayName,
    AU.Reputation,
    AU.TotalViews,
    AU.QuestionCount,
    AU.AnswerCount,
    AU.AvgQuestionScore,
    AU.GoldBadges,
    AU.SilverBadges,
    AU.BronzeBadges,
    R.Title AS LastPostTitle,
    R.CreationDate AS LastPostDate,
    COALESCE(PLS.RelatedCount, 0) AS TotalRelatedPosts
FROM ActiveUsers AU
LEFT JOIN RecentPosts R ON AU.UserId = R.OwnerUserId AND R.RN = 1
LEFT JOIN PostLinkStats PLS ON R.Id = PLS.PostId
WHERE 
    (AU.Reputation > 100 AND AU.QuestionCount > 0) OR
    (AU.Reputation < 50 AND AU.AnswerCount > 10)
ORDER BY AU.Rank
LIMIT 50;
