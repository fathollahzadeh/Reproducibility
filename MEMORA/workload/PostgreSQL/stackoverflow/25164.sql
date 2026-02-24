WITH UserActivity AS (
  SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(c.Score) AS TotalCommentScore,
    SUM(p.Score) AS TotalPostScore,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
  FROM Users u
  LEFT JOIN Posts p ON u.Id = p.OwnerUserId
  LEFT JOIN Comments c ON p.Id = c.PostId
  LEFT JOIN Badges b ON u.Id = b.UserId
  GROUP BY u.Id, u.DisplayName, u.Reputation
),
RankedUserActivity AS (
  SELECT 
    ua.*,
    RANK() OVER (ORDER BY ua.Reputation DESC, ua.TotalPosts DESC, ua.TotalComments DESC) AS ActivityRank
  FROM UserActivity ua
),
TopActiveUsers AS (
  SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    TotalPosts, 
    TotalComments,
    TotalCommentScore,
    TotalPostScore,
    GoldBadges,
    SilverBadges,
    BronzeBadges
  FROM RankedUserActivity
  WHERE ActivityRank <= 10
)
SELECT 
  tua.DisplayName,
  tua.Reputation,
  tua.TotalPosts,
  tua.TotalComments,
  tua.TotalCommentScore,
  tua.TotalPostScore,
  CONCAT('Gold: ', tua.GoldBadges, ', Silver: ', tua.SilverBadges, ', Bronze: ', tua.BronzeBadges) AS BadgeSummary
FROM TopActiveUsers tua
ORDER BY tua.Reputation DESC;
