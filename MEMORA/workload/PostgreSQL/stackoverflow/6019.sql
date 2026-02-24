WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
HistoricalChanges AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ChangeDate,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.PostHistoryTypeId, ph.UserDisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ua.TotalPosts,
    ua.UpvotedPosts,
    ua.DownvotedPosts,
    hc.ChangeCount,
    hc.ChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.PostId = ua.UserId
LEFT JOIN 
    HistoricalChanges hc ON rp.PostId = hc.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;