WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation >= 100  
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS TotalDownVotes,
        COUNT(c.Id) AS CommentCount,
        PERCENT_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosingRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  
),
UserScore AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ps.PostId,
        ps.Title,
        ps.ScoreRank,
        (ua.UpVotes - ua.DownVotes) AS NetVotes
    FROM UserActivity ua
    JOIN PostStatistics ps ON ua.PostCount > 0
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.NetVotes,
    ps.Title,
    ps.ScoreRank,
    cp.Comment AS ClosureComment,
    CASE 
        WHEN cp.ClosingRank IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM UserScore us
LEFT JOIN ClosedPosts cp ON us.PostId = cp.PostId
JOIN PostStatistics ps ON us.PostId = ps.PostId
WHERE us.NetVotes > 0  
ORDER BY us.Reputation DESC, ps.ScoreRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;