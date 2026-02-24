
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN pp.LinkTypeId = 3 THEN 1 ELSE 0 END), 0) AS DuplicatePosts
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pp ON p.Id = pp.PostId
    GROUP BY 
        p.OwnerUserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotes - us.DownVotes AS NetVotes,
        ps.PostCount,
        ps.AvgScore,
        ps.CommentCount,
        ps.DuplicatePosts,
        CASE 
            WHEN ps.PostCount > 10 THEN 'Active'
            WHEN ps.PostCount BETWEEN 1 AND 10 THEN 'Moderate'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM 
        UserStats us
    LEFT JOIN 
        PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    fs.DisplayName,
    fs.Reputation,
    fs.NetVotes,
    fs.AvgScore,
    fs.CommentCount,
    fs.DuplicatePosts,
    fs.ActivityStatus,
    RANK() OVER (ORDER BY fs.Reputation DESC) AS ReputationRank
FROM 
    FinalStats fs
WHERE 
    fs.Reputation >= (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    fs.Reputation DESC;
