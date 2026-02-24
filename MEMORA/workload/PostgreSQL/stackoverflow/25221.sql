
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
UserRanked AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.CommentCount,
        ua.UpVotes,
        ua.DownVotes,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY ua.UpVotes - ua.DownVotes DESC, ua.QuestionCount DESC, ua.CommentCount DESC) AS Rank
    FROM UserActivity ua
)
SELECT 
    ur.Rank,
    ur.DisplayName,
    ur.QuestionCount,
    ur.CommentCount,
    ur.UpVotes,
    ur.DownVotes,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges
FROM UserRanked ur
WHERE ur.Rank <= 10
ORDER BY ur.Rank;
