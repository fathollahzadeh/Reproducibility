WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM 
        UserActivity
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.PostCount, 
    u.CommentCount,
    u.UpVotes, 
    u.DownVotes,
    CAST((u.UpVotes - u.DownVotes) AS FLOAT) / NULLIF(u.PostCount, 0) AS VoteRatio,
    T.Name AS BadgeName, 
    b.Date AS BadgeDate
FROM 
    TopUsers u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
LEFT JOIN 
    (SELECT * FROM Badges WHERE Class = 1) T ON u.UserId = T.UserId
WHERE 
    u.RankByPosts <= 10
ORDER BY 
    VoteRatio DESC;
