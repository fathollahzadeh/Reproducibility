
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM
        Posts p
    WHERE
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        CASE
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationTier,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostHistoryAnalytics AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS TotalPostHistory
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
FilteredPostSummary AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.ReputationTier,
        ur.PostCount,
        pha.CloseCount,
        pha.DeleteCount,
        pha.ReopenCount
    FROM
        RankedPosts rp
    INNER JOIN UserReputation ur ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ur.UserId)
    LEFT JOIN PostHistoryAnalytics pha ON rp.PostId = pha.PostId
    WHERE
        ur.PostCount > 5
        AND (pha.CloseCount = 0 OR pha.DeleteCount = 0)
)
SELECT 
    COALESCE(ur.ReputationTier, 'Unknown') AS Reputation,
    COUNT(*) AS TotalFilteredPosts,
    AVG(fs.ViewCount) AS AverageViewCount,
    SUM(fs.Score) AS TotalScoreFromFilteredPosts,
    STRING_AGG(DISTINCT fs.Title, '; ') AS PostTitles
FROM 
    FilteredPostSummary fs
LEFT JOIN UserReputation ur ON fs.ReputationTier = ur.ReputationTier
GROUP BY 
    ur.ReputationTier
ORDER BY 
    TotalFilteredPosts DESC NULLS LAST;
