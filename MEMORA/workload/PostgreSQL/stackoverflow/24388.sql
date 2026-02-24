
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        CASE 
            WHEN rp.ViewCount > 10 THEN 'Popular'
            WHEN rp.Score IS NULL OR rp.Score < 0 THEN 'Needs Attention'
            ELSE 'Normal'
        END AS PostStatus,
        us.DisplayName AS OwnerName,
        us.Reputation AS OwnerReputation
    FROM 
        RecentPosts rp
    INNER JOIN 
        UserStatistics us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.rn = 1
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        p.Body,
        CASE
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Edit'
        END AS ActionType
    FROM 
        PostHistory ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '60 days')
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.PostStatus,
    pd.OwnerName,
    pd.OwnerReputation,
    pa.ActionType,
    pa.CreationDate AS ActivityDate
FROM 
    PostDetails pd
LEFT JOIN 
    PostActivity pa ON pd.PostId = pa.PostId
WHERE 
    pd.PostStatus = 'Popular'
ORDER BY 
    pd.ViewCount DESC,
    pd.OwnerReputation DESC
FETCH FIRST 10 ROWS ONLY;
