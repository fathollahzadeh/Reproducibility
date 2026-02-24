
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId,
        COALESCE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), 'No Tags') AS CleanTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN COALESCE(b.Class, 0) = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.Views
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedOrReopenedAt,
        ARRAY_AGG(DISTINCT ch.Name) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ch ON ph.Comment = CAST(ch.Id AS varchar)
    GROUP BY 
        ph.PostId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CleanTags,
        us.Reputation,
        ps.ClosedOrReopenedAt,
        array_length(ps.CloseReasons, 1) AS CloseReasonCount,
        CASE WHEN rp.ViewCount > 1000 THEN 'High Traffic' ELSE 'Normal Traffic' END AS TrafficLabel,
        RANK() OVER (ORDER BY us.Views DESC, rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostHistoryDetails ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CleanTags,
    pp.Reputation,
    pp.CloseReasonCount,
    pp.ClosedOrReopenedAt,
    pp.TrafficLabel,
    CASE 
        WHEN pp.CloseReasonCount IS NOT NULL AND pp.ClosedOrReopenedAt IS NOT NULL 
        THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PopularPosts pp
WHERE 
    pp.ViewRank <= 10
ORDER BY 
    pp.Reputation DESC,
    pp.CloseReasonCount ASC
LIMIT 25;
