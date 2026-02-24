
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS HistoryEditCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.PostTypeId
), 
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.HistoryEditCount,
        ROW_NUMBER() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.CommentCount DESC, ps.HistoryEditCount DESC) AS Rank
    FROM PostStats ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.UpVotes,
    ups.DownVotes,
    ups.Favorites,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.HistoryEditCount
FROM UserVoteStats ups
LEFT JOIN RankedPosts rp ON ups.UserId = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = rp.PostId
)
WHERE ups.UpVotes > ups.DownVotes
  AND EXISTS (SELECT 1 
              FROM Posts p 
              WHERE p.OwnerUserId = ups.UserId 
                AND p.PostTypeId IN (1, 2)) 
ORDER BY ups.UpVotes DESC, ups.Favorites DESC;
