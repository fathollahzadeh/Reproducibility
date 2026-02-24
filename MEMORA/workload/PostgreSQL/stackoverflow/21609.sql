
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(vb.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        AVG(CASE 
                WHEN p.OwnerUserId IS NOT NULL THEN 1 
                ELSE 0 
            END) AS OwnershipRatio
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
CloseVoteCounts AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalBounty,
    ue.TotalComments,
    ue.OwnershipRatio,
    COALESCE(CCO.CloseVoteCount, 0) AS CloseVoteCount,
    RP.Title AS TopPostTitle,
    RP.ViewCount AS TopPostViewCount
FROM 
    UserEngagement ue
LEFT JOIN 
    CloseVoteCounts CCO ON ue.UserId = CCO.UserId
LEFT JOIN 
    RankedPosts RP ON RP.Rank = 1 AND RP.PostId IN (
        SELECT 
            DISTINCT p.Id 
        FROM 
            Posts p 
        JOIN 
            Comments c ON p.Id = c.PostId 
        WHERE 
            c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 week'
    )
WHERE 
    COALESCE(ue.TotalBounty, 0) > (SELECT AVG(TotalBounty) FROM UserEngagement)
    AND COALESCE(ue.TotalComments, 0) > 5
ORDER BY 
    ue.TotalBounty DESC, 
    ue.TotalComments DESC, 
    COALESCE(CCO.CloseVoteCount, 0) DESC;
