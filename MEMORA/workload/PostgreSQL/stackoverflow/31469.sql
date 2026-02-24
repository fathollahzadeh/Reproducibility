
WITH RECURSIVE UserBadgeCount AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount,
           RANK() OVER (ORDER BY COUNT(b.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.Id AS PostId,
           p.OwnerUserId,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           p.Score AS PostScore,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.Score
),
QualifiedUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(ub.BadgeCount, 0) AS BadgeCount,
           COUNT(ps.PostId) AS PostCount,
           SUM(ps.UpVotes) AS TotalUpVotes,
           SUM(ps.DownVotes) AS TotalDownVotes,
           AVG(ps.PostScore) AS AveragePostScore
    FROM Users u
    LEFT JOIN UserBadgeCount ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE u.Reputation > 1000  
    GROUP BY u.Id, u.DisplayName, ub.BadgeCount
    HAVING COUNT(ps.PostId) > 5  
),
TopUsers AS (
    SELECT UserId, 
           DisplayName,
           BadgeCount,
           PostCount,
           TotalUpVotes,
           TotalDownVotes,
           AveragePostScore,
           RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVotesRank
    FROM QualifiedUsers
)
SELECT u.UserId,
       u.DisplayName,
       u.BadgeCount,
       u.PostCount,
       u.TotalUpVotes,
       u.TotalDownVotes,
       u.AveragePostScore,
       CASE 
           WHEN u.AveragePostScore IS NULL THEN 'No Score'
           WHEN u.AveragePostScore > 50 THEN 'High Performer'
           ELSE 'Needs Improvement'
       END AS PerformanceCategory,
       CASE 
           WHEN u.PostCount >= 20 THEN 'Frequent Contributor'
           ELSE 'Occasional Contributor'
       END AS ContributionFrequency
FROM TopUsers u
WHERE u.UpVotesRank <= 10  
ORDER BY u.TotalUpVotes DESC;
