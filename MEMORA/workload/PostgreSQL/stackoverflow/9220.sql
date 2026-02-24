
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
), UserActivity AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.Questions,
        ue.Answers,
        ue.TotalComments,
        ue.Upvotes,
        ue.Downvotes,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges
    FROM UserEngagement ue
    LEFT JOIN UserBadges ub ON ue.UserId = ub.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalComments,
    ua.Upvotes,
    ua.Downvotes,
    ua.TotalBadges,
    RANK() OVER (ORDER BY ua.TotalPosts DESC, ua.Upvotes DESC) AS EngagementRank
FROM UserActivity ua
WHERE ua.TotalPosts > 0
ORDER BY EngagementRank
FETCH FIRST 100 ROWS ONLY;
