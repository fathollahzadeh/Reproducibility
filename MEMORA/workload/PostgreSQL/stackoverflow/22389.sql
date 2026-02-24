
WITH UserVoteStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 11 THEN 1 END) AS UndeleteVotesCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),

PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id), 0) AS AnswerCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),

RankedPosts AS (
    SELECT
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank
    FROM PostDetails pd
)

SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotesCount,
    uvs.DownVotesCount,
    uvs.CloseVotesCount,
    uvs.UndeleteVotesCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.ClosedDate,
    rp.ReopenedDate,
    CASE 
        WHEN rp.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN rp.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Open' 
    END AS PostStatus
FROM UserVoteStatistics uvs
JOIN RankedPosts rp ON uvs.UserId IN (
    SELECT DISTINCT p.OwnerUserId 
    FROM Posts p 
    WHERE p.CreationDate < NOW() - INTERVAL '30 days'
)
WHERE uvs.VoteRank <= 10
ORDER BY uvs.UpVotesCount - uvs.DownVotesCount DESC, rp.ViewCount DESC;
