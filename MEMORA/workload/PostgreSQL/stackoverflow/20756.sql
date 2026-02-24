
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosureDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosureDate,
        ct.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS int) = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(CASE WHEN rp.RankByScore = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers,
    COALESCE(SUM(CASE WHEN pc.CloseReason IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalClosures,
    COALESCE(SUM(DISTINCT upl.LinkCount), 0) AS TotalLinks,
    SUM(TotalBadgeClass) AS UserBadges,
    STRING_AGG(DISTINCT pc.CloseReason, ', ') AS CloseReasons
FROM 
    TopUsers up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostClosureDetails pc ON pc.PostId = rp.PostId
LEFT JOIN 
    UserPostLinks upl ON upl.PostId = rp.PostId
GROUP BY 
    up.UserId, up.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    UserBadges DESC, TotalPosts DESC
LIMIT 20;
