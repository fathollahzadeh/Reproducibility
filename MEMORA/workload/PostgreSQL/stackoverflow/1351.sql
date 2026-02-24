
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Date = (
            SELECT MAX(b2.Date) 
            FROM Badges b2 
            WHERE b2.UserId = p.OwnerUserId
        )
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.BadgeClass,
        CASE 
            WHEN rp.UpVotes + rp.DownVotes = 0 THEN 0 
            ELSE (rp.UpVotes * 1.0 / (rp.UpVotes + rp.DownVotes)) * 100 
        END AS VotePercentage
    FROM 
        RankedPosts rp
),
TopPosts AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM 
        PostSummary
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.VotePercentage,
    CASE 
        WHEN tp.BadgeClass = 1 THEN 'Gold'
        WHEN tp.BadgeClass = 2 THEN 'Silver'
        WHEN tp.BadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS Badge
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.ViewCount DESC;
