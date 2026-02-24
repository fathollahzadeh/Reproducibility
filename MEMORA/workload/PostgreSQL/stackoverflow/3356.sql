WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.TotalUpVotes) AS UserTotalUpVotes,
        COUNT(rp.Id) AS UserPostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        u.DisplayName,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.DisplayName,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.ScoreCategory,
    us.UserTotalUpVotes,
    us.UserPostCount
FROM 
    TopPosts tp
FULL OUTER JOIN 
    UserStats us ON tp.OwnerUserId = us.UserId
WHERE 
    (tp.Score > 0 OR us.UserTotalUpVotes > 0)
    AND (tp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' OR us.UserPostCount > 5)
ORDER BY 
    tp.TotalUpVotes DESC NULLS LAST, 
    us.UserTotalUpVotes DESC NULLS LAST;