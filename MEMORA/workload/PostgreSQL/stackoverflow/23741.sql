
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
ActivePostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostTypeId,
        rp.OwnerUserId,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        rh.FirstEditDate,
        COALESCE(u.Reputation, 0) AS UserReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        RecentPostHistory rh ON rp.PostId = rh.PostId
    JOIN 
        UserReputation u ON rp.OwnerUserId = u.UserId
    WHERE 
        rp.UserPostRank = 1
    AND 
        rp.Score > 0
    AND 
        rp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    APS.PostId,
    APS.Title,
    APS.CreationDate,
    APS.Score,
    APS.TotalComments,
    APS.UserReputation,
    APS.OwnerDisplayName,
    CASE 
        WHEN APS.UserReputation > 1000 THEN 'Influencer'
        WHEN APS.UserReputation BETWEEN 500 AND 1000 THEN 'Contributor'
        ELSE 'Newcomer'
    END AS UserCategory,
    CASE 
        WHEN APS.TotalComments = 0 THEN 'No comments yet'
        ELSE 'Has comments'
    END AS CommentStatus,
    pht.Name AS PostHistoryType
FROM 
    ActivePostStatistics APS
LEFT JOIN 
    PostHistory ph ON APS.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pht.Name IS NOT NULL
ORDER BY 
    APS.Score DESC, APS.CreationDate DESC
LIMIT 100 OFFSET 0;
