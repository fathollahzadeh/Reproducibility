
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Only Questions */
        AND p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.TotalBadges,
        us.TotalBounty,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.TotalPosts > 0 /* Filter to only users with posts */
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        p.Title,
        p.Body,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) /* Closing, Reopening, Deletion */
)
SELECT 
    pu.DisplayName AS UserDisplayName,
    pu.TotalPosts,
    pu.TotalScore,
    pu.TotalBadges,
    COUNT(phd.PostId) AS PostHistoryCount,
    AVG(COALESCE(phd.HistoryRank, 0)) AS AvgHistoryRank,
    SUM(CASE WHEN phd.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosures,
    SUM(CASE WHEN phd.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopens,
    SUM(CASE WHEN phd.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS TotalDeletions
FROM 
    TopUsers pu
LEFT JOIN PostHistoryDetail phd ON pu.UserId = phd.UserId
GROUP BY 
    pu.UserId, pu.DisplayName, pu.TotalPosts, pu.TotalScore, pu.TotalBadges
HAVING 
    AVG(COALESCE(phd.HistoryRank, 0)) < 2 /* Only keep users with an average history rank of less than 2 */
ORDER BY 
    pu.TotalScore DESC;
