WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikis
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        us.TotalVotes,
        us.Upvotes,
        us.Downvotes,
        us.Favorites,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.Wikis,
        ps.TagWikis
    FROM 
        Users u
    LEFT JOIN 
        UserVoteStats us ON u.Id = us.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.Reputation,
    COALESCE(um.TotalVotes, 0) AS TotalVotes,
    COALESCE(um.Upvotes, 0) AS Upvotes,
    COALESCE(um.Downvotes, 0) AS Downvotes,
    COALESCE(um.Favorites, 0) AS Favorites,
    COALESCE(um.TotalPosts, 0) AS TotalPosts,
    COALESCE(um.Questions, 0) AS Questions,
    COALESCE(um.Answers, 0) AS Answers,
    COALESCE(um.Wikis, 0) AS Wikis,
    COALESCE(um.TagWikis, 0) AS TagWikis
FROM 
    UserMetrics um
ORDER BY 
    um.Reputation DESC, 
    um.TotalPosts DESC
LIMIT 100;