WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(b.Class) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        TotalBadges,
        LastPostDate,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        DENSE_RANK() OVER (ORDER BY UpVotes DESC) AS RankByUpVotes
    FROM 
        UserActivity
    WHERE 
        LastPostDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.Reputation,
    a.PostCount,
    a.CommentCount,
    a.UpVotes,
    a.DownVotes,
    a.TotalBadges,
    a.RankByPosts,
    a.RankByUpVotes
FROM 
    ActiveUsers a
WHERE 
    a.RankByPosts <= 10 OR a.RankByUpVotes <= 10
ORDER BY 
    a.RankByPosts, a.RankByUpVotes;