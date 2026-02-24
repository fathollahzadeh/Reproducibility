
WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COALESCE(MAX(CreationDate), '1970-01-01 00:00:00') 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.AnswerCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.LastCommentDate,
        ps.UserPostRank,
        DENSE_RANK() OVER (ORDER BY ps.CreationDate DESC) AS RecentRank
    FROM 
        RecursivePostStats ps
    WHERE 
        ps.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.LastCommentDate,
    rp.UserPostRank,
    a.UserId,
    a.DisplayName,
    a.TotalUpVotes,
    a.TotalDownVotes,
    a.BadgeCount,
    pc.CommentCount,
    CASE 
        WHEN rp.RecentRank <= 5 THEN 'High Activity'
        WHEN rp.RecentRank BETWEEN 6 AND 15 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    RecentPosts rp
JOIN 
    ActiveUsers a ON rp.UserPostRank = a.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    a.TotalUpVotes > a.TotalDownVotes
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
