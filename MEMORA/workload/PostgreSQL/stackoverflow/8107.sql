WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title
),
FeaturedUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        us.TotalVotes,
        us.UpVotes,
        us.DownVotes,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.BadgeCount,
        ps.AnswerCount
    FROM 
        UserVoteStats us
    JOIN 
        Users u ON us.UserId = u.Id
    JOIN 
        PostStats ps ON u.Id = ps.PostId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
        AND us.TotalVotes > 5
)
SELECT 
    DisplayName,
    Reputation,
    TotalVotes,
    UpVotes,
    DownVotes,
    Title,
    CommentCount,
    BadgeCount,
    AnswerCount
FROM 
    FeaturedUsers
ORDER BY 
    Reputation DESC, TotalVotes DESC
LIMIT 10;
