WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(ph.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(ph.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(ph.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    ups.PostsCount,
    ups.TotalVotes,
    ups.TotalUpVotes,
    ups.TotalDownVotes
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
ORDER BY 
    ups.TotalVotes DESC, ups.PostsCount DESC;