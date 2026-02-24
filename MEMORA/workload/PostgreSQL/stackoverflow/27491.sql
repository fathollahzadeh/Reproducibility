
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiPosts,
        SUM(pi.CommentCount) AS TotalComments,
        SUM(pi.UpVotes) AS TotalUpVotes,
        SUM(pi.DownVotes) AS TotalDownVotes,
        SUM(pi.RelatedPostsCount) AS TotalRelatedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostInteractions pi ON p.Id = pi.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ua.UserId, 
    ua.DisplayName, 
    ua.TotalPosts, 
    ua.Questions, 
    ua.Answers, 
    ua.WikiPosts, 
    ua.TotalComments, 
    ua.TotalUpVotes, 
    ua.TotalDownVotes, 
    ub.TotalBadges, 
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges
FROM UserActivity ua
JOIN UserBadges ub ON ua.UserId = ub.UserId
ORDER BY ua.TotalPosts DESC, ub.TotalBadges DESC;
