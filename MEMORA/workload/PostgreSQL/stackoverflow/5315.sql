
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId, p.AnswerCount, p.CommentCount
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalPosts DESC, TotalBadges DESC
    LIMIT 10
),
PostInteraction AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        rp.UpVotes,
        rp.DownVotes,
        tu.TotalBadges,
        tu.TotalPosts
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        TopUsers tu ON u.Id = tu.Id
)
SELECT 
    pi.Title,
    pi.CreationDate,
    pi.OwnerDisplayName,
    pi.Score,
    pi.UpVotes,
    pi.DownVotes,
    pi.TotalBadges,
    pi.TotalPosts
FROM 
    PostInteraction pi
ORDER BY 
    pi.Score DESC, pi.UpVotes DESC, pi.DownVotes ASC;
