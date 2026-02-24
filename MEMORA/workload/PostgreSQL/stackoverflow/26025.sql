WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),

PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.UpvoteCount) AS TotalUpvotes,
        COUNT(DISTINCT rp.PostId) AS PostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT rp.PostId) > 5 
),

TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        pu.DisplayName AS Author,
        rp.CommentCount,
        rp.UpvoteCount,
        pu.TotalUpvotes
    FROM 
        RankedPosts rp
    JOIN 
        PopularUsers pu ON rp.OwnerUserId = pu.UserId
    WHERE 
        rp.Rank = 1 
)

SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.Score,
    tpd.CreationDate,
    tpd.Author,
    tpd.CommentCount,
    tpd.UpvoteCount,
    tpd.TotalUpvotes,
    CASE 
        WHEN tpd.Score >= 10 THEN 'High Score'
        WHEN tpd.Score BETWEEN 5 AND 9 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.TotalUpvotes DESC, tpd.Score DESC;