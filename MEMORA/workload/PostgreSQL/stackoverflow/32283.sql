WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ur.Reputation AS OwnerReputation,
        ur.DisplayName AS OwnerDisplayName,
        COALESCE(MAX(rph.CreationDate) FILTER (WHERE rph.rn = 1), '1970-01-01'::timestamp) AS LastActionDate,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputations ur ON ur.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        RecentPostHistory rph ON rph.PostId = rp.PostId AND rph.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, ur.Reputation, ur.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.OwnerReputation,
    ps.OwnerDisplayName,
    ps.LastActionDate,
    ps.CommentCount,
    CASE 
        WHEN ps.Score > 100 THEN 'Highly Popular'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular' 
    END AS PopularityCategory,
    ps.LastActionDate - ps.CreationDate AS PostAge,
    CASE 
        WHEN ps.LastActionDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active' 
    END AS ActivityStatus
FROM 
    PostStats ps
WHERE 
    ps.CommentCount > 5 
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;