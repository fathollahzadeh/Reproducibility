
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
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
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.DisplayName,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    JOIN 
        UserStats us ON us.UserId = u.Id
    LEFT JOIN 
        PostComments pc ON pc.PostId = rp.Id
    WHERE 
        rp.PostRank = 1
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.DisplayName,
    pd.TotalComments,
    CASE 
        WHEN pd.Score > 100 THEN 'High Score'
        ELSE 'Standard Score'
    END AS ScoreCategory
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC
LIMIT 10 OFFSET 0;
