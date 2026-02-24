WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1
        AND p.Score IS NOT NULL
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        vt.Name AS VoteType,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= '2023-01-01'
    GROUP BY 
        v.PostId, v.UserId, vt.Name
),
PostsAndVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        COALESCE(rv.VoteCount, 0) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.VoteCount,
    CASE 
        WHEN p.VoteCount > 10 THEN 'Highly Voted'
        WHEN p.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VoteCategory,
    COALESCE(u.Reputation, 0) AS OwnerReputation
FROM 
    PostsAndVotes p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    MostActiveUsers mau ON p.OwnerUserId = mau.OwnerUserId
WHERE 
    p.Score > 0
ORDER BY 
    p.Score DESC, VoteCount DESC
LIMIT 100;
