
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerStatus,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAwarded
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),

ClosedPosts AS (
    SELECT 
        ph.PostId AS postId, 
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.TotalBountyAwarded,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
    CASE 
        WHEN rp.AnswerStatus = -1 THEN 'No Accepted Answer' 
        ELSE 'Accepted Answer Exists' 
    END AS AnswerStatus,
    CASE 
        WHEN rp.PostRank <= 5 THEN 'Top 5 Posts by User'
        ELSE 'Other Posts'
    END AS PostRankCategory
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.postId
WHERE 
    ua.PostsCount > 0
ORDER BY 
    ua.TotalBountyAwarded DESC, 
    rp.Score DESC;
