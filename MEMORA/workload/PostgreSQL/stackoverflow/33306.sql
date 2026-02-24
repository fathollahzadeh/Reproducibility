
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(COALESCE(b.Class, 0)) AS AverageBadgeClass,
        SUM(CASE WHEN b.Class IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivities AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        RANK() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
ConsolidatedData AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.QuestionCount,
        u.TotalBounty,
        u.AverageBadgeClass,
        u.BadgeCount,
        ra.PostId,
        ra.CreationDate AS RecentActivityDate,
        ra.ActivityRank
    FROM 
        UserStats u
    LEFT JOIN 
        RecentActivities ra ON u.UserId = ra.UserId
)
SELECT 
    cd.UserId,
    cd.DisplayName,
    cd.QuestionCount,
    cd.TotalBounty,
    cd.AverageBadgeClass,
    cd.BadgeCount,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    MAX(cd.RecentActivityDate) AS LastActivityDate
FROM 
    ConsolidatedData cd
LEFT JOIN 
    RankedPosts rp ON cd.UserId = rp.OwnerUserId AND rp.Rank <= 1 
WHERE 
    cd.QuestionCount > 0
GROUP BY 
    cd.UserId, cd.DisplayName, cd.QuestionCount, cd.TotalBounty, cd.AverageBadgeClass, cd.BadgeCount
HAVING 
    COUNT(DISTINCT rp.PostId) > 0 
ORDER BY 
    cd.TotalBounty DESC, cd.QuestionCount DESC;
