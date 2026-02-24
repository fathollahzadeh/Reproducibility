
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(b.Id) AS TotalBadges,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostUserStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.Tags,
        us.UserId,
        us.DisplayName,
        us.TotalBounties,
        us.TotalBadges,
        us.TotalScore
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.Tags LIKE CONCAT('%<', u.DisplayName, '>%')
    JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    pus.PostId,
    pus.Title,
    pus.Score,
    pus.ViewCount,
    pus.TotalBounties,
    pus.TotalBadges,
    pus.TotalScore
FROM 
    PostUserStats pus
ORDER BY 
    pus.Score DESC, pus.ViewCount DESC;
