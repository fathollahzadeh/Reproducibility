WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(p.PostCount, 0) AS PostCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId,
            COUNT(*) AS PostCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1 
        GROUP BY 
            OwnerUserId
    ) p ON u.Id = p.UserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        PostCount,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC) AS UserRank
    FROM 
        UserReputation
    WHERE 
        Reputation IS NOT NULL
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserPosts AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
),
FinalMetrics AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.BadgeCount,
        tu.PostCount,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        up.TotalPosts,
        up.PositivePosts
    FROM 
        TopUsers tu
    LEFT JOIN 
        RecentPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
    LEFT JOIN 
        UserPosts up ON tu.DisplayName = up.DisplayName
)
SELECT 
    fm.DisplayName,
    fm.Reputation,
    fm.BadgeCount,
    fm.PostCount,
    fm.Title AS RecentPostTitle,
    fm.CreationDate AS RecentPostDate,
    fm.TotalPosts,
    fm.PositivePosts,
    CASE 
        WHEN fm.Reputation > 1000 THEN 'High Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN fm.BadgeCount = 0 THEN 'No Badges'
        WHEN fm.BadgeCount BETWEEN 1 AND 3 THEN 'Few Badges'
        ELSE 'Many Badges'
    END AS BadgeCategory,
    (SELECT STRING_AGG(TagName, ', ') 
     FROM Tags 
     WHERE TagName LIKE '%' || fm.DisplayName || '%' 
     LIMIT 5) AS RelatedTags
FROM 
    FinalMetrics fm
WHERE 
    fm.Reputation > 0
ORDER BY 
    fm.Reputation DESC,
    fm.BadgeCount DESC,
    fm.TotalPosts DESC;