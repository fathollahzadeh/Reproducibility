WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AnswerCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
),

CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments
    FROM 
        Comments 
    GROUP BY 
        PostId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    rp.UserReputation,
    COALESCE(phd.HistoryTypes, 'No history') AS HistoryTypes,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.Id = cc.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.Id = phd.PostId
WHERE 
    rp.UserReputation > 100
    AND rp.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
   OR (phd.LastModified IS NOT NULL AND phd.LastModified > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 10;