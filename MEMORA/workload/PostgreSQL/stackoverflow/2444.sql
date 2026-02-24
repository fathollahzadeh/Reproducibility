WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    au.DisplayName,
    au.PostCount,
    au.TotalScore,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post' 
        ELSE 'Other Post' 
    END AS PostStatus
FROM 
    ActiveUsers au
LEFT JOIN RankedPosts rp ON au.UserId = rp.OwnerUserId
WHERE 
    (rp.Score > 10 OR rp.UpVotes > 5)
ORDER BY 
    au.TotalScore DESC, 
    rp.Score DESC
LIMIT 50;