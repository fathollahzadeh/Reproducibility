
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
CommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.PostHistoryTypeId) AS LastHistoryType
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.ReputationLevel,
        c.TotalComments,
        ph.LastEditDate,
        ph.LastHistoryType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        CommentsCount c ON rp.PostId = c.PostId
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    WHERE 
        rp.Rank <= 5 
        AND (ur.ReputationLevel IS NOT NULL OR c.TotalComments > 0)
)

SELECT 
    f.PostId, 
    f.Title, 
    f.CreationDate, 
    f.Score, 
    f.ViewCount,
    COALESCE(f.ReputationLevel, 'Unknown') AS UserReputationLevel,
    COALESCE(f.TotalComments, 0) AS TotalComments,
    COALESCE(f.LastEditDate, TIMESTAMP '1970-01-01 00:00:00') AS LastEditTimestamp,
    CASE 
        WHEN f.LastHistoryType = 10 THEN 'Closed'
        WHEN f.LastHistoryType = 4 THEN 'Edited Title'
        WHEN f.LastHistoryType = 5 THEN 'Edited Body'
        ELSE 'No History'
    END AS LastPostHistory
FROM 
    FinalResults f
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
