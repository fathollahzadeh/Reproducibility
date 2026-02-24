
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
PostHistoryWithReopened AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MIN(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        p.CreationDate
    FROM Posts p
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    GROUP BY p.Id, p.Title, p.CreationDate
)
SELECT 
    ups.DisplayName,
    u.Reputation,
    pt.TagsArray,
    ups.UpVotes - COALESCE(ups.DownVotes, 0) AS NetVotes,
    pwh.ClosedDate,
    pwh.ReopenedDate,
    CASE 
        WHEN pwh.ReopenedDate IS NOT NULL THEN 'Reopened'
        WHEN pwh.ClosedDate IS NOT NULL AND pwh.ReopenedDate IS NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    pwh.DeleteUndeleteCount
FROM UserVoteSummary ups
JOIN PostHistoryWithReopened pwh ON pwh.PostId = ups.UserId
JOIN PostWithTags pt ON pt.PostId = pwh.PostId
JOIN Users u ON u.Id = ups.UserId
WHERE ups.TotalVotes > 0 
AND (pt.TagsArray @> ARRAY['sql'] OR pt.TagsArray @> ARRAY['database'])
ORDER BY NetVotes DESC, u.Reputation DESC
LIMIT 20;
