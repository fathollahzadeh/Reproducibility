
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.PostTypeId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AverageReputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentsCount,
    hp.CloseReopenCount,
    hp.DeleteUndeleteCount,
    ur.AverageReputation,
    ur.BadgeCount,
    CASE 
        WHEN ur.AverageReputation IS NULL THEN 'No Reputation Data'
        WHEN ur.AverageReputation BETWEEN 0 AND 100 THEN 'New User'
        WHEN ur.AverageReputation BETWEEN 101 AND 500 THEN 'Intermediate User'
        WHEN ur.AverageReputation > 500 THEN 'Experienced User'
    END AS UserReputationCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregates hp ON rp.PostId = hp.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputations ur ON u.Id = ur.UserId
WHERE 
    (rp.ViewRank <= 5 AND rp.ViewCount > 100) OR (hp.CloseReopenCount > 0)
ORDER BY 
    rp.ViewCount DESC, rp.Title ASC
LIMIT 20 OFFSET 10;
