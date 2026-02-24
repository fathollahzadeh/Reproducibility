WITH RECURSIVE TopUsers AS (
    SELECT Id, DisplayName, Reputation, CreationDate,
           RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE Reputation > 1000
),
PostsWithBadges AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           COUNT(b.Id) AS BadgeCount,
           AVG(u.Reputation) AS AvgReputation
    FROM Posts p
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    JOIN Users u ON u.Id = p.OwnerUserId
    GROUP BY p.Id, p.Title, p.CreationDate
),
RecentActivePosts AS (
    SELECT p.PostTypeId, p.Title, p.Score, p.ViewCount, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT ph.PostId, pt.Name AS PostHistoryTypeName, COUNT(*) AS CloseCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE pt.Name = 'Post Closed'
    GROUP BY ph.PostId, pt.Name
),
FinalReport AS (
    SELECT pu.UserRank, pu.DisplayName, wp.Title, wp.BadgeCount,
           rp.Score AS RecentScore, rp.ViewCount AS RecentViewCount,
           cp.CloseCount
    FROM TopUsers pu
    JOIN PostsWithBadges wp ON wp.PostId IN (
        SELECT Posts.Id
        FROM Posts
        WHERE Posts.OwnerUserId = pu.Id)
    LEFT JOIN RecentActivePosts rp ON rp.Title = wp.Title
    LEFT JOIN ClosedPosts cp ON cp.PostId = wp.PostId
    WHERE pu.UserRank <= 10
),
FinalOutput AS (
    SELECT *,
           COALESCE(CASE WHEN CloseCount IS NOT NULL THEN 'Closed Post' ELSE 'Open Post' END, 'Open Post') AS PostStatus,
           CONCAT('User: ', DisplayName, ' | Title: ', Title, ' | Score: ', RecentScore) AS ReportDetails
    FROM FinalReport
)
SELECT *
FROM FinalOutput
ORDER BY UserRank, BadgeCount DESC, RecentScore DESC;