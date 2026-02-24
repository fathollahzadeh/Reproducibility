WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        
        
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
TopActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 10  
),
RankedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.CreationDate,
        r.PostRank,
        COALESCE(pd.EditCount, 0) AS EditCount,
        pd.LastEditDate,
        tu.DisplayName AS OwnerDisplayName
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        PostHistoryDetails pd ON r.PostId = pd.PostId
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    JOIN 
        TopActiveUsers tu ON u.Id = tu.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.PostRank, 
    rp.EditCount,
    rp.LastEditDate,
    rp.OwnerDisplayName,
    
    CASE 
        WHEN rp.EditCount > 0 THEN 'Edited' 
        ELSE 'Not Edited' 
    END AS EditStatus,
    
    
    (SELECT COUNT(pl.Id)
     FROM PostLinks pl
     WHERE pl.PostId = rp.PostId) AS RelatedPostsCount
    
FROM 
    RankedPosts rp
WHERE 
    rp.Score > 10  
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;