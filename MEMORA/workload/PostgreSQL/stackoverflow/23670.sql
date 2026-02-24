
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 years' 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        RANK() OVER (ORDER BY us.TotalViews DESC, us.AverageScore DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.PostCount > 5
),
PostChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostLinksAggregated AS (
    SELECT 
        pl.PostId,
        ARRAY_AGG(pl.RelatedPostId) AS RelatedPosts
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.TotalPosts,
    p.TotalUpVotes,
    p.TotalDownVotes,
    us.UserId,
    us.DisplayName AS UserName,
    us.Reputation,
    us.Location,
    tu.UserRank,
    COALESCE(pc.ChangeCount, 0) AS TotalChanges,
    COALESCE(pla.RelatedPosts, ARRAY[]::BIGINT[]) AS RelatedPostIds
FROM 
    RankedPosts p
JOIN 
    UserStatistics us ON p.OwnerUserId = us.UserId
LEFT JOIN 
    TopUsers tu ON us.UserId = tu.UserId
LEFT JOIN 
    PostChanges pc ON p.PostId = pc.PostId
LEFT JOIN 
    PostLinksAggregated pla ON p.PostId = pla.PostId
WHERE 
    (p.TotalDownVotes < p.TotalUpVotes OR p.TotalUpVotes IS NULL)
    AND (p.PostRank <= 3 OR p.PostRank IS NULL)
ORDER BY 
    us.TotalViews DESC, 
    p.CreationDate DESC
LIMIT 100;
