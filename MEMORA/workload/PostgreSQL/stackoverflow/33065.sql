
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.TotalScore,
        us.TotalBadgeClass,
        us.TotalBountyAmount,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.TotalQuestions > 0
),
MostVotedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(pa.PostId) AS RecentActivityCount
    FROM 
        Posts p
    JOIN 
        PostActivity pa ON p.Id = pa.PostId
    WHERE 
        pa.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalScore,
    tu.TotalBadgeClass,
    tu.TotalBountyAmount,
    COALESCE(ra.RecentActivityCount, 0) AS RecentActivity,
    mp.Title AS MostVotedPostTitle,
    mp.TotalBounty,
    mp.VoteCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentActivity ra ON tu.UserId = ra.OwnerUserId
LEFT JOIN 
    MostVotedPosts mp ON tu.UserId = mp.OwnerUserId
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.TotalScore DESC;
