WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
        COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
        COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC) AS Rank
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
TopPerformers AS (
    SELECT 
        * 
    FROM UserPerformance
    WHERE Rank <= 10
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    tp.QuestionCount,
    tp.AnswerCount,
    tp.TotalScore,
    tp.TotalViews,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = tp.UserId AND v.VoteTypeId IN (2, 3)) AS TotalVotes
FROM TopPerformers tp
ORDER BY tp.Rank;
