WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserEngagement AS (
    SELECT 
        ups.UserId,
        ups.TotalPosts,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalViews,
        ups.UpVotes,
        ups.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM UserPostStats ups
    LEFT JOIN UserBadges ub ON ups.UserId = ub.UserId
)
SELECT 
    u.DisplayName,
    ue.TotalPosts,
    ue.QuestionCount,
    ue.AnswerCount,
    ue.TotalViews,
    ue.UpVotes,
    ue.DownVotes,
    ue.BadgeCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM Users u
JOIN UserEngagement ue ON u.Id = ue.UserId
WHERE ue.TotalPosts > 10
ORDER BY ue.UpVotes DESC, ue.TotalViews DESC;
