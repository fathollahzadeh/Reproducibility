WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        COUNT(*) FILTER (WHERE h.Id IS NOT NULL) AS CloseReasonCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE 
        h.Name = 'Post Closed'
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.TagCount,
    u.DisplayName AS OwnerDisplayName,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AvgReputation,
    COALESCE(c.CloseDate, NULL) AS ClosedDate,
    CASE 
        WHEN c.CloseReasonCount IS NULL THEN 'Not Closed'
        ELSE 'Closed'
    END AS ClosureStatus,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostTier
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts c ON rp.PostId = c.PostId
WHERE 
    us.AvgReputation > 1000
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.PostId DESC
LIMIT 50;