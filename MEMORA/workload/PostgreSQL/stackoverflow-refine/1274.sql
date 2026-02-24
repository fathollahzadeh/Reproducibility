WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT ph.Id) AS CloseHistoryCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id, p.Title
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(cp.CloseHistoryCount, 0) AS CloseCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Posts p
    LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY p.Id, p.Title, cp.CloseHistoryCount
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CloseCount,
        ps.CommentCount,
        ps.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY ps.CloseCount ORDER BY ps.CommentCount DESC, ps.TotalBounty DESC) AS Rank
    FROM PostStatistics ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    rp.Title,
    rp.CloseCount,
    rp.CommentCount,
    rp.TotalBounty,
    ups.UpVotesCount,
    ups.DownVotesCount
FROM UserVoteStats ups
JOIN RankedPosts rp ON ups.PostsCount > 5 AND ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE rp.Rank <= 10
ORDER BY ups.UpVotesCount DESC, rp.CommentCount DESC;