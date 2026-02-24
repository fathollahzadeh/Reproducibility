
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        b.Name AS BadgeName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, b.Name
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        ur.UserId,
        ur.Reputation,
        ur.BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank <= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Title,
    tp.ViewCount, 
    tp.Reputation, 
    COALESCE(th.CloseOpenCount, 0) AS CloseOpenCount,
    COALESCE(th.EditCount, 0) AS EditCount,
    p.CreationDate AS CreatedDate,
    CASE 
        WHEN tp.BadgeName IS NOT NULL THEN 'Has Badge'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistorySummary th ON tp.Id = th.PostId
JOIN 
    Posts p ON tp.Id = p.Id
ORDER BY 
    tp.ViewCount DESC;
