
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT PostId FROM RankedPosts)
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges ub
    GROUP BY 
        ub.UserId
),
CombinedData AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalBounty,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount,
        COALESCE(rp.PostId, 0) AS LatestPostId,
        COALESCE(rp.Title, 'No posts') AS LatestPostTitle
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
    LEFT JOIN 
        RankedPosts rp ON tu.UserId = rp.PostId 
)
SELECT 
    c.UserId,
    c.DisplayName,
    c.TotalBounty,
    c.GoldCount,
    c.SilverCount,
    c.BronzeCount,
    CASE 
        WHEN c.TotalBounty IS NOT NULL THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS Bounty_Status,
    c.LatestPostTitle,
    c.LatestPostId
FROM 
    CombinedData c
ORDER BY 
    c.TotalBounty DESC NULLS LAST, 
    c.DisplayName ASC;
