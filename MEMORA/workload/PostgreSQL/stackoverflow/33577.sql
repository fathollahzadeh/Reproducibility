WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (1, 4, 10)  
), PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount,
        AVG(u.Reputation) AS AvgUserReputation,
        MAX(ph.CreationDate) AS LastPostHistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
), RankedPosts AS (
    SELECT 
        pm.Id,
        pm.Title,
        pm.CommentsCount,
        pm.VotesCount,
        pm.AvgUserReputation,
        pm.LastPostHistoryDate,
        RANK() OVER (ORDER BY pm.VotesCount DESC, pm.CommentsCount DESC) AS PostRank
    FROM 
        PostMetrics pm
)
SELECT 
    rp.Title,
    rp.CommentsCount,
    rp.VotesCount,
    COALESCE(rp.AvgUserReputation, 0) AS AvgUserReputation,
    CASE 
        WHEN rp.LastPostHistoryDate IS NOT NULL THEN 
            'Active'
        ELSE 
            'Inactive'
    END AS PostStatus
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10  
ORDER BY 
    rp.PostRank;