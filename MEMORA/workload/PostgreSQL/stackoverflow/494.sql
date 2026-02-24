
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    COALESCE(us.Upvotes, 0) AS Upvotes,
    COALESCE(us.Downvotes, 0) AS Downvotes,
    ph.LastEdited,
    ph.EditCount,
    ph.HistoryTypes,
    CASE 
        WHEN rp.Score > 10 THEN 'Highly Rated'
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderately Rated'
        ELSE 'Low Rating'
    END AS RatingCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserScores us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.Id = ph.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
FETCH FIRST 100 ROWS ONLY;
