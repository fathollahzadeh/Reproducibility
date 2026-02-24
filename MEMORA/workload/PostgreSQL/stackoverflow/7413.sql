WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
), UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
), PostVoteStats AS (
    SELECT 
        p.OwnerUserId,
        AVG(v.BountyAmount) AS AverageBountyAmount,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    WHERE v.VoteTypeId IN (2, 3)  
    GROUP BY p.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.PositivePosts,
    ups.NegativePosts,
    COALESCE(ubc.TotalBadges, 0) AS TotalBadges,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pvs.AverageBountyAmount, 0) AS AverageBountyAmount,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes
FROM UserPostStats ups
LEFT JOIN UserBadgeCounts ubc ON ups.UserId = ubc.UserId
LEFT JOIN PostVoteStats pvs ON ups.UserId = pvs.OwnerUserId
WHERE ups.TotalPosts > 10
ORDER BY ups.TotalPosts DESC, ups.PositivePosts DESC;