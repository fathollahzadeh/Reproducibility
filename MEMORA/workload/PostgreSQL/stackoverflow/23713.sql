WITH RankedPostComments AS (
    SELECT 
        c.PostId,
        c.UserId,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank,
        RANK() OVER (PARTITION BY c.PostId ORDER BY c.Score DESC) AS CommentScoreRank
    FROM 
        Comments c
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT pc.UserId) AS UniqueCommenters,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    LEFT JOIN 
        Users u ON pc.UserId = u.Id
    WHERE 
        p.CreationDate > '2020-01-01' AND
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
BizarreJoin AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.TotalBounty,
        pm.UniqueCommenters,
        pm.AvgReputation,
        CASE 
            WHEN pm.UniqueCommenters = 0 THEN 'No comments yet!'
            WHEN pm.UniqueCommenters = 1 THEN 'Just one bold commenter.'
            ELSE CONCAT(pm.UniqueCommenters, ' unique commenters.') 
        END AS CommentStatus
    FROM 
        PostMetrics pm
    LEFT JOIN 
        RankedPostComments rpc ON pm.PostId = rpc.PostId AND rpc.CommentRank = 1
)

SELECT 
    b.PostId,
    b.Title,
    b.ViewCount,
    b.TotalBounty,
    b.UniqueCommenters,
    b.CommentStatus,
    COALESCE(b.AvgReputation, 0) AS AvgUserReputation,
    CASE 
        WHEN b.TotalBounty <= 0 THEN 'No bounties awarded.'
        WHEN b.TotalBounty < 50 THEN 'A small bounty.'
        ELSE 'A generous bounty!'
    END AS BountyStatus
FROM 
    BizarreJoin b
WHERE 
    b.CommentStatus IS NOT NULL
ORDER BY 
    b.ViewCount DESC, b.TotalBounty DESC;