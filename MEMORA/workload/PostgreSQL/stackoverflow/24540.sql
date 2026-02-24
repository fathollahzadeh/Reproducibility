WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
), 
FinalStats AS (
    SELECT 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate AS UserCreationDate, 
        uvs.UpVotes, 
        uvs.DownVotes, 
        ps.PostId, 
        ps.CommentCount, 
        ps.TotalBounty, 
        ps.LastPostDate,
        CASE 
            WHEN ps.RankByComments <= 5 THEN 'Top Contributor'
            ELSE 'Regular Contributor'
        END AS ContributorLevel
    FROM 
        Users u
    JOIN 
        UserVoteStats uvs ON u.Id = uvs.UserId
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    fs.DisplayName,
    fs.Reputation,
    fs.UserCreationDate,
    fs.UpVotes,
    fs.DownVotes,
    fs.PostId,
    fs.CommentCount,
    fs.TotalBounty,
    fs.LastPostDate,
    fs.ContributorLevel
FROM 
    FinalStats fs
WHERE 
    fs.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND 
    fs.LastPostDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    fs.TotalBounty DESC NULLS LAST;