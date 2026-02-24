
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '30 days')
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
EnhancedPostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        ups.TotalPosts,
        ups.TotalComments,
        ups.TotalBounties,
        CASE 
            WHEN ups.TotalPosts IS NULL THEN 'No User'
            ELSE ups.DisplayName 
        END AS UserDisplayName
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserPostStats ups ON tp.PostId = ups.UserId
)
SELECT 
    epd.PostId,
    epd.Title,
    epd.Score,
    epd.ViewCount,
    epd.TotalPosts,
    epd.TotalComments,
    epd.TotalBounties,
    epd.UserDisplayName
FROM 
    EnhancedPostDetails epd
WHERE 
    epd.Score IS NOT NULL
    AND epd.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = epd.PostId) > 
        (SELECT AVG((SELECT COUNT(*) FROM Comments WHERE PostId = p.Id)) FROM Posts p WHERE p.PostTypeId = 1)
ORDER BY 
    epd.Score DESC, 
    epd.ViewCount DESC;
