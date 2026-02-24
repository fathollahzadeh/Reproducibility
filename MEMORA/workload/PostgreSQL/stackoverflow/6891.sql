WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pm.*,
        RANK() OVER (ORDER BY pm.UpVoteCount DESC, pm.CommentCount DESC, pm.CreationDate ASC) AS Rank
    FROM PostMetrics pm
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    rp.EditCount,
    rp.TotalBadgeClass,
    rp.Rank
FROM RankedPosts rp
WHERE rp.Rank <= 10
ORDER BY rp.Rank;