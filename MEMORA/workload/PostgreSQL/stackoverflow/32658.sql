WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), PostReputation AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId
), UserPostLinks AS (
    SELECT u.Id AS UserId, 
           COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsLinked,
           COUNT(DISTINCT p.Id) AS TotalPostsCreated
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY u.Id
), BadgeStats AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
), UserStatistics AS (
    SELECT u.Id,
           u.Reputation,
           COALESCE(ubr.ReputationRank, 0) AS ReputationRank,
           ups.RelatedPostsLinked,
           ups.TotalPostsCreated,
           bs.GoldBadges,
           bs.SilverBadges,
           bs.BronzeBadges
    FROM Users u
    LEFT JOIN UserReputation ubr ON u.Id = ubr.Id
    LEFT JOIN UserPostLinks ups ON u.Id = ups.UserId
    LEFT JOIN BadgeStats bs ON u.Id = bs.UserId
)
SELECT us.Id,
       us.Reputation,
       us.ReputationRank,
       us.RelatedPostsLinked,
       us.TotalPostsCreated,
       COALESCE(pr.UpVotes, 0) AS TotalUpvotes,
       COALESCE(pr.DownVotes, 0) AS TotalDownvotes,
       COALESCE(pr.TotalBounty, 0) AS TotalBounty,
       us.GoldBadges,
       us.SilverBadges,
       us.BronzeBadges
FROM UserStatistics us
LEFT JOIN PostReputation pr ON us.Id = pr.OwnerUserId
WHERE us.Reputation > 100
ORDER BY us.Reputation DESC, us.TotalPostsCreated DESC
LIMIT 100;
