
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
), 

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)
)

SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    r.OwnerDisplayName,
    r.CommentCount,
    t.UserId,
    t.DisplayName AS TopUser,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount
FROM 
    RankedPosts r
JOIN 
    TopUsers t ON r.OwnerDisplayName = t.DisplayName
WHERE 
    r.RankByScore <= 10
ORDER BY 
    r.Score DESC, t.UpVotes DESC;
