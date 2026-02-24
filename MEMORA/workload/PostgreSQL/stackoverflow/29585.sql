
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(pv.Id) AS ViewCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN PostLinks pl ON rp.PostId = pl.PostId
    LEFT JOIN Posts pv ON rp.PostId = pv.Id
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    WHERE rp.TagRank <= 5
    GROUP BY rp.PostId, rp.Title, rp.Tags
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    pm.PostId,
    pm.Title,
    pm.Tags,
    pm.CommentCount,
    pm.ViewCount,
    pm.CloseVotes,
    ue.VoteCount,
    ue.UpVotes,
    ue.DownVotes,
    ue.BadgeCount
FROM UserEngagement ue
JOIN PostMetrics pm ON ue.UserId = pm.PostId
ORDER BY pm.ViewCount DESC, ue.VoteCount DESC;
