
WITH RecursivePostRank AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        COALESCE(cr.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(cr.CloseRank, 0) AS CloseRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        ClosedPosts cr ON p.Id = cr.PostId
    LEFT JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.OwnerDisplayName,
        pd.OwnerReputation,
        pd.CloseReason,
        MAX(r.Rank) AS HighestRank
    FROM 
        PostDetails pd
    JOIN 
        RecursivePostRank r ON pd.PostId = r.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.ViewCount, pd.OwnerDisplayName, pd.OwnerReputation, pd.CloseReason
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CloseReason,
    CASE 
        WHEN tp.HighestRank IS NOT NULL THEN 'Ranked Post' 
        ELSE 'Non-Ranked Post' 
    END AS PostCategory
FROM 
    TopPosts tp
WHERE 
    tp.OwnerReputation > 1000 
ORDER BY 
    tp.OwnerReputation DESC, 
    tp.ViewCount DESC 
FETCH FIRST 100 ROWS ONLY;
