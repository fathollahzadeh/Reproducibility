
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
BadgeStatistics AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(us.PostCount, 0) AS PostCount,
    COALESCE(us.QuestionCount, 0) AS QuestionCount,
    COALESCE(us.AnswerCount, 0) AS AnswerCount,
    COALESCE(us.TotalBounty, 0) AS TotalBounty,
    COALESCE(us.UpVotes, 0) AS UpVotes,
    COALESCE(us.DownVotes, 0) AS DownVotes,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
FROM Users u
LEFT JOIN UserStatistics us ON u.Id = us.UserId
LEFT JOIN BadgeStatistics bs ON u.Id = bs.UserId
ORDER BY u.Reputation DESC
LIMIT 100;
