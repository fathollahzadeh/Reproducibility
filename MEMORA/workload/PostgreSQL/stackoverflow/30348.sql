
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.Score, 0) AS Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(p.Score, 0) DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
        AND p.PostTypeId IN (1, 2)  
    GROUP BY
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount, COALESCE(p.Score, 0), p.PostTypeId
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),

PostHistorySummary AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM
        PostHistory ph
    WHERE
        ph.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')
),

RecentPopularPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        ua.DisplayName AS OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM
        RankedPosts rp
    JOIN Users ua ON rp.OwnerUserId = ua.Id
    WHERE
        rp.Rank <= 10  
)

SELECT 
    rpp.PostId,
    rpp.Title,
    rpp.OwnerDisplayName,
    rpp.ViewCount,
    rpp.Score,
    rpp.CommentCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.BadgeCount,
    ua.TotalPosts,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    ph.UserDisplayName AS HistoryEditor,
    ph.Comment AS HistoryComment
FROM 
    RecentPopularPosts rpp
LEFT JOIN UserActivity ua ON rpp.OwnerUserId = ua.UserId
LEFT JOIN PostHistorySummary ph ON rpp.PostId = ph.PostId
ORDER BY 
    rpp.Score DESC, rpp.ViewCount DESC
LIMIT 50;
