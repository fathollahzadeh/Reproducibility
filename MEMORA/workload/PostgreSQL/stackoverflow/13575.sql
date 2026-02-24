
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS Questions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS Answers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END), 0) AS Wikis,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 7 THEN 1 ELSE 0 END), 0) AS WikiPlaceholders,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END), 0) AS TagWikis
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN  
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.Wikis,
    ups.WikiPlaceholders,
    ups.TagWikis,
    pe.PostId,
    pe.Title,
    pe.ViewCount,
    pe.Score,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes
FROM 
    UserPostStats ups
LEFT JOIN 
    PostEngagement pe ON ups.UserId = pe.PostId
ORDER BY 
    ups.TotalPosts DESC, pe.ViewCount DESC;
