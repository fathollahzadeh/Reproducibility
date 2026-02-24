WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS total_count
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId, 
        SUM((CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END)) AS Score,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.Id AS PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.CreationDate, 
        rp.rn, 
        us.UserId, 
        us.Score AS UserScore, 
        us.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.Id = p.Id AND p.AcceptedAnswerId IS NOT NULL
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserScores us ON u.Id = us.UserId
    WHERE 
        rp.rn <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.ViewCount, 
    tp.CreationDate, 
    COALESCE(tp.UserScore, 0) AS UserScore, 
    COALESCE(tp.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, 
    tp.UserScore DESC;