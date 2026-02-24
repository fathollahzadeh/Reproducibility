
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    GROUP BY 
        u.Id
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 AND ph.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days' THEN 1 END) AS RecentCloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 AND ph.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days' THEN 1 END) AS RecentDeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.Score,
        ur.TotalReputation,
        COALESCE(rb.BadgeName, 'No Gold Badge') AS LastGoldBadge,
        phs.CloseCount,
        phs.RecentCloseCount,
        phs.DeleteCount,
        phs.RecentDeleteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        RecentBadges rb ON rp.OwnerUserId = rb.UserId AND rb.BadgeRank = 1
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
)
SELECT 
    *,
    CASE 
        WHEN Score > 10 THEN 'High Score'
        WHEN Score BETWEEN 1 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    FinalSummary
WHERE 
    TotalReputation > 1000
ORDER BY 
    CreationDate DESC, Score DESC;
