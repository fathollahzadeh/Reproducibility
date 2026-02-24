
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.OwnerUserId
),
Benchmark AS (
    SELECT 
        us.UserId,
        ps.PostId,
        us.Reputation,
        ps.PostTypeId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        us.BadgeCount,
        us.TotalBounty
    FROM 
        UserStats us
    JOIN 
        PostStats ps ON us.UserId = ps.OwnerUserId
)

SELECT 
    UserId,
    AVG(Reputation) AS AverageReputation,
    AVG(BadgeCount) AS AverageBadgeCount,
    AVG(TotalBounty) AS AverageTotalBounty,
    SUM(CommentCount) AS TotalComments,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes,
    COUNT(DISTINCT PostId) AS CountPosts
FROM 
    Benchmark
GROUP BY 
    UserId;
