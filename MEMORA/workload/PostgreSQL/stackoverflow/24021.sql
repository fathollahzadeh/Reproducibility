
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
),
RecentVotes AS (
    SELECT 
        PostId,
        VoteTypeId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    WHERE CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY PostId, VoteTypeId
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), ARRAY[]::VARCHAR[]) AS Tags,
        SUM(rv.UpVotes) AS TotalUpVotes,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Tags t ON pl.RelatedPostId = t.Id
    LEFT JOIN RecentVotes rv ON p.Id = rv.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        MAX(ph.UserDisplayName) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS UserDisplayName
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate, ph.Comment
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Tags,
    ps.TotalUpVotes,
    ps.CommentCount,
    COALESCE(cr.UserDisplayName, 'No action') AS ClosedBy,
    RANK() OVER (PARTITION BY ps.HighestBadgeClass ORDER BY ps.TotalUpVotes DESC) AS RankWithinBadgeClass,
    COALESCE(u.Reputation, 0) AS UserReputation
FROM PostSummary ps
LEFT JOIN ClosedPosts cr ON ps.PostId = cr.PostId
LEFT JOIN UserReputation u ON ps.HighestBadgeClass = u.UserRank
WHERE ps.TotalUpVotes > 0
  AND ps.CommentCount > 0
  AND ps.HighestBadgeClass BETWEEN 1 AND 3
ORDER BY ps.TotalUpVotes DESC, ps.CommentCount DESC, ps.PostId;
