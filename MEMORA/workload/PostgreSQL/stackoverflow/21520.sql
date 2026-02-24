WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopUsersWithPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(phs.CloseCount), 0) AS TotalClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistoryStats phs ON p.Id = phs.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    u.TotalViews,
    u.TotalScore,
    COALESCE(b.GoldCount, 0) AS GoldCount,
    COALESCE(b.SilverCount, 0) AS SilverCount,
    COALESCE(b.BronzeCount, 0) AS BronzeCount,
    r.CommentCount,
    CASE 
        WHEN u.TotalClosedPosts > 0 THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS PostStatus
FROM 
    TopUsersWithPosts u
JOIN 
    RankedPosts r ON u.UserId = r.PostRank
LEFT JOIN 
    UserBadgeCounts b ON u.UserId = b.UserId
WHERE 
    r.PostRank <= 5
ORDER BY 
    u.TotalScore DESC, r.Score DESC;