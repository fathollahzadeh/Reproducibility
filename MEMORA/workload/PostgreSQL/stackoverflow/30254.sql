
WITH RecursivePostHistory AS (
    SELECT ph.PostId, ph.UserId, ph.CreationDate, ph.Comment, ph.Text,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
),
RecentPosts AS (
    SELECT p.Id AS PostId, p.CreationDate, p.Title, p.Body, p.ViewCount,
           p.OwnerUserId, p.AcceptedAnswerId, p.AnswerCount,
           COALESCE(MAX(rph.CreationDate), p.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN RecursivePostHistory rph ON p.Id = rph.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY p.Id, p.CreationDate, p.Title, p.Body, p.ViewCount,
             p.OwnerUserId, p.AcceptedAnswerId, p.AnswerCount
),
TopUsers AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation
    FROM Users u
    ORDER BY u.Reputation DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT rp.PostId, rp.Title, rp.ViewCount, rp.LastEditDate,
           u.DisplayName AS OwnerName, u.Reputation,
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
           COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2), 0) AS UpVotes,
           COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM RecentPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN TopUsers tu ON u.Id = tu.UserId
    WHERE tu.UserId IS NOT NULL 
)

SELECT ps.PostId, ps.Title, ps.ViewCount, ps.LastEditDate, 
       ps.OwnerName, ps.Reputation, ps.CommentCount, ps.UpVotes, ps.DownVotes
FROM PostStatistics ps
ORDER BY ps.ViewCount DESC, ps.LastEditDate DESC;
