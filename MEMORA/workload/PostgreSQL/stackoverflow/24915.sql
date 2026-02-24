
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2023-01-01' 
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.RankScore,
        rp.UpVoteCount,
        rp.DownVoteCount,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5  
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS UserPostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100  
    GROUP BY 
        u.Id, u.DisplayName
),
TopUserPosts AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.UserPostCount,
        up.TotalBadgeScore
    FROM 
        UserPosts up
    WHERE 
        up.UserPostCount > 10  
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.NetScore,
    tup.DisplayName AS UserDisplayName,
    tup.UserPostCount,
    tup.TotalBadgeScore
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    TopUserPosts tup ON u.Id = tup.UserId
WHERE 
    (tp.NetScore > 0 OR tup.TotalBadgeScore > 0)
ORDER BY 
    tp.NetScore DESC,
    tup.TotalBadgeScore DESC;
