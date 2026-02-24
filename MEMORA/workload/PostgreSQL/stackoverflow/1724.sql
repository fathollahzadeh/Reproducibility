WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)

SELECT 
    u.DisplayName AS User,
    u.Reputation,
    ups.UpVotes,
    ups.DownVotes,
    p.Title AS PostTitle,
    p.ViewCount,
    ph.LastEditDate,
    ph.EditCount,
    ph.EditTypes,
    p.CommentCount
FROM Users u
JOIN UserVoteStats ups ON u.Id = ups.UserId
JOIN PostWithComments p ON p.PostId IN (
    SELECT DISTINCT PostId 
    FROM Votes v 
    WHERE v.UserId = u.Id
)
LEFT JOIN PostHistoryAnalysis ph ON p.PostId = ph.PostId
WHERE 
    ups.TotalVotes > 10 
    AND p.ViewCount > 200 
    AND ph.EditCount > 0
ORDER BY u.Reputation DESC, p.ViewCount DESC
LIMIT 50;
