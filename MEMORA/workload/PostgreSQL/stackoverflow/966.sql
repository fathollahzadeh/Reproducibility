
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(v.Upvotes, 0) AS TotalUpvotes,
        COALESCE(v.Downvotes, 0) AS TotalDownvotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    ORDER BY 
        p.Score DESC
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
LatestPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    ORDER BY 
        ph.CreationDate DESC
)

SELECT 
    up.UserId, 
    up.DisplayName, 
    MAX(up.PostCount) AS TotalPosts,
    SUM(COALESCE(rp.TotalUpvotes, 0)) AS AllTimeUpvotes,
    SUM(COALESCE(rp.TotalDownvotes, 0)) AS AllTimeDownvotes,
    COUNT(DISTINCT lp.PostId) AS ClosedPosts,
    MAX(rp.CreationDate) AS LastPostDate
FROM 
    TopUsers up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    LatestPostHistory lp ON rp.PostId = lp.PostId
GROUP BY 
    up.UserId, up.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 0 
    AND MAX(rp.CreationDate) < CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY 
    AllTimeUpvotes DESC, TotalPosts DESC;
