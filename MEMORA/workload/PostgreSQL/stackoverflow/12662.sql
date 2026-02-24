
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(u.PostCount, 0) AS TotalPosts,
    COALESCE(u.QuestionCount, 0) AS TotalQuestions,
    COALESCE(u.AnswerCount, 0) AS TotalAnswers,
    COALESCE(u.UpVotes, 0) AS TotalUpVotes,
    COALESCE(u.DownVotes, 0) AS TotalDownVotes,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(b.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(b.BronzeBadges, 0) AS TotalBronzeBadges
FROM UserStats u
FULL OUTER JOIN BadgeStats b ON u.UserId = b.UserId
ORDER BY TotalPosts DESC, TotalUpVotes DESC
LIMIT 100;
