
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
), 
TopEngagedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        PostsCreated,
        CommentsMade,
        EngagementRank
    FROM UserEngagement
    WHERE EngagementRank <= 10
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id 
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.ViewCount
), 
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.CommentCount,
        ps.CloseCount,
        CASE 
            WHEN ps.CloseCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM PostStatistics ps
    WHERE ps.ViewCount > 10 AND ps.CommentCount > 1
)
SELECT 
    e.UserId,
    e.DisplayName,
    f.PostId,
    f.Title,
    f.ViewCount,
    f.CommentCount,
    f.CloseCount,
    f.PostStatus,
    CASE 
        WHEN f.PostStatus = 'Closed' THEN 'This post has been closed due to moderation.'
        ELSE 'This post is currently open for discussion.'
    END AS PostStatusMessage
FROM TopEngagedUsers e
JOIN FilteredPosts f ON e.UserId = f.PostId
ORDER BY e.NetVotes DESC, f.ViewCount DESC
LIMIT 5 OFFSET 0;
