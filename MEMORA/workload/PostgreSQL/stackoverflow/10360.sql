
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.BadgesCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId = ua.UserId
ORDER BY 
    rp.CreationDate DESC;
