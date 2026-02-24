
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(pv.VoteCount, 0) DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(b.Class) > 3
)
SELECT 
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    rp.Score,
    rp.VoteCount,
    fu.DisplayName,
    fu.TotalBadgeClass,
    fu.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    FilteredUsers fu ON rp.PostId IN (
        SELECT 
            c.PostId 
        FROM 
            Comments c 
        WHERE 
            c.UserId = fu.UserId
    )
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
