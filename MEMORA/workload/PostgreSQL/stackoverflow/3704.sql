
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
),
TopUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
    HAVING COUNT(*) > 3
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalVotes,
    us.UpVotes,
    us.DownVotes,
    re.Title,
    re.Editor,
    re.EditDate,
    CASE WHEN re.EditRank = 1 THEN 'Latest Edit' ELSE 'Earlier Edit' END AS EditStatus,
    tb.BadgeCount
FROM Users u
LEFT JOIN UserVoteStats us ON u.Id = us.UserId
LEFT JOIN RecentEdits re ON u.DisplayName = re.Editor
LEFT JOIN TopUsers tb ON u.Id = tb.UserId
WHERE u.Reputation >= 1000
AND (us.TotalVotes IS NULL OR us.TotalVotes > 10)
ORDER BY u.Reputation DESC, us.TotalVotes DESC NULLS LAST
LIMIT 50;
