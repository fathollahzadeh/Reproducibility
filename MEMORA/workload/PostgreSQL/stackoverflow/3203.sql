
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

TopRankedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    WHERE 
        rp.Rank <= 3
)

SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score Registered'
        WHEN p.Score > 10 THEN 'High Score'
        ELSE 'Average Score'
    END AS ScoreCategory,
    p.OwnerDisplayName,
    p.UserBadge
FROM 
    TopRankedPosts p
ORDER BY 
    p.Score DESC;
